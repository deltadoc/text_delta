defmodule TextDelta.DocumentTest do
  use ExUnit.Case

  doctest TextDelta.Document

  describe "lines" do
    test "not a document" do
      delta = TextDelta.delete(TextDelta.new(), 5)
      assert {:error, :bad_document} = TextDelta.lines(delta)
      delta = TextDelta.retain(TextDelta.new(), 5)
      assert {:error, :bad_document} = TextDelta.lines(delta)
      delta =
        TextDelta.new
        |> TextDelta.delete(2)
        |> TextDelta.insert("5")
        |> TextDelta.retain(5)
      assert {:error, :bad_document} = TextDelta.lines(delta)
    end

    test "empty document" do
      delta = TextDelta.new()
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == []
    end

    test "document with a single insert" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a")
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{delta, %{}}]
    end

    test "document with one insert containing newline" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a\nb")
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("a")
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("b")
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{}}, {b_delta, %{}}]
    end

    test "document with one insert containing two newlines" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a\nb\nc\n")
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("a")
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("b")
      c_delta =
        TextDelta.new()
        |> TextDelta.insert("c")
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{}}, {b_delta, %{}}, {c_delta, %{}}]
    end

    test "document with one paragraph, including newline attributes" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("ab", %{bold: true})
        |> TextDelta.insert("\n", %{header: 1})
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("ab", %{bold: true})
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{header: 1}}]
    end

    test "document with embeds" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("ab")
        |> TextDelta.insert(1)
        |> TextDelta.insert("\n")
        |> TextDelta.insert("c")
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("ab")
        |> TextDelta.insert(1)
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("c")
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{}}, {b_delta, %{}}]
    end

    test "document with two paragraphs, but only one with newline attributes" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("ab", %{bold: true})
        |> TextDelta.insert("\n", %{header: 1})
        |> TextDelta.insert("cd")
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("ab", %{bold: true})
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("cd")
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{header: 1}}, {b_delta, %{}}]
    end

    test "complex document including mixed attributes" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a")
        |> TextDelta.insert("b", %{bold: true})
        |> TextDelta.insert("cd\n")
        |> TextDelta.insert("e", %{italic: true})
        |> TextDelta.insert("f", %{bold: false})
        |> TextDelta.insert("\n", %{header: 2})
        |> TextDelta.insert("g")
        |> TextDelta.insert("h\n", %{bold: true, italic: true})
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("a")
        |> TextDelta.insert("b", %{bold: true})
        |> TextDelta.insert("cd")
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("e", %{italic: true})
        |> TextDelta.insert("f", %{bold: false})
      c_delta =
        TextDelta.new()
        |> TextDelta.insert("g")
        |> TextDelta.insert("h", %{bold: true, italic: true})
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{}}, {b_delta, %{header: 2}}, {c_delta, %{}}]
    end

    test "document with one insert containing both newline and attributes" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("a\nb", %{bold: true})
      a_delta =
        TextDelta.new()
        |> TextDelta.insert("a", %{bold: true})
      b_delta =
        TextDelta.new()
        |> TextDelta.insert("b", %{bold: true})
      assert {:ok, lines} = TextDelta.lines(delta)
      assert lines == [{a_delta, %{}}, {b_delta, %{}}]
    end
  end
end
