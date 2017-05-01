defmodule TextDelta.Generators do
  use EQC.ExUnit

  alias TextDelta.{Delta, Operation}

  @max_text_length 500
  @max_operation_length 100

  def document do
    let text <- text() do
      Delta.insert(Delta.new(), text)
    end
  end

  def delta do
    let ops <- list(operation()) do
      Delta.new(ops)
    end
  end

  def document_delta(doc) do
    such_that delta <- delta() do
      Delta.length(doc) >= Delta.length(delta, [:retain, :delete])
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
      {oneof([string()]), oneof([string(), bool(), int()])},
      {oneof([:font, :style]), string()},
      {oneof([:bold, :italic]), bool()}
    ]
  end

  def text do
    let length <- text_length() do
      random_string(length)
    end
  end

  def string do
    let length <- operation_length() do
      random_string(length)
    end
  end

  def priority_side do
    oneof [:left, :right]
  end

  def text_length do
    choose(0, @max_text_length)
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
