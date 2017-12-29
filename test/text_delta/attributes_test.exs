defmodule TextDelta.AttributesTest do
  use ExUnit.Case
  alias TextDelta.Attributes

  doctest TextDelta.Attributes

  describe "compose" do
    @attributes %{bold: true, color: "red"}

    test "from nothing" do
      assert Attributes.compose(%{}, @attributes) == @attributes
    end

    test "to nothing" do
      assert Attributes.compose(@attributes, %{}) == @attributes
    end

    test "nothing with nothing" do
      assert Attributes.compose(%{}, %{}) == %{}
    end

    test "with new attribute" do
      assert Attributes.compose(@attributes, %{italic: true}) == %{
        bold: true,
        italic: true,
        color: "red"
      }
    end

    test "with overwriten attribute" do
      assert Attributes.compose(@attributes, %{bold: false, color: "blue"}) == %{
        bold: false,
        color: "blue"
      }
    end

    test "with attribute removed" do
      assert Attributes.compose(@attributes, %{bold: nil}) == %{color: "red"}
    end

    test "with all attributes removed" do
      assert Attributes.compose(@attributes, %{bold: nil, color: nil}) == %{}
    end

    test "with removal of inexistent element" do
      assert Attributes.compose(@attributes, %{italic: nil}) == @attributes
    end

    test "string-keyed attributes" do
      attrs_a = %{"bold" => true, "color" => "red"}
      attrs_b = %{"italic" => true, "color" => "blue"}
      composed = %{"bold" => true, "color" => "blue", "italic" => true}
      assert Attributes.compose(attrs_a, attrs_b) == composed
    end
  end

  describe "transform" do
    @lft %{bold: true, color: "red", font: nil}
    @rgt %{color: "blue", font: "serif", italic: true}

    test "from nothing" do
      assert Attributes.transform(%{}, @rgt, :right) == @rgt
    end

    test "to nothing" do
      assert Attributes.transform(@lft, %{}, :right) == %{}
    end

    test "nothing to nothing" do
      assert Attributes.transform(%{}, %{}, :right) == %{}
    end

    test "left to right with priority" do
      assert Attributes.transform(@lft, @rgt, :left) == %{italic: true}
    end

    test "left to right without priority" do
      assert Attributes.transform(@lft, @rgt, :right) == @rgt
    end

    test "string-keyed attributes" do
      attrs_a = %{"bold" => true, "color" => "red", "font" => nil}
      attrs_b = %{"color" => "blue", "font" => "serif", "italic" => true}
      assert Attributes.transform(attrs_a, attrs_b, :left) == %{"italic" => true}
      assert Attributes.transform(attrs_a, attrs_b, :right) == attrs_b
    end
  end

  describe "diff" do
    @attributes %{bold: true, color: "red"}

    test "nothing with attributes" do
      assert Attributes.diff(%{}, @attributes) == @attributes
    end

    test "attributes with nothing" do
      assert Attributes.diff(@attributes, %{}) == %{bold: nil, color: nil}
    end

    test "same attributes" do
      assert Attributes.diff(@attributes, @attributes) == %{}
    end

    test "with added attribute" do
      assert Attributes.diff(@attributes, %{bold: true, color: "red", italic: true}) == %{italic: true}
    end

    test "with removed attribute" do
      assert Attributes.diff(@attributes, %{bold: true}) == %{color: nil}
    end

    test "with overwriten attribute" do
      assert Attributes.diff(@attributes, %{bold: true, color: "blue"}) == %{color: "blue"}
    end
  end
end
