defmodule TextDelta.IteratorTest do
  use ExUnit.Case

  alias TextDelta.Iterator

  describe "next" do
    test "of empty deltas" do
      assert Iterator.next({[], []}) == {{nil, []}, {nil, []}}
    end

    test "of an empty delta" do
      delta = TextDelta.new() |> TextDelta.insert("test")
      assert Iterator.next({[], delta}) == {{nil, []}, {%{insert: "test"}, []}}
      assert Iterator.next({delta, []}) == {{%{insert: "test"}, []}, {nil, []}}
    end

    test "operations of equal length" do
      delta_a = TextDelta.new() |> TextDelta.insert("test")
      delta_b = TextDelta.new() |> TextDelta.retain(4)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, []}
      }
    end

    test "operations of different length (>)" do
      delta_a = TextDelta.new() |> TextDelta.insert("test")
      delta_b = TextDelta.new() |> TextDelta.retain(2)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "te"}, [%{insert: "st"}]},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (>) with skip" do
      delta_a = TextDelta.new() |> TextDelta.insert("test")
      delta_b = TextDelta.new() |> TextDelta.retain(2)
      assert Iterator.next({delta_a, delta_b}, :insert) == {
        {%{insert: "test"}, []},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (<)" do
      delta_a = TextDelta.new() |> TextDelta.insert("test")
      delta_b = TextDelta.new() |> TextDelta.retain(6)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, [%{retain: 2}]}
      }
    end
  end
end
