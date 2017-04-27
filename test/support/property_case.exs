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

      defp operation do
        oneof [insert(), retain(), delete()]
      end

      defp insert do
        let [str <- string(), attrs <- attributes()] do
          Operation.insert(str, attrs)
        end
      end

      defp retain do
        let [len <- choose(1, 50), attrs <- attributes()] do
          Operation.retain(len, attrs)
        end
      end

      defp delete do
        let len <- choose(1, 50) do
          Operation.delete(len)
        end
      end

      defp attributes do
        let attrs <- list(attribute()) do
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
