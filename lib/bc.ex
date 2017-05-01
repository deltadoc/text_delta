defmodule TextDelta.Delta do
  @moduledoc """
  This module is here only for backwards compatibility. Use `TextDelta` instead.
  """

  alias TextDelta.{Operation, Attributes, Transformation}

  @type t :: [Operation.t]
  @type document :: [Operation.insert]

  @doc false
  @spec new([Operation.t]) :: t
  def new(ops \\ []) do
    TextDelta.new(ops)
  end

  @doc false
  @spec insert(t, Operation.element, Attributes.t) :: t
  def insert(delta, el, attrs \\ %{}) do
    TextDelta.insert(delta, el, attrs)
  end

  @doc false
  @spec retain(t, non_neg_integer, Attributes.t) :: t
  def retain(delta, len, attrs \\ %{}) do
    TextDelta.retain(delta, len, attrs)
  end

  @doc false
  @spec delete(t, non_neg_integer) :: t
  def delete(delta, len) do
    TextDelta.delete(delta, len)
  end

  @doc false
  @spec append(t, Operation.t) :: t
  def append(delta, op) do
    TextDelta.append(delta, op)
  end

  @doc false
  @spec compose(t, t) :: t
  def compose(delta_a, delta_b) do
    TextDelta.compose(delta_a, delta_b)
  end

  @doc false
  @spec transform(t, t, Transformation.priority) :: t
  def transform(delta_a, delta_b, priority) do
    TextDelta.transform(delta_a, delta_b, priority)
  end

  @doc false
  @spec trim(t) :: t
  def trim(delta) do
    TextDelta.trim(delta)
  end

  @doc false
  @spec length(t, [Operation.type]) :: non_neg_integer
  def length(delta, included_ops \\ [:insert, :retain, :delete]) do
    TextDelta.length(delta, included_ops)
  end
end

defmodule TextDelta.Delta.Composition do
  @moduledoc """
  This module is here only for backwards compatibility. Use
  `TextDelta.Composition` instead.
  """

  defdelegate compose(delta_a, delta_b),
    to: TextDelta.Composition
end

defmodule TextDelta.Delta.Transformation do
  @moduledoc """
  This module is here only for backwards compatibility. Use
  `TextDelta.Transformation` instead.
  """

  @type priority :: :left | :right

  defdelegate transform(delta_a, delta_b, priority),
    to: TextDelta.Transformation
end

defmodule TextDelta.Delta.Iterator do
  @moduledoc """
  This module is here only for backwards compatibility. Use
  `TextDelta.Iterator` instead.
  """

  @type deltas :: {Delta.t, Delta.t}
  @type skip_type :: :insert | :delete | nil
  @type cycle :: {delta_split, delta_split}
  @type delta_split :: {Operation.t | nil, Delta.t}

  defdelegate next(deltas, skip_type \\ nil),
    to: TextDelta.Iterator
end
