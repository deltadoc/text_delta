defmodule TextDelta.DifferenceTest do
  use ExUnit.Case
  use EQC.ExUnit
  import TextDelta.Generators

  doctest TextDelta.Difference

  property "applying diff always results in expected document" do
    forall document_a <- document() do
      forall document_b <- document() do
        diff = TextDelta.diff!(document_a, document_b)
        ensure TextDelta.apply!(document_a, diff) == document_b
      end
    end
  end

  describe "diff" do
    test "invalid documents" do
      bad_a = TextDelta.retain(TextDelta.new(), 5)
      bad_b = TextDelta.delete(TextDelta.new(), 3)
      good = TextDelta.insert(TextDelta.new(), "A")
      assert {:error, :bad_document} = TextDelta.diff(bad_a, bad_b)
      assert {:error, :bad_document} = TextDelta.diff(good, bad_b)
      assert {:error, :bad_document} = TextDelta.diff(bad_a, good)
    end

    test "insert" do
      a = TextDelta.insert(TextDelta.new(), "A")
      b = TextDelta.insert(TextDelta.new(), "AB")
      delta =
        TextDelta.new()
        |> TextDelta.retain(1)
        |> TextDelta.insert("B")
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "delete" do
      a = TextDelta.insert(TextDelta.new(), "AB")
      b = TextDelta.insert(TextDelta.new(), "A")
      delta =
        TextDelta.new()
        |> TextDelta.retain(1)
        |> TextDelta.delete(1)
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "retain" do
      a = TextDelta.insert(TextDelta.new(), "A")
      b = TextDelta.insert(TextDelta.new(), "A")
      delta = TextDelta.new()
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "format" do
      a = TextDelta.insert(TextDelta.new(), "A")
      b = TextDelta.insert(TextDelta.new(), "A", %{bold: true})
      delta = TextDelta.retain(TextDelta.new(), 1, %{bold: true})
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "object attributes" do
      a = TextDelta.insert(TextDelta.new(), "A", %{
        font: %{family: "Helvetica", size: "15px"}})
      b = TextDelta.insert(TextDelta.new(), "A", %{
        font: %{family: "Helvetica", size: "15px"}})
      delta = TextDelta.new()
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "embed integer match" do
      a = TextDelta.insert(TextDelta.new(), 1)
      b = TextDelta.insert(TextDelta.new(), 1)
      delta = TextDelta.new()
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "embed integer mismatch" do
      a = TextDelta.insert(TextDelta.new(), 1)
      b = TextDelta.insert(TextDelta.new(), 2)
      delta =
        TextDelta.new()
        |> TextDelta.delete(1)
        |> TextDelta.insert(2)
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "embed object match" do
      a = TextDelta.insert(TextDelta.new(), %{image: "http://quilljs.com"})
      b = TextDelta.insert(TextDelta.new(), %{image: "http://quilljs.com"})
      delta = TextDelta.new()
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "embed object mismatch" do
      a = TextDelta.insert(TextDelta.new(), %{
        image: "http://quilljs.com" , alt: 'Overwrite'})
      b = TextDelta.insert(TextDelta.new(), %{
        image: "http://quilljs.com"})
      delta =
        TextDelta.new()
        |> TextDelta.insert(%{image: "http://quilljs.com"})
        |> TextDelta.delete(1)
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "embed false positive" do
      a = TextDelta.insert(TextDelta.new(), 1)
      b = TextDelta.insert(TextDelta.new(), List.to_string([0]))
      delta =
        TextDelta.new()
        |> TextDelta.insert(List.to_string([0]))
        |> TextDelta.delete(1)
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "inconvenient indexes" do
      a =
        TextDelta.new()
        |> TextDelta.insert("12", %{bold: true})
        |> TextDelta.insert("34", %{italic: true})
      b =
        TextDelta.new()
        |> TextDelta.insert("123", %{color: "red"})
      delta =
        TextDelta.new()
        |> TextDelta.retain(2, %{bold: nil, color: "red"})
        |> TextDelta.retain(1, %{italic: nil, color: "red"})
        |> TextDelta.delete(1)
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
    end

    test "combination" do
      a =
        TextDelta.new()
        |> TextDelta.insert("Bad", %{"color" => "red"})
        |> TextDelta.insert("cat", %{"color" => "blue"})
      b =
        TextDelta.new()
        |> TextDelta.insert("Good", %{"bold" => true})
        |> TextDelta.insert("dog", %{"italic" => true})
      delta =
        TextDelta.new()
        |> TextDelta.insert("Goo", %{"bold" => true})
        |> TextDelta.delete(2)
        |> TextDelta.retain(1, %{"bold" => true, "color" => nil})
        |> TextDelta.delete(3)
        |> TextDelta.insert("dog", %{"italic" => true})
      assert {:ok, result} = TextDelta.diff(a, b)
      assert result == delta
      assert TextDelta.apply!(a, delta) == b
    end

    test "same document" do
      a =
        TextDelta.new()
        |> TextDelta.insert("A")
        |> TextDelta.insert("B", %{"bold" => true})
      delta = TextDelta.new()
      assert {:ok, result} = TextDelta.diff(a, a)
      assert result == delta
    end
  end

  describe "diff!" do
    test "proper document" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("hi")
      assert TextDelta.diff!(delta, delta) == TextDelta.new()
    end

    test "retain delta" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(5)
      assert_raise RuntimeError, fn ->
        TextDelta.diff!(delta, delta)
      end
    end
  end
end
