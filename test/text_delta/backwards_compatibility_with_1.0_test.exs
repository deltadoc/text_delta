# Backwards compatibility layer tests. To be removed in 2.0.

defmodule TextDelta.BCTest do
  use ExUnit.Case

  alias TextDelta.{Delta, Operation}
  alias TextDelta.Delta.{Iterator}

  describe "create" do
    test "empty delta" do
      assert Delta.new() == []
    end

    test "empty operations" do
      delta =
        Delta.new()
        |> Delta.insert("")
        |> Delta.delete(0)
        |> Delta.retain(0)
      assert delta == []
    end
  end

  describe "insert" do
    test "text" do
      delta = Delta.new() |> Delta.insert("test")
      assert delta == [%{insert: "test"}]
    end

    test "after delete" do
      delta =
        Delta.new()
        |> Delta.delete(1)
        |> Delta.insert("a")
      assert delta == [%{insert: "a"}, %{delete: 1}]
    end

    test "after delete with merge" do
      delta =
        Delta.new()
        |> Delta.insert("a")
        |> Delta.delete(1)
        |> Delta.insert("b")
      assert delta == [%{insert: "ab"}, %{delete: 1}]
    end

    test "after delete without merge" do
      delta =
        Delta.new()
        |> Delta.insert(1)
        |> Delta.delete(1)
        |> Delta.insert("a")
      assert delta == [%{insert: 1}, %{insert: "a"}, %{delete: 1}]
    end
  end

  describe "delete" do
    test "0" do
      delta = Delta.new() |> Delta.delete(0)
      assert delta == []
    end

    test "positive" do
      delta = Delta.new() |> Delta.delete(3)
      assert delta == [%{delete: 3}]
    end
  end

  describe "retain" do
    test "0" do
      delta = Delta.new() |> Delta.retain(0)
      assert delta == []
    end

    test "positive" do
      delta = Delta.new() |> Delta.retain(3)
      assert delta == [%{retain: 3}]
    end
  end

  describe "append" do
    test "to empty delta" do
      op = Operation.insert("a")
      assert Delta.append([], op) == [%{insert: "a"}]
      assert Delta.append(nil, op) == [%{insert: "a"}]
    end

    test "no operation" do
      delta = Delta.new()
      assert Delta.append(delta, nil) == []
      assert Delta.append(delta, []) == []
    end

    test "consecutive deletes" do
      delta = Delta.new() |> Delta.delete(3)
      op = Operation.delete(3)
      assert Delta.append(delta, op) == [%{delete: 6}]
    end

    test "consecutive inserts" do
      delta = Delta.new() |> Delta.insert("a")
      op = Operation.insert("c")
      assert Delta.append(delta, op) == [%{insert: "ac"}]
    end

    test "consecutive inserts with same attributes" do
      delta = Delta.new() |> Delta.insert("a", %{bold: true})
      op = Operation.insert("c", %{bold: true})
      assert Delta.append(delta, op) == [%{insert: "ac", attributes: %{bold: true}}]
    end

    test "consecutive embed inserts with same attributes" do
      delta = Delta.new() |> Delta.insert(1, %{bold: true})
      op = Operation.insert(1, %{bold: true})
      assert Delta.append(delta, op) == [
        %{insert: 1, attributes: %{bold: true}},
        %{insert: 1, attributes: %{bold: true}}
      ]
    end

    test "consecutive embed inserts with different attributes" do
      delta = Delta.new() |> Delta.insert("a", %{bold: true})
      op = Operation.insert("c", %{italic: true})
      assert Delta.append(delta, op) == [
        %{insert: "a", attributes: %{bold: true}},
        %{insert: "c", attributes: %{italic: true}}
      ]
    end

    test "consecutive retains" do
      delta = Delta.new() |> Delta.retain(3)
      op = Operation.retain(3)
      assert Delta.append(delta, op) == [%{retain: 6}]
    end

    test "consecutive retains with same attributes" do
      delta = Delta.new() |> Delta.retain(3, %{color: "red"})
      op = Operation.retain(3, %{color: "red"})
      assert Delta.append(delta, op) == [%{retain: 6, attributes: %{color: "red"}}]
    end

    test "consecutive retains with different attributes" do
      delta = Delta.new() |> Delta.retain(3, %{color: "red"})
      op = Operation.retain(2, %{color: "blue"})
      assert Delta.append(delta, op) == [
        %{retain: 3, attributes: %{color: "red"}},
        %{retain: 2, attributes: %{color: "blue"}}
      ]
    end

    test "an edge-case with potential duplication of inserts" do
      delta =
        Delta.new()
        |> Delta.insert("collaborative")
        |> Delta.retain(1)
        |> Delta.delete(1)
        |> Delta.insert("a")

      assert delta == [
        %{insert: "collaborative"},
        %{retain: 1},
        %{insert: "a"},
        %{delete: 1}
      ]
    end
  end

  describe "trim" do
    test "delta with no retains at the end" do
      delta = Delta.new() |> Delta.insert("a")
      assert Delta.trim(delta) == [%{insert: "a"}]
    end

    test "delta with a retain at the end" do
      delta =
        Delta.new()
        |> Delta.insert("a")
        |> Delta.retain(3)
      assert Delta.trim(delta) == [%{insert: "a"}]
    end

    test "delta with a retain at the beginning" do
      delta =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("a")
      assert Delta.trim(delta) == [%{retain: 3}, %{insert: "a"}]
    end
  end

  describe "compose" do
    test "insert with insert" do
      a =
        Delta.new()
        |> Delta.insert("A")
      b =
        Delta.new()
        |> Delta.insert("B")
      composition =
        Delta.new()
        |> Delta.insert("B")
        |> Delta.insert("A")
      assert Delta.compose(a, b) == composition
    end

    test "insert with retain" do
      a =
        Delta.new()
        |> Delta.insert("A")
      b =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red", font: nil})
      composition =
        Delta.new()
        |> Delta.insert("A", %{bold: true, color: "red"})
      assert Delta.compose(a, b) == composition
    end

    test "insert with delete" do
      a =
        Delta.new()
        |> Delta.insert("A")
      b =
        Delta.new()
        |> Delta.delete(1)
      composition =
        Delta.new()
      assert Delta.compose(a, b) == composition
    end

    test "delete with insert" do
      a =
        Delta.new()
        |> Delta.delete(1)
      b =
        Delta.new()
        |> Delta.insert("B")
      composition =
        Delta.new()
        |> Delta.insert("B")
        |> Delta.delete(1)
      assert Delta.compose(a, b) == composition
    end

    test "delete with retain" do
      a =
        Delta.new()
        |> Delta.delete(1)
      b =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      composition =
        Delta.new()
        |> Delta.delete(1)
        |> Delta.retain(1, %{bold: true, color: "red"})
      assert Delta.compose(a, b) == composition
    end

    test "delete with larger retain" do
      a =
        Delta.new()
        |> Delta.delete(1)
      b =
        Delta.new()
        |> Delta.retain(2)
      composition =
        Delta.new()
        |> Delta.delete(1)
      assert Delta.compose(a, b) == composition
    end

    test "delete with delete" do
      a =
        Delta.new()
        |> Delta.delete(1)
      b =
        Delta.new()
        |> Delta.delete(1)
      composition =
        Delta.new()
        |> Delta.delete(2)
      assert Delta.compose(a, b) == composition
    end

    test "retain with insert" do
      a =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      b =
        Delta.new()
        |> Delta.insert("B")
      composition =
        Delta.new()
        |> Delta.insert("B")
        |> Delta.retain(1, %{color: "blue"})
      assert Delta.compose(a, b) == composition
    end

    test "retain with retain" do
      a =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      b =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red", font: nil})
      composition =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red", font: nil})
      assert Delta.compose(a, b) == composition
    end

    test "retain with delete" do
      a =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      b =
        Delta.new()
        |> Delta.delete(1)
      composition =
        Delta.new()
        |> Delta.delete(1)
      assert Delta.compose(a, b) == composition
    end

    test "insertion in the middle of a text" do
      a =
        Delta.new()
        |> Delta.insert("Hello")
      b =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("X")
      composition = Delta.new() |> Delta.insert("HelXlo")
      assert Delta.compose(a, b) == composition
    end

    test "insert and delete with different ordering" do
      initial =
        Delta.new()
        |> Delta.insert("Hello")
      insert_first =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("X")
        |> Delta.delete(1)
      delete_first =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.delete(1)
        |> Delta.insert("X")
      composition =
        Delta.new()
        |> Delta.insert("HelXo")
      assert Delta.compose(initial, insert_first) == composition
      assert Delta.compose(initial, delete_first) == composition
    end

    test "insert embed" do
      a =
        Delta.new()
        |> Delta.insert(1, %{src: "img.png"})
      b =
        Delta.new()
        |> Delta.retain(1, %{alt: "logo"})
      composition =
        Delta.new()
        |> Delta.insert(1, %{src: "img.png", alt: "logo"})
      assert Delta.compose(a, b) == composition
    end

    test "insert half of and delete entirety of text" do
      a =
        Delta.new()
        |> Delta.retain(4)
        |> Delta.insert("Hello")
      b =
        Delta.new()
        |> Delta.delete(9)
      composition =
        Delta.new()
        |> Delta.delete(4)
      assert Delta.compose(a, b) == composition
    end

    test "retain more than the length of text" do
      a =
        Delta.new()
        |> Delta.insert("Hello")
      b =
        Delta.new()
        |> Delta.retain(10)
      composition =
        Delta.new()
        |> Delta.insert("Hello")
      assert Delta.compose(a, b) == composition
    end

    test "retain empty embed" do
      a =
        Delta.new()
        |> Delta.insert(1)
      b =
        Delta.new()
        |> Delta.retain(1)
      composition =
        Delta.new()
        |> Delta.insert(1)
      assert Delta.compose(a, b) == composition
    end

    test "remove attribute" do
      a =
        Delta.new()
        |> Delta.insert("A", %{bold: true})
      b =
        Delta.new()
        |> Delta.retain(1, %{bold: nil})
      composition =
        Delta.new()
        |> Delta.insert("A")
      assert Delta.compose(a, b) == composition
    end

    test "remove embed attribute" do
      a =
        Delta.new()
        |> Delta.insert(2, %{bold: true})
      b =
        Delta.new()
        |> Delta.retain(1, %{bold: nil})
      composition =
        Delta.new()
        |> Delta.insert(2)
      assert Delta.compose(a, b) == composition
    end

    test "change attributes and delete parts of text" do
      a =
        Delta.new()
        |> Delta.insert("Test", %{bold: true})
      b =
        Delta.new()
        |> Delta.retain(1, %{color: "red"})
        |> Delta.delete(2)
      composition =
        Delta.new()
        |> Delta.insert("T", %{color: "red", bold: true})
        |> Delta.insert("t", %{bold: true})
      assert Delta.compose(a, b) == composition
    end

    test "delete+retain with delete" do
      a =
        Delta.new()
        |> Delta.delete(1)
        |> Delta.retain(1, %{style: "P"})
      b =
        Delta.new()
        |> Delta.delete(1)
      composition =
        Delta.new()
        |> Delta.delete(2)

      assert Delta.compose(a, b) == composition
    end
  end

  describe "transform" do
    test "insert against insert" do
      first =
        Delta.new()
        |> Delta.insert("A")
      second =
        Delta.new()
        |> Delta.insert("B")
      transformed_left =
        Delta.new()
        |> Delta.retain(1)
        |> Delta.insert("B")
      transformed_right =
        Delta.new()
        |> Delta.insert("B")
      assert Delta.transform(first, second, :left) == transformed_left
      assert Delta.transform(first, second, :right) == transformed_right
    end

    test "retain against insert" do
      first =
        Delta.new()
        |> Delta.insert("A")
      second =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      transformed =
        Delta.new()
        |> Delta.retain(1)
        |> Delta.retain(1, %{bold: true, color: "red"})
      assert Delta.transform(first, second, :left) == transformed
    end

    test "delete against insert" do
      first =
        Delta.new()
        |> Delta.insert("A")
      second =
        Delta.new()
        |> Delta.delete(1)
      transformed =
        Delta.new()
        |> Delta.retain(1)
        |> Delta.delete(1)
      assert Delta.transform(first, second, :left) == transformed
    end

    test "insert against delete" do
      first =
        Delta.new()
        |> Delta.delete(1)
      second =
        Delta.new()
        |> Delta.insert("B")
      transformed =
        Delta.new()
        |> Delta.insert("B")
      assert Delta.transform(first, second, :left) == transformed
    end

    test "retain against delete" do
      first =
        Delta.new()
        |> Delta.delete(1)
      second =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      transformed =
        Delta.new()
      assert Delta.transform(first, second, :left) == transformed
    end

    test "delete against delete" do
      first =
        Delta.new()
        |> Delta.delete(1)
      second =
        Delta.new()
        |> Delta.delete(1)
      transformed =
        Delta.new()
      assert Delta.transform(first, second, :left) == transformed
    end

    test "insert against retain" do
      first =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      second =
        Delta.new()
        |> Delta.insert("B")
      transformed =
        Delta.new()
        |> Delta.insert("B")
      assert Delta.transform(first, second, :left) == transformed
    end

    test "retain against retain" do
      first =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      second =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      transformed_second =
        Delta.new()
        |> Delta.retain(1, %{bold: true})
      transformed_first =
        Delta.new()
      assert Delta.transform(first, second, :left) == transformed_second
      assert Delta.transform(second, first, :left) == transformed_first
    end

    test "retain against retain with right as priority" do
      first =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      second =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      transformed_second =
        Delta.new()
        |> Delta.retain(1, %{bold: true, color: "red"})
      transformed_first =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      assert Delta.transform(first, second, :right) == transformed_second
      assert Delta.transform(second, first, :right) == transformed_first
    end

    test "delete against retain" do
      first =
        Delta.new()
        |> Delta.retain(1, %{color: "blue"})
      second =
        Delta.new()
        |> Delta.delete(1)
      transformed =
        Delta.new()
        |> Delta.delete(1)
      assert Delta.transform(first, second, :left) == transformed
    end

    test "alternating edits" do
      first =
        Delta.new()
        |> Delta.retain(2)
        |> Delta.insert("si")
        |> Delta.delete(5)
      second =
        Delta.new()
        |> Delta.retain(1)
        |> Delta.insert("e")
        |> Delta.delete(5)
        |> Delta.retain(1)
        |> Delta.insert("ow")
      transformed_second =
        Delta.new()
        |> Delta.retain(1)
        |> Delta.insert("e")
        |> Delta.delete(1)
        |> Delta.retain(2)
        |> Delta.insert("ow")
      transformed_first =
        Delta.new()
        |> Delta.retain(2)
        |> Delta.insert("si")
        |> Delta.delete(1)
      assert Delta.transform(first, second, :right) == transformed_second
      assert Delta.transform(second, first, :right) == transformed_first
    end

    test "conflicting appends" do
      first =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("aa")
      second =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("bb")
      transformed_second_with_left_priority =
        Delta.new()
        |> Delta.retain(5)
        |> Delta.insert("bb")
      transformed_first_with_right_priority =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("aa")
      assert Delta.transform(first, second, :left) == transformed_second_with_left_priority
      assert Delta.transform(second, first, :right) == transformed_first_with_right_priority
    end

    test "prepend and append" do
      first =
        Delta.new()
        |> Delta.insert("aa")
      second =
        Delta.new()
        |> Delta.retain(3)
        |> Delta.insert("bb")
      transformed_second =
        Delta.new()
        |> Delta.retain(5)
        |> Delta.insert("bb")
      transformed_first =
        Delta.new()
        |> Delta.insert("aa")
      assert Delta.transform(first, second, :right) == transformed_second
      assert Delta.transform(second, first, :right) == transformed_first
    end

    test "trailing deletes with differing lengths" do
      first =
        Delta.new()
        |> Delta.retain(2)
        |> Delta.delete(1)
      second =
        Delta.new()
        |> Delta.delete(3)
      transformed_second =
        Delta.new()
        |> Delta.delete(2)
      transformed_first =
        Delta.new()
      assert Delta.transform(first, second, :right) == transformed_second
      assert Delta.transform(second, first, :right) == transformed_first
    end
  end

  describe "Iterator.next" do
    test "of empty deltas" do
      assert Iterator.next({[], []}) == {{nil, []}, {nil, []}}
    end

    test "of an empty delta" do
      delta = Delta.new() |> Delta.insert("test")
      assert Iterator.next({[], delta}) == {{nil, []}, {%{insert: "test"}, []}}
      assert Iterator.next({delta, []}) == {{%{insert: "test"}, []}, {nil, []}}
    end

    test "operations of equal length" do
      delta_a = Delta.new() |> Delta.insert("test")
      delta_b = Delta.new() |> Delta.retain(4)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, []}
      }
    end

    test "operations of different length (>)" do
      delta_a = Delta.new() |> Delta.insert("test")
      delta_b = Delta.new() |> Delta.retain(2)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "te"}, [%{insert: "st"}]},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (>) with skip" do
      delta_a = Delta.new() |> Delta.insert("test")
      delta_b = Delta.new() |> Delta.retain(2)
      assert Iterator.next({delta_a, delta_b}, :insert) == {
        {%{insert: "test"}, []},
        {%{retain: 2}, []}
      }
    end

    test "operations of different length (<)" do
      delta_a = Delta.new() |> Delta.insert("test")
      delta_b = Delta.new() |> Delta.retain(6)
      assert Iterator.next({delta_a, delta_b}) == {
        {%{insert: "test"}, []},
        {%{retain: 4}, [%{retain: 2}]}
      }
    end
  end
end
