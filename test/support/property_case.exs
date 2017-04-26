defmodule ExUnit.PropertyCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use EQC.ExUnit

      alias TextDelta.{Delta, Operation}

      defp document do
        Delta.insert(Delta.new(), text())
      end

      defp priorities do
        oneof [{:left, :right}, {:right, :left}]
      end

      defp operations do
        list(operation())
      end

      defp operation do
        oneof [
          Operation.insert(string()),
          Operation.insert(string(), attributes()),
          Operation.retain(short_length()),
          Operation.retain(short_length(), attributes()),
          Operation.delete(short_length())
        ]
      end

      defp text(options \\ 5) do
        texts =
          1..200
          |> Enum.take_random(options)
          |> Enum.map(&random_string/1)
        oneof texts
      end

      defp string(options \\ 10) do
        texts =
          1..50
          |> Enum.take_random(options)
          |> Enum.map(&random_string/1)
        oneof texts
      end

      defp attributes do
        oneof [
          %{string() => oneof([string(), bool()])},
          %{bold: bool()},
          %{italic: bool()},
          %{bold: bool(), italic: bool()},
        ]
      end

      defp short_length do
        choose(1, 50)
      end

      defp random_string(length) do
        length
        |> :crypto.strong_rand_bytes()
        |> Base.url_encode64()
        |> String.slice(0, length)
      end

      defp delta_from_operations(ops) do
        Enum.reduce(ops, Delta.new(), &Delta.append(&2, &1))
      end

      defp doc_len(doc) do
        doc
        |> Enum.map(&Operation.length/1)
        |> Enum.sum()
      end

      defp delta_len(doc) do
        doc
        |> Enum.filter(fn op -> Operation.type(op) !== :insert end)
        |> Enum.map(&Operation.length/1)
        |> Enum.sum()
      end
    end
  end
end
