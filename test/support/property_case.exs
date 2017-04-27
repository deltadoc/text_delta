defmodule ExUnit.PropertyCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use EQC.ExUnit

      alias TextDelta.{Delta, Operation}

      defp document do
        let text <- text() do
          Delta.insert(Delta.new(), text)
        end
      end

      defp delta do
        let_shrink ops <- list(operation()) do
          Enum.reduce(ops, Delta.new(), &Delta.append(&2, &1))
        end
      end

      defp document_delta(doc) do
        such_that delta <- delta() do
          doc_len =
            doc
            |> Enum.map(&Operation.length/1)
            |> Enum.sum()
          delta_len =
            delta
            |> Enum.filter(fn op -> Operation.type(op) !== :insert end)
            |> Enum.map(&Operation.length/1)
            |> Enum.sum()
          doc_len >= delta_len
        end
      end

      defp priorities do
        oneof [{:left, :right}, {:right, :left}]
      end

      defp operation do
        oneof [
          Operation.insert(string()),
          Operation.insert(string(), attributes()),
          Operation.retain(choose(1, 50)),
          Operation.retain(choose(1, 50), attributes()),
          Operation.delete(choose(1, 50))
        ]
      end

      defp attributes do
        let attrs <- non_empty(list(attribute())) do
          Enum.into(attrs, %{})
        end
      end

      defp attribute do
        oneof [
          {string(), string()},
          {string(), bool()},
          {:font, string()},
          {:bold, bool()},
          {:italic, bool()}
        ]
      end

      defp text do
        let_shrink length <- choose(1, 500) do
          length
          |> :crypto.strong_rand_bytes()
          |> Base.url_encode64()
          |> String.slice(0, length)
        end
      end

      defp string do
        let_shrink length <- choose(1, 50) do
          length
          |> :crypto.strong_rand_bytes()
          |> Base.url_encode64()
          |> String.slice(0, length)
        end
      end
    end
  end
end
