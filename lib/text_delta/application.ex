defmodule TextDelta.Application do
  @moduledoc """
  """

  @type error_reason :: atom

  @type result :: {:ok, TextDelta.document}
                | {:error, error_reason}

  @spec apply(TextDelta.document, TextDelta.t) :: result
  def apply(document, delta) do
    case delta_within_document_length?(delta, document) do
      true ->
        {:ok, TextDelta.compose(document, delta)}
      false ->
        {:error, :length_mismatch}
    end
  end

  @spec apply!(TextDelta.document, TextDelta.t) :: TextDelta.document
  def apply!(document, delta) do
    case __MODULE__.apply(document, delta) do
      {:ok, new_state} ->
        new_state
      {:error, reason} ->
        raise "Can not apply delta to document: #{Atom.to_string(reason)}"
    end
  end

  defp delta_within_document_length?(delta, document) do
    TextDelta.length(document) >= TextDelta.length(delta, [:retain, :delete])
  end
end
