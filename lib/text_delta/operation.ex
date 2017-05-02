defmodule TextDelta.Operation do
  @moduledoc """
  Operations represent a smallest possible change applicable to the document.

  In case of text, there are exactly 3 possible operations we might want to
  perform:

  - `t:TextDelta.Operation.insert/0`: insert a new piece of text or an embedded
    element
  - `t:TextDelta.Operation.retain/0`: preserve given number of characters in
    sequence
  - `t:TextDelta.Operation.delete/0`: delete given number of characters in
    sequence

  `insert` and `retain` operations can also have optional
  `t:TextDelta.Attributes.t/0` attached to them. This is how Delta manages rich
  text formatting without breaking the [Operational Transformation][ot]
  paradigm.

  [ot]: https://en.wikipedia.org/wiki/Operational_transformation
  """

  alias TextDelta.Attributes

  @typedoc """
  Insert operation represents an intention to add a text or an embedded element
  to a document. Text additions are represented with binary strings and embedded
  elements are represented with either an integer or an object.

  Insert also allows us to attach attributes to the element being inserted.
  """
  @type insert :: %{insert: element}
                | %{insert: element, attributes: Attributes.t}

  @typedoc """
  Retain operation represents an intention to keep a sequence of characters
  unchanged in the document. It is always a number and it is always positive.

  In addition to indicating preservation of existing text, retain also allows us
  to change formatting of retained text or element via optional attributes.
  """
  @type retain :: %{retain: non_neg_integer}
                | %{retain: non_neg_integer, attributes: Attributes.t}

  @typedoc """
  Delete operation represents an intention to delete a sequence of characters
  from the document. It is always a number and it is always positive.
  """
  @type delete :: %{delete: non_neg_integer}

  @typedoc """
  An operation. Either `insert`, `retain` or `delete`.
  """
  @type t :: insert | retain | delete

  @typedoc """
  Atom representing type of operation.
  """
  @type type :: :insert | :retain | :delete

  @typedoc """
  The result of comparison operation.
  """
  @type comparison :: :eq | :gt | :lt

  @typedoc """
  An insertable rich text element. Either a piece of text, a number or an embed.
  """
  @type element :: String.t | integer | map

  @doc """
  Creates a new insert operation.

  Attributes are optional and are ignored if empty map or `nil` is provided.

  ## Examples

  To indicate that we need to insert a text "hello" into the document, we can
  use following insert:

      iex> TextDelta.Operation.insert("hello")
      %{insert: "hello"}

  In addition, we can indicate that "hello" should be inserted with specific
  attributes:

      iex> TextDelta.Operation.insert("hello", %{bold: true, color: "magenta"})
      %{insert: "hello", attributes: %{bold: true, color: "magenta"}}

  We can also insert non-text objects, such as an image:

      iex> TextDelta.Operation.insert(%{img: "me.png"}, %{alt: "My photo"})
      %{insert: %{img: "me.png"}, attributes: %{alt: "My photo"}}
  """
  @spec insert(element, Attributes.t) :: insert
  def insert(el, attrs \\ %{})
  def insert(el, nil), do: %{insert: el}
  def insert(el, attrs) when map_size(attrs) == 0, do: %{insert: el}
  def insert(el, attrs), do: %{insert: el, attributes: attrs}

  @doc """
  Creates a new retain operation.

  Attributes are optional and are ignored if empty map or `nil` is provided.

  ## Examples

  To keep 5 next characters inside the text, we can use the following retain:

      iex> TextDelta.Operation.retain(5)
      %{retain: 5}

  To make those exact 5 characters bold, while keeping them, we can use
  attributes:

      iex> TextDelta.Operation.retain(5, %{bold: true})
      %{retain: 5, attributes: %{bold: true}}
  """
  @spec retain(non_neg_integer, Attributes.t) :: retain
  def retain(len, attrs \\ %{})
  def retain(len, nil), do: %{retain: len}
  def retain(len, attrs) when map_size(attrs) == 0, do: %{retain: len}
  def retain(len, attrs), do: %{retain: len, attributes: attrs}

  @doc """
  Creates a new delete operation.

  ## Example

  To delete 3 next characters from the text, we can create a following
  operation:

      iex> TextDelta.Operation.delete(3)
      %{delete: 3}
  """
  @spec delete(non_neg_integer) :: delete
  def delete(len)
  def delete(len), do: %{delete: len}

  @doc """
  Returns atom representing type of the given operation.

  ## Example

      iex> TextDelta.Operation.type(%{retain: 5, attributes: %{bold: true}})
      :retain
  """
  @spec type(t) :: type
  def type(op)
  def type(%{insert: _}), do: :insert
  def type(%{retain: _}), do: :retain
  def type(%{delete: _}), do: :delete

  @doc """
  Returns length of text affected by a given operation.

  Length for `insert` operations is calculated by counting the length of text
  itself being inserted, length for `retain` or `delete` operations is a length
  of sequence itself. Attributes have no effect over the length.

  ## Examples

  For text inserts it is a length of text itself:

      iex> TextDelta.Operation.length(%{insert: "hello!"})
      6

  For embed inserts, however, length is always 1:

      iex> TextDelta.Operation.length(%{insert: 3})
      1

  For retain and deletes, the number itself is the length:

      iex> TextDelta.Operation.length(%{retain: 4})
      4
  """
  @spec length(t) :: non_neg_integer
  def length(op)
  def length(%{insert: el}) when not is_bitstring(el), do: 1
  def length(%{insert: str}), do: String.length(str)
  def length(%{retain: len}), do: len
  def length(%{delete: len}), do: len

  @doc """
  Compares the length of two operations.

  ## Example

      iex> TextDelta.Operation.compare(%{insert: "hello!"}, %{delete: 3})
      :gt
  """
  @spec compare(t, t) :: comparison
  def compare(op_a, op_b) do
    len_a = __MODULE__.length(op_a)
    len_b = __MODULE__.length(op_b)
    cond do
      len_a > len_b -> :gt
      len_a < len_b -> :lt
      true -> :eq
    end
  end

  @doc """
  Splits operations into two halves around the given index.

  Text `insert` is split via slicing the text itself, `retain` or `delete` is
  split by subtracting the sequence number. Attributes are preserved during
  splitting. This is mostly used for normalisation of deltas during iteration.

  ## Examples

  Text `inserts` are split via slicing the text itself:

      iex> TextDelta.Operation.slice(%{insert: "hello"}, 3)
      {%{insert: "hel"}, %{insert: "lo"}}

  `retain` and `delete` are split by subtracting the sequence number:

      iex> TextDelta.Operation.slice(%{retain: 5}, 2)
      {%{retain: 2}, %{retain: 3}}
  """
  @spec slice(t, non_neg_integer) :: {t, t}
  def slice(op, idx)

  def slice(%{insert: str} = op, idx) when is_bitstring(str) do
    {Map.put(op, :insert, String.slice(str, 0, idx)),
     Map.put(op, :insert, String.slice(str, idx..-1))}
  end

  def slice(%{insert: _} = op, _) do
    {op, %{insert: ""}}
  end

  def slice(%{retain: op_len} = op, idx) do
    {Map.put(op, :retain, idx),
     Map.put(op, :retain, op_len - idx)}
  end

  def slice(%{delete: op_len} = op, idx) do
    {Map.put(op, :delete, idx),
     Map.put(op, :delete, op_len - idx)}
  end

  @doc """
  Attempts to compact two given operations into one.

  If successful, will return a list with just a single, compacted operation. In
  any other case both operations will be returned back unchanged.

  Compacting works by combining same operations with the same attributes
  together. Easiest way to think about this function is that it produces an
  exact opposite effect of `TextDelta.Operation.slice/2`.

  Text `insert` is compacted by concatenating strings, `retain` or `delete` is
  compacted by adding the sequence numbers. Only operations with the same
  attribute set are compacted. This is mostly used to keep deltas short and
  canonical.

  ## Examples

  Text inserts are compacted into a single insert:

      iex> TextDelta.Operation.compact(%{insert: "hel"}, %{insert: "lo"})
      [%{insert: "hello"}]

  Retains and deletes are compacted by adding their sequence numbers:

      iex> TextDelta.Operation.compact(%{retain: 2}, %{retain: 3})
      [%{retain: 5}]
  """
  @spec compact(t, t) :: [t]
  def compact(op_a, op_b)

  def compact(%{retain: len_a, attributes: attrs_a},
              %{retain: len_b, attributes: attrs_b})
              when attrs_a == attrs_b do
    [retain(len_a + len_b, attrs_a)]
  end

  def compact(%{retain: len_a} = a,
              %{retain: len_b} = b)
              when map_size(a) == 1 and map_size(b) == 1 do
    [retain(len_a + len_b)]
  end

  def compact(%{insert: el_a} = op_a,
              %{insert: _} = op_b)
              when not is_bitstring(el_a) do
    [op_a, op_b]
  end

  def compact(%{insert: _} = op_a,
              %{insert: el_b} = op_b)
              when not is_bitstring(el_b) do
    [op_a, op_b]
  end

  def compact(%{insert: str_a, attributes: attrs_a},
              %{insert: str_b, attributes: attrs_b})
              when attrs_a == attrs_b do
    [insert(str_a <> str_b, attrs_a)]
  end

  def compact(%{insert: str_a} = op_a,
              %{insert: str_b} = op_b)
              when map_size(op_a) == 1 and map_size(op_b) == 1 do
    [insert(str_a <> str_b)]
  end

  def compact(%{delete: len_a}, %{delete: len_b}) do
    [delete(len_a + len_b)]
  end

  def compact(op_a, op_b), do: [op_a, op_b]

  @doc """
  Checks if given operation is trimmable.

  Technically only `retain` operations are trimmable, but the creator of this
  library didn't feel comfortable exposing that knowledge outside of this
  module.

  ## Example

      iex> TextDelta.Operation.trimmable?(%{retain: 3})
      true
  """
  @spec trimmable?(t) :: boolean
  def trimmable?(op) do
    Map.has_key?(op, :retain) and !Map.has_key?(op, :attributes)
  end
end
