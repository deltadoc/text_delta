defmodule TextDelta.IteratorTest do
  use ExUnit.Case

  alias TextDelta.{Operation, Iterator}

  describe "next" do
    test "of empty operation lists" do
      assert Iterator.next({[], []}) == {{nil, []}, {nil, []}}
    end

    test "of an empty operation list" do
      ops = [Operation.insert("test")]
      assert Iterator.next({[], ops}) == {{nil, []}, {%{insert: "test"}, []}}
      assert Iterator.next({ops, []}) == {{%{insert: "test"}, []}, {nil, []}}
    end

    test "operations of equal length" do
      ops_a = [Operation.insert("test")]
      ops_b = [Operation.retain(4)]
      assert Iterator.next({ops_a, ops_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, []}
      }
    end

    test "operations of different length (>)" do
      ops_a = [Operation.insert("test")]
      ops_b = [Operation.retain(2)]
      assert Iterator.next({ops_a, ops_b}) == {
        {%{insert: "te"}, [%{insert: "st"}]},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (>) with skip" do
      ops_a = [Operation.insert("test")]
      ops_b = [Operation.retain(2)]
      assert Iterator.next({ops_a, ops_b}, :insert) == {
        {%{insert: "test"}, []},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (<)" do
      ops_a = [Operation.insert("test")]
      ops_b = [Operation.retain(6)]
      assert Iterator.next({ops_a, ops_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, [%{retain: 2}]}
      }
    end
  end
end
