defmodule TextDelta.Generators do
  use EQC.ExUnit

  alias TextDelta.Operation

  @max_operation_length 100
  @max_string_length 100
  @max_text_length 500

  def document do
    let text <- text() do
      TextDelta.insert(TextDelta.new(), text)
    end
  end

  def delta do
    let ops <- list(operation()) do
      TextDelta.new(ops)
    end
  end

  def document_delta(doc) do
    such_that delta <- delta() do
      TextDelta.length(doc) >= TextDelta.length(delta, [:retain, :delete])
    end
  end

  def operation do
    oneof [insert(), retain(), delete()]
  end

  def insert do
    let [el <- element(), attrs <- attributes()] do
      Operation.insert(el, attrs)
    end
  end

  def bitstring_insert do
    let [str <- string(), attrs <- attributes()] do
      Operation.insert(str, attrs)
    end
  end

  def retain do
    let [len <- operation_length(), attrs <- attributes()] do
      Operation.retain(len, attrs)
    end
  end

  def delete do
    let len <- operation_length() do
      Operation.delete(len)
    end
  end

  def element do
    oneof [string(), int(), map(string(), string())]
  end

  def attributes do
    let attrs <- list(attribute()) do
      Map.new(attrs)
    end
  end

  def attribute do
    oneof [
      {oneof([non_empty_string()]), oneof([non_empty_string(), bool(), int()])},
      {oneof([:font, :style]), non_empty_string()},
      {oneof([:bold, :italic]), bool()}
    ]
  end

  def text do
    let length <- text_length() do
      random_string(length)
    end
  end

  def string do
    let length <- string_length() do
      random_string(length)
    end
  end

  def non_empty_string do
    non_empty(string())
  end

  def priority_side do
    oneof [:left, :right]
  end

  def text_length do
    choose(0, @max_text_length)
  end

  def string_length do
    choose(0, @max_string_length)
  end

  def operation_length do
    choose(0, @max_operation_length)
  end

  def opposite(:left), do: :right
  def opposite(:right), do: :left

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> String.slice(0, length)
  end
end
