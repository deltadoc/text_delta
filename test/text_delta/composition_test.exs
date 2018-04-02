defmodule TextDelta.CompositionTest do
  use ExUnit.Case
  use EQC.ExUnit
  import TextDelta.Generators

  doctest TextDelta.Composition

  property "(a + b) + c = a + (b + c)" do
    forall doc <- document() do
      forall delta_a <- document_delta(doc) do
        doc_a = TextDelta.compose(doc, delta_a)

        forall delta_b <- document_delta(doc_a) do
          doc_b = TextDelta.compose(doc_a, delta_b)

          delta_c = TextDelta.compose(delta_a, delta_b)
          doc_c = TextDelta.compose(doc, delta_c)

          ensure(doc_b == doc_c)
        end
      end
    end
  end

  describe "compose" do
    test "insert with insert" do
      a =
        TextDelta.new()
        |> TextDelta.insert("A")

      b =
        TextDelta.new()
        |> TextDelta.insert("B")

      composition =
        TextDelta.new()
        |> TextDelta.insert("B")
        |> TextDelta.insert("A")

      assert TextDelta.compose(a, b) == composition
    end

    test "insert with retain" do
      a =
        TextDelta.new()
        |> TextDelta.insert("A")

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: true, color: "red", font: nil})

      composition =
        TextDelta.new()
        |> TextDelta.insert("A", %{bold: true, color: "red"})

      assert TextDelta.compose(a, b) == composition
    end

    test "insert with delete" do
      a =
        TextDelta.new()
        |> TextDelta.insert("A")

      b =
        TextDelta.new()
        |> TextDelta.delete(1)

      composition = TextDelta.new()
      assert TextDelta.compose(a, b) == composition
    end

    test "delete with insert" do
      a =
        TextDelta.new()
        |> TextDelta.delete(1)

      b =
        TextDelta.new()
        |> TextDelta.insert("B")

      composition =
        TextDelta.new()
        |> TextDelta.insert("B")
        |> TextDelta.delete(1)

      assert TextDelta.compose(a, b) == composition
    end

    test "delete with retain" do
      a =
        TextDelta.new()
        |> TextDelta.delete(1)

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: true, color: "red"})

      composition =
        TextDelta.new()
        |> TextDelta.delete(1)
        |> TextDelta.retain(1, %{bold: true, color: "red"})

      assert TextDelta.compose(a, b) == composition
    end

    test "delete with larger retain" do
      a =
        TextDelta.new()
        |> TextDelta.delete(1)

      b =
        TextDelta.new()
        |> TextDelta.retain(2)

      composition =
        TextDelta.new()
        |> TextDelta.delete(1)

      assert TextDelta.compose(a, b) == composition
    end

    test "delete with delete" do
      a =
        TextDelta.new()
        |> TextDelta.delete(1)

      b =
        TextDelta.new()
        |> TextDelta.delete(1)

      composition =
        TextDelta.new()
        |> TextDelta.delete(2)

      assert TextDelta.compose(a, b) == composition
    end

    test "retain with insert" do
      a =
        TextDelta.new()
        |> TextDelta.retain(1, %{color: "blue"})

      b =
        TextDelta.new()
        |> TextDelta.insert("B")

      composition =
        TextDelta.new()
        |> TextDelta.insert("B")
        |> TextDelta.retain(1, %{color: "blue"})

      assert TextDelta.compose(a, b) == composition
    end

    test "retain with retain" do
      a =
        TextDelta.new()
        |> TextDelta.retain(1, %{color: "blue"})

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: true, color: "red", font: nil})

      composition =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: true, color: "red", font: nil})

      assert TextDelta.compose(a, b) == composition
    end

    test "retain with delete" do
      a =
        TextDelta.new()
        |> TextDelta.retain(1, %{color: "blue"})

      b =
        TextDelta.new()
        |> TextDelta.delete(1)

      composition =
        TextDelta.new()
        |> TextDelta.delete(1)

      assert TextDelta.compose(a, b) == composition
    end

    test "insertion in the middle of a text" do
      a =
        TextDelta.new()
        |> TextDelta.insert("Hello")

      b =
        TextDelta.new()
        |> TextDelta.retain(3)
        |> TextDelta.insert("X")

      composition = TextDelta.new() |> TextDelta.insert("HelXlo")
      assert TextDelta.compose(a, b) == composition
    end

    test "insert and delete with different ordering" do
      initial =
        TextDelta.new()
        |> TextDelta.insert("Hello")

      insert_first =
        TextDelta.new()
        |> TextDelta.retain(3)
        |> TextDelta.insert("X")
        |> TextDelta.delete(1)

      delete_first =
        TextDelta.new()
        |> TextDelta.retain(3)
        |> TextDelta.delete(1)
        |> TextDelta.insert("X")

      composition =
        TextDelta.new()
        |> TextDelta.insert("HelXo")

      assert TextDelta.compose(initial, insert_first) == composition
      assert TextDelta.compose(initial, delete_first) == composition
    end

    test "insert embed" do
      a =
        TextDelta.new()
        |> TextDelta.insert(1, %{src: "img.png"})

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{alt: "logo"})

      composition =
        TextDelta.new()
        |> TextDelta.insert(1, %{src: "img.png", alt: "logo"})

      assert TextDelta.compose(a, b) == composition
    end

    test "insert half of and delete entirety of text" do
      a =
        TextDelta.new()
        |> TextDelta.retain(4)
        |> TextDelta.insert("Hello")

      b =
        TextDelta.new()
        |> TextDelta.delete(9)

      composition =
        TextDelta.new()
        |> TextDelta.delete(4)

      assert TextDelta.compose(a, b) == composition
    end

    test "retain more than the length of text" do
      a =
        TextDelta.new()
        |> TextDelta.insert("Hello")

      b =
        TextDelta.new()
        |> TextDelta.retain(10)

      composition =
        TextDelta.new()
        |> TextDelta.insert("Hello")

      assert TextDelta.compose(a, b) == composition
    end

    test "retain empty embed" do
      a =
        TextDelta.new()
        |> TextDelta.insert(1)

      b =
        TextDelta.new()
        |> TextDelta.retain(1)

      composition =
        TextDelta.new()
        |> TextDelta.insert(1)

      assert TextDelta.compose(a, b) == composition
    end

    test "remove attribute" do
      a =
        TextDelta.new()
        |> TextDelta.insert("A", %{bold: true})

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: nil})

      composition =
        TextDelta.new()
        |> TextDelta.insert("A")

      assert TextDelta.compose(a, b) == composition
    end

    test "remove embed attribute" do
      a =
        TextDelta.new()
        |> TextDelta.insert(2, %{bold: true})

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{bold: nil})

      composition =
        TextDelta.new()
        |> TextDelta.insert(2)

      assert TextDelta.compose(a, b) == composition
    end

    test "change attributes and delete parts of text" do
      a =
        TextDelta.new()
        |> TextDelta.insert("Test", %{bold: true})

      b =
        TextDelta.new()
        |> TextDelta.retain(1, %{color: "red"})
        |> TextDelta.delete(2)

      composition =
        TextDelta.new()
        |> TextDelta.insert("T", %{color: "red", bold: true})
        |> TextDelta.insert("t", %{bold: true})

      assert TextDelta.compose(a, b) == composition
    end

    test "delete+retain with delete" do
      a =
        TextDelta.new()
        |> TextDelta.delete(1)
        |> TextDelta.retain(1, %{style: "P"})

      b =
        TextDelta.new()
        |> TextDelta.delete(1)

      composition =
        TextDelta.new()
        |> TextDelta.delete(2)

      assert TextDelta.compose(a, b) == composition
    end
  end
end
