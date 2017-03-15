defmodule TextDelta.Operation do
  @moduledoc """
  Operations represent a smallest possible change applicable to the document.

  In case of text, there are exactly 3 possible operations you might want to perform:

  - `insert`: insert a new piece of text or an embedded element
  - `retain`: preserve given number of characters in sequence
  - `delete`: delete given number of characters in sequence
  """

  @typedoc """
  Insert operations represent an intention to add a text or an embedded element to a document. Text
  additions are represented with binary strings and embedded elements are represented with either
  an integer or an object.

  Insert also allows us to attach arbitrary number of attributes to the element being inserted.
  Attributes are provided as a map via optional second argument of the function. This library
  does not make any assumptions about attributes, so no validity is checked there.
  """
  @type insert :: %{insert: String.t | integer | map} | %{insert: String.t | integer | map, attributes: map}

  @typedoc """
  Retain operations represent an intention to keep a sequence of characters unchanged in the
  document. It is always a number and it is always positive.

  In addition to indicating preservation of existing text, retain also allows us to change
  formatting of said text by providing optional attributes as a map via second argument of the
  function.
  """
  @type retain :: %{retain: non_neg_integer} | %{retain: non_neg_integer, attributes: map}

  @typedoc """
  Delete operations represent an intention to delete a sequence of characters from the document. It
  is always a number and it is always positive.
  """
  @type delete :: %{delete: non_neg_integer}

  @typedoc """
  An operation. Either insert, retain or delete.
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

  @doc """
  Creates a new insert operation.

  Attributes are optional and are ignored if empty map or nil is provided.

  ## Examples

  To indicate that we need to insert a text "hello" into the document, we can use following insert:

    iex> TextDelta.Operation.insert("hello")
    %{insert: "hello"}

  In addition, we can indicate that "hello" should be inserted with specific attributes:

    iex> TextDelta.Operation.insert("hello", %{bold: true, color: "magenta"})
    %{insert: "hello", attributes: %{bold: true, color: "magenta"}}

  We can also insert non-text objects, such as an image:

    iex> TextDelta.Operation.insert(%{img: "me.png"}, %{alt: "My photo"})
    %{insert: %{img: "me.png"}, attributes: %{alt: "My photo"}}

  As said previously, attributes are totally optional and ignored if empty:

    iex> TextDelta.Operation.insert("hello", nil)
    %{insert: "hello"}
    iex> TextDelta.Operation.insert("hello", %{})
    %{insert: "hello"}
  """
  @spec insert(String.t | integer | map, map) :: insert
  def insert(el, attrs \\ %{})
  def insert(el, nil), do: %{insert: el}
  def insert(el, attrs) when map_size(attrs) == 0, do: %{insert: el}
  def insert(el, attrs), do: %{insert: el, attributes: attrs}

  @doc """
  Creates a new retain operation.

  Attributes are optional and are ignored if empty map or nil is provided.

  ## Examples

  To keep 5 next characters inside the text, we can create a following retain:

    iex> TextDelta.Operation.retain(5)
    %{retain: 5}

  To make those exact 5 characters bold while keeping them, we can use attributes:

    iex> TextDelta.Operation.retain(5, %{bold: true})
    %{retain: 5, attributes: %{bold: true}}

  Same as with insert, attributes are optional and are ignored when empty:

    iex> TextDelta.Operation.retain(5, nil)
    %{retain: 5}
  """
  @spec retain(non_neg_integer, map) :: retain
  def retain(len, attrs \\ %{})
  def retain(len, nil), do: %{retain: len}
  def retain(len, attrs) when map_size(attrs) == 0, do: %{retain: len}
  def retain(len, attrs), do: %{retain: len, attributes: attrs}

  @doc """
  Creates a new delete operation.

  ## Examples

  To delete 3 next characters from the text, we can create a following operation:

    iex> TextDelta.Operation.delete(3)
    %{delete: 3}
  """
  @spec delete(non_neg_integer) :: delete
  def delete(len)
  def delete(len), do: %{delete: len}

  @doc """
  Returns atom representing type of the given operation.

  ## Examples

    iex> TextDelta.Operation.type(%{insert: "hi"})
    :insert
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

  ## Examples

  For text inserts it is a length of text itself:

    iex> TextDelta.Operation.length(%{insert: "hello!"})
    6

  For embed inserts, however, length is always 1:

    iex> TextDelta.Operation.length(%{insert: 4})
    1
    iex> TextDelta.Operation.length(%{insert: %{img: "me.png"}})
    1

  For retain, the number itself is the length:

    iex> TextDelta.Operation.length(%{retain: 4})
    4

  Same for deletes:

    iex> TextDelta.Operation.length(%{delete: 2})
    2

  Attributes have no effect over length:

    iex> TextDelta.Operation.length(%{insert: "hello!", attributes: %{bold: true}})
    6
    iex> TextDelta.Operation.length(%{retain: 3, attributes: %{italic: true}})
    3
  """
  @spec length(t) :: non_neg_integer
  def length(op)
  def length(%{insert: el}) when not is_bitstring(el), do: 1
  def length(%{insert: str}), do: String.length(str)
  def length(%{retain: len}), do: len
  def length(%{delete: len}), do: len

  @doc """
  Compares length of two operations.

  ## Examples

    iex> TextDelta.Operation.compare(%{insert: "hello!"}, %{delete: 3})
    :gt

    iex> TextDelta.Operation.compare(%{retain: 2}, %{insert: "text"})
    :lt

    iex> TextDelta.Operation.compare(%{delete: 3}, %{retain: 3})
    :eq
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

  This is mostly used for normalisation and simplification of iteration over deltas of operations.

  ## Examples

  Text inserts are split via slicing the text itself:

    iex> TextDelta.Operation.slice(%{insert: "hello"}, 3)
    {%{insert: "hel"}, %{insert: "lo"}}

  Retains and deletes are split by subtracting the sequence number itself:

    iex> TextDelta.Operation.slice(%{retain: 5}, 2)
    {%{retain: 2}, %{retain: 3}}
    iex> TextDelta.Operation.slice(%{delete: 5}, 2)
    {%{delete: 2}, %{delete: 3}}

  Attributes are preserved during splitting:

    iex> TextDelta.Operation.slice(%{insert: "hello", attributes: %{bold: true}}, 3)
    {%{insert: "hel", attributes: %{bold: true}}, %{insert: "lo", attributes: %{bold: true}}}
  """
  @spec slice(t, non_neg_integer) :: {t, t}
  def slice(op, idx)

  def slice(%{insert: str} = op, idx) do
    {Map.put(op, :insert, String.slice(str, 0, idx)),
     Map.put(op, :insert, String.slice(str, idx..-1))}
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

  If successful, will return a list with just a single, compacted operation. In any other case both
  operations will be returned back unchanged.

  Compacting works by combining same operations with the same attributes together. Easiest way to
  think about this function is that it produces an exact opposite effect of slice function.

  This is mostly used for composition, transformation and other delta operations to keep deltas
  short and canonical.

  ## Examples

  Text inserts are compacted into a single insert:

    iex> TextDelta.Operation.compact(%{insert: "hel"}, %{insert: "lo"})
    [%{insert: "hello"}]

  Retains and deletes are compacted by adding their sequence numbers:

    iex> TextDelta.Operation.compact(%{retain: 2}, %{retain: 3})
    [%{retain: 5}]
    iex> TextDelta.Operation.compact(%{delete: 2}, %{delete: 3})
    [%{delete: 5}]

  Attributes are preserved during compaction:

    iex> TextDelta.Operation.compact(%{insert: "hel", attributes: %{bold: true}}, %{insert: "lo", attributes: %{bold: true}})
    [%{insert: "hello", attributes: %{bold: true}}]

  Operations with different attributes wouldn't compact:

    iex> TextDelta.Operation.compact(%{format: 5, attributes: %{bold: true}}, %{format: 3, attributes: %{italic: true}})
    [%{format: 5, attributes: %{bold: true}}, %{format: 3, attributes: %{italic: true}}]
  """
  @spec compact(t, t) :: [t]
  def compact(op_a, op_b)

  def compact(%{retain: len_a, attributes: attrs_a},
              %{retain: len_b, attributes: attrs_b}) when attrs_a == attrs_b do
    [retain(len_a + len_b, attrs_a)]
  end

  def compact(%{retain: len_a} = a,
              %{retain: len_b} = b) when map_size(a) == 1 and map_size(b) == 1 do
    [retain(len_a + len_b)]
  end

  def compact(%{insert: el_a} = op_a,
              %{insert: _} = op_b) when not is_bitstring(el_a) do
    [op_a, op_b]
  end

  def compact(%{insert: _} = op_a,
              %{insert: el_b} = op_b) when not is_bitstring(el_b) do
    [op_a, op_b]
  end

  def compact(%{insert: str_a, attributes: attrs_a},
              %{insert: str_b, attributes: attrs_b}) when attrs_a == attrs_b do
    [insert(str_a <> str_b, attrs_a)]
  end

  def compact(%{insert: str_a} = op_a,
              %{insert: str_b} = op_b) when map_size(op_a) == 1 and map_size(op_b) == 1 do
    [insert(str_a <> str_b)]
  end

  def compact(%{delete: len_a}, %{delete: len_b}) do
    [delete(len_a + len_b)]
  end

  def compact(op_a, op_b), do: [op_a, op_b]

  @doc """
  Checks if given operation is trimmable.

  Technically only retains are trimmable, but the creator of this library didn't feel comfortable
  exposing that knowledge outside of this module.

  ## Examples

    iex> TextDelta.Operation.trimmable?(%{insert: "hello"})
    false
    iex> TextDelta.Operation.trimmable?(%{delete: 3})
    false
    iex> TextDelta.Operation.trimmable?(%{retain: 3})
    true
  """
  @spec trimmable?(t) :: boolean
  def trimmable?(op) do
    Map.has_key?(op, :retain) and !Map.has_key?(op, :attributes)
  end
end
