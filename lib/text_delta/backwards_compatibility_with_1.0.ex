# All modules here are only for bacwards compatibility and will be removed in
# next major bump - 2.0. Please upgrade to the new public API ASAP.

defmodule TextDelta.Delta do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.{Operation, Attributes}
  alias TextDelta.Delta.{Transformation, Composition}

  @type t :: [Operation.t]
  @type document :: [Operation.insert]

  @doc false
  @spec new([Operation.t]) :: t
  def new(ops \\ []) do
    ops
    |> TextDelta.new()
    |> unwrap()
  end

  @doc false
  @spec insert(t, Operation.element, Attributes.t) :: t
  def insert(delta, el, attrs \\ %{}) do
    delta
    |> wrap()
    |> TextDelta.insert(el, attrs)
    |> unwrap()
  end

  @doc false
  @spec retain(t, non_neg_integer, Attributes.t) :: t
  def retain(delta, len, attrs \\ %{}) do
    delta
    |> wrap()
    |> TextDelta.retain(len, attrs)
    |> unwrap()
  end

  @doc false
  @spec delete(t, non_neg_integer) :: t
  def delete(delta, len) do
    delta
    |> wrap()
    |> TextDelta.delete(len)
    |> unwrap()
  end

  @doc false
  @spec append(t | nil, Operation.t) :: t
  def append(nil, op), do: append(new(), op)
  def append(delta, op) do
    delta
    |> wrap()
    |> TextDelta.append(op)
    |> unwrap()
  end

  defdelegate compose(delta_a, delta_b), to: Composition
  defdelegate transform(delta_a, delta_b, priority), to: Transformation

  @doc false
  @spec trim(t) :: t
  def trim(delta) do
    delta
    |> wrap()
    |> TextDelta.trim()
    |> unwrap()
  end

  @doc false
  @spec length(t, [Operation.type]) :: non_neg_integer
  def length(delta, included_ops \\ [:insert, :retain, :delete]) do
    delta
    |> wrap()
    |> TextDelta.length(included_ops)
  end

  @doc false
  @spec wrap(t) :: TextDelta.t
  def wrap(ops), do: TextDelta.new(ops)

  @doc false
  @spec unwrap(TextDelta.t) :: t
  def unwrap(delta), do: TextDelta.operations(delta)
end

defmodule TextDelta.Delta.Composition do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.Delta

  @doc false
  @spec compose(Delta.t, Delta.t) :: Delta.t
  def compose(delta_a, delta_b) do
    delta_a
    |> Delta.wrap()
    |> TextDelta.compose(Delta.wrap(delta_b))
    |> Delta.unwrap()
  end
end

defmodule TextDelta.Delta.Transformation do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.Delta

  @type priority :: :left | :right

  @doc false
  @spec transform(Delta.t, Delta.t, priority) :: Delta.t
  def transform(delta_a, delta_b, priority) do
    delta_a
    |> Delta.wrap()
    |> TextDelta.transform(Delta.wrap(delta_b), priority)
    |> Delta.unwrap()
  end
end

defmodule TextDelta.Delta.Iterator do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  @type deltas :: {Delta.t, Delta.t}
  @type skip_type :: :insert | :delete | nil
  @type cycle :: {delta_split, delta_split}
  @type delta_split :: {Operation.t | nil, Delta.t}

  defdelegate next(deltas, skip_type \\ nil), to: TextDelta.Iterator
end
