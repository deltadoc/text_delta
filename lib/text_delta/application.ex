defmodule TextDelta.Application do
  @moduledoc """
  Application provides ability to apply given text `t:TextDelta.t/0` to the
  `t:TextDelta.document/0`.

  Text document is always represented as a set of
  `t:TextDelta.Operation.insert/0` operations. This means that any application
  should always result in a set of `insert` operations or produce an error
  tuple.

  In simpler terms this means that it is not possible to apply delta, which
  combined length of `retain` and `delete` operations is longer than the length
  of original document. This situation will always result in `:length_mismatch`.
  """

  @typedoc """
  Atom representing reason for error.
  """
  @type error_reason :: atom

  @typedoc """
  Result of an application.

  An ok/error tuple. Represents either a successful application in form of
  `{:ok, new_document}` or an error in form of `{:error, reason}`.
  """
  @type result :: {:ok, TextDelta.document}
                | {:error, error_reason}

  @doc """
  Applies given delta to a particular document, resulting in a new document.

  Document is a set of `t:TextDelta.Operation.insert/0` operations. If
  applying delta results in anything but a set of `insert` operations, `:error`
  tuple is returned instead.

  ## Examples

  successful application:

      iex> doc = TextDelta.insert(TextDelta.new(), "hi")
      %TextDelta{ops: [%{insert: "hi"}]}
      iex> TextDelta.apply(doc, TextDelta.insert(TextDelta.new(), "oh, "))
      {:ok, %TextDelta{ops: [%{insert: "oh, hi"}]}}

  error handling:

      iex> doc = TextDelta.insert(TextDelta.new(), "hi")
      %TextDelta{ops: [%{insert: "hi"}]}
      iex> TextDelta.apply(doc, TextDelta.delete(TextDelta.new(), 5))
      {:error, :length_mismatch}
  """
  @spec apply(TextDelta.document, TextDelta.t) :: result
  def apply(document, delta) do
    case delta_within_document_length?(delta, document) do
      true ->
        {:ok, TextDelta.compose(document, delta)}
      false ->
        {:error, :length_mismatch}
    end
  end

  @doc """
  Applies given delta to a particular document, resulting in a new document.

  Equivalent to `&TextDelta.Application.apply/2`, but instead of returning
  ok/error tuples returns a new document or raises a `RuntimeError`.
  """
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
