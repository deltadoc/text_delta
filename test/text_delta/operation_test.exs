defmodule TextDelta.OperationTest do
  use ExUnit.Case
  alias TextDelta.Operation

  doctest TextDelta.Operation

  describe "insert" do
    test "text" do
      assert Operation.insert("test") == %{insert: "test"}
    end

    test "text with attributes" do
      assert Operation.insert("test", %{italic: true, font: "serif"}) == %{
        insert: "test",
        attributes: %{italic: true, font: "serif"}
      }
    end

    test "embed" do
      assert Operation.insert(2) == %{insert: 2}
    end

    test "embed as a map" do
      assert Operation.insert(%{img: "me.png"}) == %{insert: %{img: "me.png"}}
    end

    test "embed as a map with attributes" do
      assert Operation.insert(%{img: "me.png"}, %{alt: "My photo"}) == %{
        insert: %{img: "me.png"},
        attributes: %{alt: "My photo"}
      }
    end

    test "with empty attributes" do
      assert Operation.insert("test", %{}) == %{insert: "test"}
    end

    test "with nil attributes" do
      assert Operation.insert("test", nil) == %{insert: "test"}
    end
  end

  describe "retain" do
    test "length" do
      assert Operation.retain(3) == %{retain: 3}
    end

    test "length with attributes" do
      assert Operation.retain(3, %{italic: true}) == %{retain: 3, attributes: %{italic: true}}
    end

    test "length with empty attributes" do
      assert Operation.retain(3, %{}) == %{retain: 3}
    end

    test "length with nil attributes" do
      assert Operation.retain(3, nil) == %{retain: 3}
    end
  end

  describe "delete" do
    test "length" do
      assert Operation.delete(5) == %{delete: 5}
    end
  end

  describe "type" do
    test "of insert" do
      assert Operation.type(%{insert: "test"}) == :insert
    end

    test "of insert with attributes" do
      assert Operation.type(%{insert: "test", attributes: %{bold: true}}) == :insert
    end

    test "of retain" do
      assert Operation.type(%{retain: 4}) == :retain
    end

    test "of retain with attributes" do
      assert Operation.type(%{retain: 4, attributes: %{italic: true}}) == :retain
    end

    test "of delete" do
      assert Operation.type(%{delete: 10}) == :delete
    end
  end

  describe "length" do
    test "of insert" do
      assert Operation.length(%{insert: "test"}) == 4
    end

    test "of insert with attributes" do
      assert Operation.length(%{insert: "test", attributes: %{bold: true}}) == 4
    end

    test "of numerical embed insert with attributes" do
      assert Operation.length(%{insert: 5, attributes: %{bold: true}}) == 1
    end

    test "of map embed insert with attributes" do
      assert Operation.length(%{insert: %{tweet: "4412"}, attributes: %{bold: true}}) == 1
    end

    test "of retain" do
      assert Operation.length(%{retain: 5}) == 5
    end

    test "of retain with attributes" do
      assert Operation.length(%{retain: 5, attributes: %{italic: true}}) == 5
    end

    test "of delete" do
      assert Operation.length(%{delete: 10}) == 10
    end
  end

  describe "compare" do
    test "greater insert with delete" do
      assert Operation.compare(%{insert: "test", attributes: %{italic: true}}, %{delete: 2}) == :gt
    end

    test "lesser retain with insert" do
      assert Operation.compare(%{retain: 2, attributes: %{italic: true}}, %{insert: "tes"}) == :lt
    end

    test "equal delete and retain" do
      assert Operation.compare(%{delete: 3}, %{retain: 3, attributes: %{bold: true}}) == :eq
    end
  end

  describe "slice" do
    test "insert" do
      assert Operation.slice(%{insert: "hello"}, 3) == {%{insert: "hel"}, %{insert: "lo"}}
    end

    test "insert with attributes" do
      assert Operation.slice(%{insert: "hello", attributes: %{bold: true}}, 3) == {
        %{insert: "hel", attributes: %{bold: true}},
        %{insert: "lo", attributes: %{bold: true}}
      }
    end

    test "insert of numeric embed" do
      assert Operation.slice(%{insert: 1}, 3) == {%{insert: 1}, %{insert: ""}}
    end

    test "insert of map embed" do
      assert Operation.slice(%{insert: %{img: "me.png"}}, 3) == {
        %{insert: %{img: "me.png"}},
        %{insert: ""}
      }
    end

    test "retain" do
      assert Operation.slice(%{retain: 5}, 3) == {%{retain: 3}, %{retain: 2}}
    end

    test "retain with attributes" do
      assert Operation.slice(%{retain: 5, attributes: %{italic: true}}, 3) == {
        %{retain: 3, attributes: %{italic: true}},
        %{retain: 2, attributes: %{italic: true}}
      }
    end

    test "delete" do
      assert Operation.slice(%{delete: 5}, 3) == {%{delete: 3}, %{delete: 2}}
    end
  end

  describe "compact" do
    test "inserts" do
      assert Operation.compact(%{insert: "hel"}, %{insert: "lo"}) == [%{insert: "hello"}]
    end

    test "inserts with attributes" do
      assert Operation.compact(
        %{insert: "hel", attributes: %{bold: true}},
        %{insert: "lo", attributes: %{bold: true}}
      ) == [%{insert: "hello", attributes: %{bold: true}}]
    end

    test "inserts of numeric embeds" do
      assert Operation.compact(%{insert: 1}, %{insert: 1}) == [%{insert: 1}, %{insert: 1}]
    end

    test "inserts of map embeds" do
      assert Operation.compact(%{insert: %{img: "me.png"}}, %{insert: %{img: "me.png"}}) == [
        %{insert: %{img: "me.png"}},
        %{insert: %{img: "me.png"}}
      ]
    end

    test "retains" do
      assert Operation.compact(%{retain: 3}, %{retain: 2}) == [%{retain: 5}]
    end

    test "retains with attributes" do
      assert Operation.compact(
        %{retain: 3, attributes: %{italic: true}},
        %{retain: 2, attributes: %{italic: true}}
      ) == [%{retain: 5, attributes: %{italic: true}}]
    end

    test "deletes" do
      assert Operation.compact(%{delete: 3}, %{delete: 2}) == [%{delete: 5}]
    end
  end

  describe "trimmable?" do
    test "insert" do
      refute Operation.trimmable?(%{insert: "test"})
    end

    test "delete" do
      refute Operation.trimmable?(%{delete: 5})
    end

    test "retain" do
      assert Operation.trimmable?(%{retain: 5})
    end
  end
end
