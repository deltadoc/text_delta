defmodule TextDelta do
  @moduledoc """
  Delta is a format used to describe documents and changes.

  Delta can describe any rich text changes or a rich document itself, preserving
  all the formatting.

  At the baseline level, delta is an array of operations (constructed via
  `TextDelta.Operation`). Operations can be either
  `t:TextDelta.Operation.insert/0`, `t:TextDelta.Operation.retain/0` or
  `t:TextDelta.Operation.delete/0`. None of the operations contain index,
  meaning that delta aways describes document or a change staring from the very
  beginning.

  Delta can describe both changes to and documents themselves. We can think of a
  document as an artefact of all the changes applied to it. This way, newly
  imported document can be thinked of as simply a sequence of `insert`s applied
  to an empty document.

  Deltas are composable. This means that a document delta can be composed with
  another delta for that document, resulting in a shorter, optimized delta.

  Deltas are also transformable. This attribute of deltas is what enables
  [Operational Transformation][ot] - a way to transform one operation against
  the context of another one. Operational Transformation allows us to build
  optimistic, non-locking collaborative editors.

  The format for deltas was deliberately copied from [Quill][quill] - a rich
  text editor for web. This library aims to be an Elixir counter-part for Quill,
  enabling us to build matching backends for the editor.

  ## Example

      iex> delta = TextDelta.insert(TextDelta.new(), "Gandalf", %{bold: true})
      %TextDelta{ops: [
          %{insert: "Gandalf", attributes: %{bold: true}}]}
      iex> delta = TextDelta.insert(delta, " the ")
      %TextDelta{ops: [
          %{insert: "Gandalf", attributes: %{bold: true}},
          %{insert: " the "}]}
      iex> TextDelta.insert(delta, "Grey", %{color: "#ccc"})
      %TextDelta{ops: [
          %{insert: "Gandalf", attributes: %{bold: true}},
          %{insert: " the "},
          %{insert: "Grey", attributes: %{color: "#ccc"}}]}

  [ot]: https://en.wikipedia.org/wiki/Operational_transformation
  [quill]: https://quilljs.com
  """

  alias TextDelta.{Operation, Attributes, Composition, Transformation}

  defstruct ops: []

  @typedoc """
  Delta is a set of `t:TextDelta.Operation.retain/0`,
  `t:TextDelta.Operation.insert/0`, or `t:TextDelta.Operation.delete/0`
  operations.
  """
  @type t :: %TextDelta{ops: [Operation.t]}

  @typedoc """
  A document represented as delta. Any rich document can be represented as a set
  of `t:TextDelta.Operation.insert/0` operations.
  """
  @type document :: %TextDelta{ops: [Operation.insert]}

  @doc """
  Creates new delta.

  ## Examples

      iex> TextDelta.new()
      %TextDelta{ops: []}

  You can also pass set of operations using optional argument:

      iex> TextDelta.new([TextDelta.Operation.insert("hello")])
      %TextDelta{ops: [%{insert: "hello"}]}
  """
  @spec new([Operation.t]) :: t
  def new(ops \\ [])
  def new([]), do: %TextDelta{}
  def new(ops), do: Enum.reduce(ops, new(), &append(&2, &1))

  @doc """
  Creates and appends new `insert` operation to the delta.

  Same as with underlying `TextDelta.Operation.insert/2` function, attributes
  are optional.

  `TextDelta.append/2` is used undert the hood to add operation to the delta
  after construction. So all `append` rules apply.

  ## Example

      iex> TextDelta.insert(TextDelta.new(), "hello", %{bold: true})
      %TextDelta{ops: [%{insert: "hello", attributes: %{bold: true}}]}
  """
  @spec insert(t, Operation.element, Attributes.t) :: t
  def insert(delta, el, attrs \\ %{}) do
    append(delta, Operation.insert(el, attrs))
  end

  @doc """
  Creates and appends new `retain` operation to the delta.

  Same as with underlying `TextDelta.Operation.retain/2` function, attributes
  are optional.

  `TextDelta.append/2` is used undert the hood to add operation to the delta
  after construction. So all `append` rules apply.

  ## Example

      iex> TextDelta.retain(TextDelta.new(), 5, %{italic: true})
      %TextDelta{ops: [%{retain: 5, attributes: %{italic: true}}]}
  """
  @spec retain(t, non_neg_integer, Attributes.t) :: t
  def retain(delta, len, attrs \\ %{}) do
    append(delta, Operation.retain(len, attrs))
  end

  @doc """
  Creates and appends new `delete` operation to the delta.

  `TextDelta.append/2` is used undert the hood to add operation to the delta
  after construction. So all `append` rules apply.

  ## Example

      iex> TextDelta.delete(TextDelta.new(), 3)
      %TextDelta{ops: [%{delete: 3}]}
  """
  @spec delete(t, non_neg_integer) :: t
  def delete(delta, len) do
    append(delta, Operation.delete(len))
  end

  @doc """
  Appends given operation to the delta.

  Before adding operation to the delta, this function attempts to compact it by
  applying 2 simple rules:

  1. Delete followed by insert is swapped to ensure that insert goes first.
  2. Same operations with the same attributes are merged.

  These two rules ensure that our deltas are always as short as possible and
  canonical, making it easier to compare, compose and transform them.

  ## Example

      iex> operation = TextDelta.Operation.insert("hello")
      iex> TextDelta.append(TextDelta.new(), operation)
      %TextDelta{ops: [%{insert: "hello"}]}
  """
  @spec append(t, Operation.t) :: t
  def append(delta, op)
  def append(%TextDelta{ops: []}, op), do: wrap(compact([], op))
  def append(%TextDelta{ops: ops}, op) do
    ops
    |> Enum.reverse()
    |> compact(op)
    |> Enum.reverse()
    |> wrap()
  end

  defdelegate compose(delta_a, delta_b), to: Composition
  defdelegate transform(delta_a, delta_b, priority), to: Transformation

  @doc """
  Trims trailing retains from the end of a given delta.

  ## Example

      iex> TextDelta.trim(TextDelta.new([%{insert: "hello"}, %{retain: 5}]))
      %TextDelta{ops: [%{insert: "hello"}]}
  """
  @spec trim(t) :: t
  def trim(delta)
  def trim(%TextDelta{ops: []} = empty), do: empty
  def trim(delta) do
    last_operation = List.last(delta.ops)
    case Operation.trimmable?(last_operation) do
      true ->
        delta.ops
        |> Enum.slice(0..-2)
        |> wrap()
        |> trim()
      false ->
        delta
    end
  end

  @doc """
  Calculates the length of a given delta.

  Length of delta is a sum of its operations length.

  ## Example

      iex> TextDelta.length(TextDelta.new([%{insert: "hello"}, %{retain: 5}]))
      10

  The function also allows to select which types of operations we include in the
  summary with optional second argument:

      iex> TextDelta.length(TextDelta.new([%{insert: "hi"}]), [:retain])
      0
  """
  @spec length(t, [Operation.type]) :: non_neg_integer
  def length(delta, op_types \\ [:insert, :retain, :delete]) do
    delta.ops
    |> Enum.filter(&(Enum.member?(op_types, Operation.type(&1))))
    |> Enum.map(&Operation.length/1)
    |> Enum.sum()
  end

  @doc """
  Returns set of operations for a given delta.

  ## Example

      iex> TextDelta.operations(TextDelta.new([%{delete: 5}, %{retain: 3}]))
      [%{delete: 5}, %{retain: 3}]
  """
  @spec operations(t) :: [Operation.t]
  def operations(delta), do: delta.ops

  defp compact(ops, %{insert: ""}) do
    ops
  end

  defp compact(ops, %{retain: 0}) do
    ops
  end

  defp compact(ops, %{delete: 0}) do
    ops
  end

  defp compact(ops, []) do
    ops
  end

  defp compact(ops, nil) do
    ops
  end

  defp compact([], new_op) do
    [new_op]
  end

  defp compact([%{delete: _} = del | ops_remainder], %{insert: _} = ins) do
    compact(compact(ops_remainder, ins), del)
  end

  defp compact([last_op | ops_remainder], new_op) do
    last_op
    |> Operation.compact(new_op)
    |> Enum.reverse()
    |> Kernel.++(ops_remainder)
  end

  defp wrap(ops), do: %TextDelta{ops: ops}
end
