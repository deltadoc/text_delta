defmodule TextDelta.Composition do
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

  alias TextDelta.{Operation, Attributes, Iterator}

  @doc """
  Composes two operations into a single equivalent operation.

  ## Example

      iex> foo = TextDelta.insert(TextDelta.new(), "Foo")
      %TextDelta{ops: [%{insert: "Foo"}]}
      iex> bar = TextDelta.insert(TextDelta.new(), "Bar")
      %TextDelta{ops: [%{insert: "Bar"}]}
      iex> TextDelta.compose(bar, foo)
      %TextDelta{ops: [%{insert: "FooBar"}]}
  """
  @spec compose(TextDelta.t, TextDelta.t) :: TextDelta.t
  def compose(first, second) do
    {TextDelta.operations(first), TextDelta.operations(second)}
    |> iterate()
    |> do_compose(TextDelta.new())
    |> TextDelta.trim()
  end

  defp do_compose({{nil, _}, {nil, _}}, result) do
    result
  end

  defp do_compose({{nil, _}, {op_b, remainder_b}}, result) do
    List.foldl([op_b | remainder_b], result, &TextDelta.append(&2, &1))
  end

  defp do_compose({{op_a, remainder_a}, {nil, _}}, result) do
    List.foldl([op_a | remainder_a], result, &TextDelta.append(&2, &1))
  end

  defp do_compose({{%{insert: _} = ins_a, remainder_a},
                   {%{insert: _} = ins_b, remainder_b}}, result) do
    {[ins_a | remainder_a], remainder_b}
    |> iterate()
    |> do_compose(TextDelta.append(result, ins_b))
  end

  defp do_compose({{%{insert: el_a} = ins, remainder_a},
                   {%{retain: _} = ret, remainder_b}}, result) do
    insert = Operation.insert(el_a, compose_attributes(ins, ret))
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(TextDelta.append(result, insert))
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
    |> do_compose(TextDelta.append(result, ins))
  end

  defp do_compose({{%{delete: _} = del, remainder_a},
                   {%{retain: _} = ret, remainder_b}}, result) do
    {remainder_a, [ret | remainder_b]}
    |> iterate()
    |> do_compose(TextDelta.append(result, del))
  end

  defp do_compose({{%{delete: _} = del_a, remainder_a},
                   {%{delete: _} = del_b, remainder_b}}, result) do
    {remainder_a, [del_b | remainder_b]}
    |> iterate()
    |> do_compose(TextDelta.append(result, del_a))
  end

  defp do_compose({{%{retain: _} = ret, remainder_a},
                   {%{insert: _} = ins, remainder_b}}, result) do
    {[ret | remainder_a], remainder_b}
    |> iterate()
    |> do_compose(TextDelta.append(result, ins))
  end

  defp do_compose({{%{retain: len} = ret_a, remainder_a},
                   {%{retain: _} = ret_b, remainder_b}}, result) do
    retain = Operation.retain(len, compose_attributes(ret_a, ret_b, true))
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(TextDelta.append(result, retain))
  end

  defp do_compose({{%{retain: _}, remainder_a},
                   {%{delete: _} = del, remainder_b}}, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_compose(TextDelta.append(result, del))
  end

  defp iterate(stream), do: Iterator.next(stream, :delete)

  defp compose_attributes(op_a, op_b, keep_nil \\ false) do
    attrs_a = Map.get(op_a, :attributes)
    attrs_b = Map.get(op_b, :attributes)
    Attributes.compose(attrs_a, attrs_b, keep_nil)
  end
end
