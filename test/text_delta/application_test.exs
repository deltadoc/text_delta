defmodule TextDelta.ApplicationTest do
  use ExUnit.Case
  use EQC.ExUnit
  import TextDelta.Generators

  doctest TextDelta.Application

  property "document modifications always result in a proper document" do
    forall document <- document() do
      forall delta <- document_delta(document) do
        new_document = TextDelta.apply!(document, delta)
        ensure TextDelta.length(new_document) ==
          TextDelta.length(new_document, [:insert])
      end
    end
  end

  @document TextDelta.insert(TextDelta.new(), "test")

  describe "apply" do
    test "insert" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("hi")
      assert TextDelta.apply(@document, delta) ==
        {:ok, TextDelta.compose(@document, delta)}
    end

    test "insert outside document length" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("this is a ")
      assert TextDelta.apply(@document, delta) ==
        {:ok, TextDelta.compose(@document, delta)}
    end

    test "remove within document length" do
      delta =
        TextDelta.new()
        |> TextDelta.delete(3)
      assert TextDelta.apply(@document, delta) ==
        {:ok, TextDelta.compose(@document, delta)}
    end

    test "remove outside document length" do
      delta =
        TextDelta.new()
        |> TextDelta.delete(5)
      assert TextDelta.apply(@document, delta) == {:error, :length_mismatch}
    end

    test "retain within document length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(3)
      assert TextDelta.apply(@document, delta) ==
        {:ok, TextDelta.compose(@document, delta)}
    end

    test "retain outside document length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(5)
      assert TextDelta.apply(@document, delta) == {:error, :length_mismatch}
    end
  end

  describe "apply!" do
    test "insert" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("hi")
      assert TextDelta.apply!(@document, delta) ==
        TextDelta.compose(@document, delta)
    end

    test "retain outside document length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(5)
      assert_raise RuntimeError, fn ->
        TextDelta.apply!(@document, delta)
      end
    end
  end
end
