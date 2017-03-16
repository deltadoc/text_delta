defmodule TextDelta.DeltaTest do
  use ExUnit.Case
  doctest TextDelta.Delta
  alias TextDelta.{Delta, Operation}

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
end
