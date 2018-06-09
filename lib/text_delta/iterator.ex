defmodule TextDelta.Iterator do
  @moduledoc """
  Iterator iterates over two sets of operations at the same time, ensuring next
  elements in the resulting stream are of equal length.
  """

  alias TextDelta.Operation

  @typedoc """
  Individual set of operations.
  """
  @type set :: [Operation.t()]

  @typedoc """
  Two sets of operations to iterate.
  """
  @type sets :: {set, set}

  @typedoc """
  A type which is not to be sliced when iterating. Can be `:insert`, `:delete`
  or nil
  """
  @type skip_type :: :insert | :delete | nil

  @typedoc """
  A tuple representing the new head and tail operations of the two operation
  sets being iterated over.
  """
  @type cycle :: {set_split, set_split}

  @typedoc """
  A set's next scanned full or partial operation, and its resulting tail set.
  """
  @type set_split :: {Operation.t() | nil, set}

  @doc """
  Generates next cycle by iterating over given sets of operations.
  """
  @spec next(sets, skip_type) :: cycle
  def next(sets, skip_type \\ nil)

  def next({[], []}, _) do
    {{nil, []}, {nil, []}}
  end

  def next({[], [head_b | tail_b]}, _) do
    {{nil, []}, {head_b, tail_b}}
  end

  def next({[head_a | tail_a], []}, _) do
    {{head_a, tail_a}, {nil, []}}
  end

  def next({[head_a | _], [head_b | _]} = sets, skip_type) do
    skip = Operation.type(head_a) == skip_type
    len_a = Operation.length(head_a)
    len_b = Operation.length(head_b)

    cond do
      len_a > len_b -> do_next(sets, :gt, len_b, skip)
      len_a < len_b -> do_next(sets, :lt, len_a, skip)
      true -> do_next(sets, :eq, 0, skip)
    end
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, :gt, len, false) do
    {head_a, remainder_a} = Operation.slice(head_a, len)
    {{head_a, [remainder_a | tail_a]}, {head_b, tail_b}}
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, :lt, len, _) do
    {head_b, remainder_b} = Operation.slice(head_b, len)
    {{head_a, tail_a}, {head_b, [remainder_b | tail_b]}}
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, _, _, _) do
    {{head_a, tail_a}, {head_b, tail_b}}
  end
end
