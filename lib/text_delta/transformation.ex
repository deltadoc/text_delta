defmodule TextDelta.Transformation do
  @moduledoc """
  The transformation of two concurrent operations such that they satisfy the
  convergence properties of Operational Transformation.

  Transformation allows optimistic conflict resolution in concurrent editing.
  Given an operation A that occurred at the same time as operation B against the
  same text state, we can transform the components of operation A such that the
  state of the text after applying operation A and then operation B is the same
  as after applying operation B and then the transformation of operation A
  against operation B:

    S ○ Oa ○ transform(Ob, Oa) = S ○ Ob ○ transform(Oa, Ob)

  There is a great article writte on [Operational Transformation][ot1] that
  author of this library used. It is called [Understanding and Applying
  Operational Transformation][ot2].

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot1]: https://en.wikipedia.org/wiki/Operational_transformation
  [ot2]: http://www.codecommit.com/blog/java/understanding-and-applying-operational-transformation
  """

  alias TextDelta.{Operation, Attributes, Iterator}

  @typedoc """
  Atom representing transformation priority. Which delta came first?
  """
  @type priority :: :left | :right

  @doc """
  Transforms `right` delta against the `left` one.

  The function also takes a third `t:TextDelta.Transformation.priority/0`
  argument that indicates which delta came first. This is important when
  deciding whether it is acceptable to break up insert operations from one
  delta or the other.
  """
  @spec transform(TextDelta.t, TextDelta.t, priority) :: TextDelta.t
  def transform(left, right, priority) do
    {TextDelta.operations(left), TextDelta.operations(right)}
    |> iterate()
    |> do_transform(priority, TextDelta.new())
    |> TextDelta.trim()
  end

  defp do_transform({{_, _}, {nil, _}}, _, result) do
    result
  end

  defp do_transform({{nil, _}, {op_b, remainder_b}}, _, result) do
    List.foldl([op_b | remainder_b], result, &TextDelta.append(&2, &1))
  end

  defp do_transform({{%{insert: _} = ins_a, remainder_a},
                     {%{insert: _} = ins_b, remainder_b}}, :left, result) do
    retain = make_retain(ins_a)
    {remainder_a, [ins_b | remainder_b]}
    |> iterate()
    |> do_transform(:left, TextDelta.append(result, retain))
  end

  defp do_transform({{%{insert: _} = ins_a, remainder_a},
                     {%{insert: _} = ins_b, remainder_b}}, :right, result) do
    {[ins_a | remainder_a], remainder_b}
    |> iterate()
    |> do_transform(:right, TextDelta.append(result, ins_b))
  end

  defp do_transform({{%{insert: _} = ins, remainder_a},
                     {%{retain: _} = ret, remainder_b}}, priority, result) do
    retain = make_retain(ins)
    {remainder_a, [ret | remainder_b]}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, retain))
  end

  defp do_transform({{%{insert: _} = ins, remainder_a},
                     {%{delete: _} = del, remainder_b}}, priority, result) do
    retain = make_retain(ins)
    {remainder_a, [del | remainder_b]}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, retain))
  end

  defp do_transform({{%{delete: _} = del, remainder_a},
                     {%{insert: _} = ins, remainder_b}}, priority, result) do
    {[del | remainder_a], remainder_b}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, ins))
  end

  defp do_transform({{%{delete: _}, remainder_a},
                     {%{retain: _}, remainder_b}}, priority, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_transform(priority, result)
  end

  defp do_transform({{%{delete: _}, remainder_a},
                     {%{delete: _}, remainder_b}}, priority, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_transform(priority, result)
  end

  defp do_transform({{%{retain: _} = ret, remainder_a},
                     {%{insert: _} = ins, remainder_b}}, priority, result) do
    {[ret | remainder_a], remainder_b}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, ins))
  end

  defp do_transform({{%{retain: _} = ret_a, remainder_a},
                     {%{retain: _} = ret_b, remainder_b}}, priority, result) do
    retain = make_retain(ret_a, transform_attributes(ret_a, ret_b, priority))
    {remainder_a, remainder_b}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, retain))
  end

  defp do_transform({{%{retain: _}, remainder_a},
                     {%{delete: _} = del, remainder_b}}, priority, result) do
    {remainder_a, remainder_b}
    |> iterate()
    |> do_transform(priority, TextDelta.append(result, del))
  end

  defp iterate(stream), do: Iterator.next(stream, :insert)

  defp make_retain(op, attrs \\ %{}) do
    op
    |> Operation.length()
    |> Operation.retain(attrs)
  end

  defp transform_attributes(op_a, op_b, priority) do
    attrs_a = Map.get(op_a, :attributes)
    attrs_b = Map.get(op_b, :attributes)
    Attributes.transform(attrs_a, attrs_b, priority)
  end
end
