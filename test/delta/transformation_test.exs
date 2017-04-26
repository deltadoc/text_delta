defmodule TextDelta.Delta.TransformationTest do
  use ExUnit.PropertyCase

  alias TextDelta.Delta

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

  property "composing delta with its prime results in consistent state" do
    forall {doc, {priority_a, priority_b}} <- {document(), priorities()} do
      forall {ops_a, ops_b} <- {operations(), operations()} do
        a = delta_from_operations(ops_a)
        b = delta_from_operations(ops_b)

        implies Enum.max([delta_len(a), delta_len(b)]) <= doc_len(doc) do
          a_prime = Delta.transform(b, a, priority_a)
          b_prime = Delta.transform(a, b, priority_b)

          doc_a =
            doc
            |> Delta.compose(a)
            |> Delta.compose(b_prime)
          doc_b =
            doc
            |> Delta.compose(b)
            |> Delta.compose(a_prime)

          ensure doc_a == doc_b
        end
      end
    end
  end
end
