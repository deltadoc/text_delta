defmodule TextDelta.Iterator do
  @moduledoc """
  Iterator iterates over two deltas at the same time, ensuring next elements in
  the resulting stream are of equal length.
  """

  alias TextDelta.Operation

  @typedoc """
  Two deltas to iterate.
  """
  @type deltas :: {TextDelta.t, TextDelta.t}

  @typedoc """
  A type which is not to be sliced when iterating. Can be `:insert`, `:delete`
  or nil
  """
  @type skip_type :: :insert | :delete | nil

  @typedoc """
  A tuple representing the new head operations and tail deltas of the two
  deltas being iterated over.
  """
  @type cycle :: {delta_split, delta_split}

  @typedoc """
  A delta's next scanned full or partial operation, and its resulting tail
  delta.
  """
  @type delta_split :: {Operation.t | nil, TextDelta.t}

  @doc """
  Generates next cycle by iterating over given deltas.
  """
  @spec next(deltas, skip_type) :: cycle
  def next(deltas, skip_type \\ nil)

  def next({[], []}, _) do
    {{nil, []}, {nil, []}}
  end

  def next({[], [head_b | tail_b]}, _) do
    {{nil, []}, {head_b, tail_b}}
  end

  def next({[head_a | tail_a], []}, _) do
    {{head_a, tail_a}, {nil, []}}
  end

  def next({[head_a | _], [head_b | _]} = deltas, skip_type) do
    comparison = Operation.compare(head_a, head_b)
    skip = Operation.type(head_a) == skip_type
    do_next(deltas, comparison, skip)
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, :gt, false) do
    {head_a, remainder_a} = Operation.slice(head_a, Operation.length(head_b))
    {{head_a, [remainder_a | tail_a]}, {head_b, tail_b}}
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, :lt, _) do
    {head_b, remainder_b} = Operation.slice(head_b, Operation.length(head_a))
    {{head_a, tail_a}, {head_b, [remainder_b | tail_b]}}
  end

  defp do_next({[head_a | tail_a], [head_b | tail_b]}, _, _) do
    {{head_a, tail_a}, {head_b, tail_b}}
  end
end
