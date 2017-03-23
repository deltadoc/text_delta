defmodule TextDelta.Delta.Composition do
  @moduledoc """
  The composition of two non-concurrent operations into a single operation.

  The operations are composed in such a way that the resulting operation has the
  same effect on document state as applying one operation and then the other:

    S ○ compose(Oa, Ob) = S ○ Oa ○ Ob

  In more simple terms, composition allows you to take many operations and
  transform them into one of equal effect. When used together with Operational
  Transformation that allows to reduce system overhead when tracking non-synced
  changes.
  """

  alias TextDelta.{Delta, Operation, Attributes}
  alias TextDelta.Delta.Iterator

  @doc """
  Composes two operations into a single equivalent operation.

  ## Examples

    iex> TextDelta.Delta.compose([%{insert: "Bar"}], [%{insert: "Foo"}])
    [%{insert: "FooBar"}]
  """
  @spec compose(Delta.t, Delta.t) :: Delta.t
  def compose(delta_a, delta_b) do
    {delta_a, delta_b}
    |> iterate()
    |> do_compose(Delta.new())
    |> Delta.trim()
  end

  defp do_compose({{nil, _}, {nil, _}}, result) do
    result
  end

  defp do_compose({{nil, _}, {op_b, remainder_b}}, result) do
    List.foldl([op_b | remainder_b], result, &Delta.append(&2, &1))
  end

  defp do_compose({{op_a, remainder_a}, {nil, _}}, result) do
    List.foldl([op_a | remainder_a], result, &Delta.append(&2, &1))
  end

  defp do_compose({{%{insert: _} = ins_a, remainder_a},
                   {%{insert: _} = ins_b, remainder_b}}, result) do
    {[ins_a | remainder_a], remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, ins_b))
  end

  defp do_compose({{%{insert: el_a} = ins, remainder_a},
                   {%{retain: _} = ret, remainder_b}}, result) do
    insert = Operation.insert(el_a, compose_attributes(ins, ret))
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, insert))
  end

  defp do_compose({{%{insert: _}, remainder_a},
                   {%{delete: _}, remainder_b}}, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(result)
  end

  defp do_compose({{%{delete: _} = del, remainder_a},
                   {%{insert: _} = ins, remainder_b}}, result) do
    {[del | remainder_a], remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, ins))
  end

  defp do_compose({{%{delete: _} = del, remainder_a},
                   {%{retain: _} = ret, remainder_b}}, result) do
    {remainder_a, [ret, remainder_b]}
    |> iterate()
    |> do_compose(Delta.append(result, del))
  end

  defp do_compose({{%{delete: len_a}, remainder_a},
                   {%{delete: len_b}, remainder_b}}, result) do
    delete = Operation.delete(len_a + len_b)
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, delete))
  end

  defp do_compose({{%{retain: _} = ret, remainder_a},
                   {%{insert: _} = ins, remainder_b}}, result) do
    {[ret | remainder_a], remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, ins))
  end

  defp do_compose({{%{retain: len} = ret_a, remainder_a},
                   {%{retain: _} = ret_b, remainder_b}}, result) do
    retain = Operation.retain(len, compose_attributes(ret_a, ret_b, true))
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, retain))
  end

  defp do_compose({{%{retain: _}, remainder_a},
                   {%{delete: _} = del, remainder_b}}, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(Delta.append(result, del))
  end

  defp iterate(stream), do: Iterator.next(stream, :delete)

  defp compose_attributes(op_a, op_b, keep_nil \\ false) do
    attrs_a = Map.get(op_a, :attributes)
    attrs_b = Map.get(op_b, :attributes)
    Attributes.compose(attrs_a, attrs_b, keep_nil)
  end
end
