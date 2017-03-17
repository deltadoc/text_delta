defmodule TextDelta.Delta.CompositionTest do
  use ExUnit.Case
  alias TextDelta.Delta
  doctest TextDelta.Delta.Composition

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
  end
end
