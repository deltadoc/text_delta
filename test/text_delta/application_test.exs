defmodule TextDelta.ApplicationTest do
  use ExUnit.Case
  use EQC.ExUnit
  import TextDelta.Generators

  doctest TextDelta.Application

  property "state modifications always result in a valid document state" do
    forall document <- document() do
      forall delta <- document_delta(document) do
        new_document = TextDelta.apply!(document, delta)
        ensure TextDelta.length(new_document) ==
          TextDelta.length(new_document, [:insert])
      end
    end
  end

  @state TextDelta.insert(TextDelta.new(), "test")

  describe "apply" do
    test "insert delta" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("hi")
      assert TextDelta.apply(@state, delta) ==
        {:ok, TextDelta.compose(@state, delta)}
    end

    test "insert delta outside original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("this is a ")
      assert TextDelta.apply(@state, delta) ==
        {:ok, TextDelta.compose(@state, delta)}
    end

    test "remove delta within original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.delete(3)
      assert TextDelta.apply(@state, delta) ==
        {:ok, TextDelta.compose(@state, delta)}
    end

    test "remove delta outside original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.delete(5)
      assert TextDelta.apply(@state, delta) == {:error, :length_mismatch}
    end

    test "retain delta within original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(3)
      assert TextDelta.apply(@state, delta) ==
        {:ok, TextDelta.compose(@state, delta)}
    end

    test "retain delta outside original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(5)
      assert TextDelta.apply(@state, delta) == {:error, :length_mismatch}
    end
  end

  describe "apply!" do
    test "insert delta" do
      delta =
        TextDelta.new()
        |> TextDelta.insert("hi")
      assert TextDelta.apply!(@state, delta) ==
        TextDelta.compose(@state, delta)
    end

    test "retain delta outside original text length" do
      delta =
        TextDelta.new()
        |> TextDelta.retain(5)
      assert_raise RuntimeError, fn ->
        TextDelta.apply!(@state, delta)
      end
    end
  end
end
