defmodule TextDeltaTest do
  use ExUnit.Case
  use EQC.ExUnit
  import TextDelta.Generators

  alias TextDelta.Operation
  doctest TextDelta

  describe "compaction" do
    property "consecutive operations with same attributes compact" do
      forall ops <- list(oneof([bitstring_insert(), retain(), delete()])) do
        delta = TextDelta.new(ops)
        ensure(consecutive_ops_with_same_attrs(delta) == 0)
      end
    end

    defp consecutive_ops_with_same_attrs(%TextDelta{ops: []}), do: 0

    defp consecutive_ops_with_same_attrs(delta) do
      delta
      |> TextDelta.operations()
      |> Enum.chunk_by(&{Operation.type(&1), Map.get(&1, :attributes)})
      |> Enum.filter(&(Enum.count(&1) > 1))
      |> Enum.count()
    end
  end

  describe "create" do
    test "empty delta" do
      assert ops(TextDelta.new()) == []
    end

    test "empty delta using zero-operations" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("")
        |> TextDelta.delete(0)
        |> TextDelta.retain(0)

      assert ops(delta) == []
    end
  end

  describe "insert" do
    test "text" do
      delta = TextDelta.insert(TextDelta.new(), "test")
      assert ops(delta) == [%{insert: "test"}]
    end

    test "after delete" do
      delta =
        TextDelta.new()
        |> TextDelta.delete(1)
        |> TextDelta.insert("a")

      assert ops(delta) == [%{insert: "a"}, %{delete: 1}]
    end

    test "after delete with merge" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a")
        |> TextDelta.delete(1)
        |> TextDelta.insert("b")

      assert ops(delta) == [%{insert: "ab"}, %{delete: 1}]
    end

    test "after delete without merge" do
      delta =
        TextDelta.new()
        |> TextDelta.insert(1)
        |> TextDelta.delete(1)
        |> TextDelta.insert("a")

      assert ops(delta) == [%{insert: 1}, %{insert: "a"}, %{delete: 1}]
    end
  end

  describe "delete" do
    test "0" do
      delta = TextDelta.delete(TextDelta.new(), 0)
      assert ops(delta) == []
    end

    test "positive" do
      delta = TextDelta.delete(TextDelta.new(), 3)
      assert ops(delta) == [%{delete: 3}]
    end
  end

  describe "retain" do
    test "0" do
      delta = TextDelta.retain(TextDelta.new(), 0)
      assert ops(delta) == []
    end

    test "positive" do
      delta = TextDelta.retain(TextDelta.new(), 3)
      assert ops(delta) == [%{retain: 3}]
    end
  end

  describe "append" do
    test "to empty delta" do
      op = Operation.insert("a")
      assert ops(TextDelta.append(%TextDelta{}, op)) == [%{insert: "a"}]
    end

    test "noop" do
      delta = TextDelta.new()
      assert ops(TextDelta.append(delta, nil)) == []
      assert ops(TextDelta.append(delta, [])) == []
    end

    test "consecutive deletes" do
      delta = TextDelta.delete(TextDelta.new(), 3)
      op = Operation.delete(3)
      assert ops(TextDelta.append(delta, op)) == [%{delete: 6}]
    end

    test "consecutive inserts" do
      delta = TextDelta.insert(TextDelta.new(), "a")
      op = Operation.insert("c")
      assert ops(TextDelta.append(delta, op)) == [%{insert: "ac"}]
    end

    test "consecutive inserts with same attributes" do
      delta = TextDelta.insert(TextDelta.new(), "a", %{bold: true})
      op = Operation.insert("c", %{bold: true})

      assert ops(TextDelta.append(delta, op)) == [
               %{insert: "ac", attributes: %{bold: true}}
             ]
    end

    test "consecutive embed inserts with same attributes" do
      delta = TextDelta.insert(TextDelta.new(), 1, %{bold: true})
      op = Operation.insert(1, %{bold: true})

      assert ops(TextDelta.append(delta, op)) == [
               %{insert: 1, attributes: %{bold: true}},
               %{insert: 1, attributes: %{bold: true}}
             ]
    end

    test "consecutive embed inserts with different attributes" do
      delta = TextDelta.insert(TextDelta.new(), "a", %{bold: true})
      op = Operation.insert("c", %{italic: true})

      assert ops(TextDelta.append(delta, op)) == [
               %{insert: "a", attributes: %{bold: true}},
               %{insert: "c", attributes: %{italic: true}}
             ]
    end

    test "consecutive retains" do
      delta = TextDelta.retain(TextDelta.new(), 3)
      op = Operation.retain(3)
      assert ops(TextDelta.append(delta, op)) == [%{retain: 6}]
    end

    test "consecutive retains with same attributes" do
      delta = TextDelta.retain(TextDelta.new(), 3, %{color: "red"})
      op = Operation.retain(3, %{color: "red"})

      assert ops(TextDelta.append(delta, op)) == [
               %{retain: 6, attributes: %{color: "red"}}
             ]
    end

    test "consecutive retains with different attributes" do
      delta = TextDelta.retain(TextDelta.new(), 3, %{color: "red"})
      op = Operation.retain(2, %{color: "blue"})

      assert ops(TextDelta.append(delta, op)) == [
               %{retain: 3, attributes: %{color: "red"}},
               %{retain: 2, attributes: %{color: "blue"}}
             ]
    end
  end

  describe "trim" do
    test "delta with no retains at the end" do
      delta = TextDelta.insert(TextDelta.new(), "a")
      assert ops(TextDelta.trim(delta)) == [%{insert: "a"}]
    end

    test "delta with a retain at the end" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a")
        |> TextDelta.retain(3)

      assert ops(TextDelta.trim(delta)) == [%{insert: "a"}]
    end

    test "delta with a retain at the beginning" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(3)
        |> TextDelta.insert("a")

      assert ops(TextDelta.trim(delta)) == [%{retain: 3}, %{insert: "a"}]
    end
  end

  describe "an edge case of" do
    test "potential duplication of inserts" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("collaborative")
        |> TextDelta.retain(1)
        |> TextDelta.delete(1)
        |> TextDelta.insert("a")

      assert ops(delta) == [
               %{insert: "collaborative"},
               %{retain: 1},
               %{insert: "a"},
               %{delete: 1}
             ]
    end
  end

  defp ops(delta), do: TextDelta.operations(delta)
end
