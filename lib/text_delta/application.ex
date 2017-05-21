defmodule TextDelta.Application do
  @moduledoc """
  The application of a delta onto a text state.

  Text state is always represented as a set of `t:TextDelta.Operation.insert/0`
  operations. This means that any application should always result in a set of
  `insert` operations or produce an error tuple.

  In simpler terms this means that it is not possible to apply delta, which
  combined length of `retain` and `delete` operations is longer than the length
  of original text. This situation will always result in `:length_mismatch`
  error.
  """

  @typedoc """
  Reason for an application error.
  """
  @type error_reason :: :length_mismatch

  @typedoc """
  Result of an application.

  An ok/error tuple. Represents either a successful application in form of
  `{:ok, new_state}` or an error in form of `{:error, reason}`.
  """
  @type result :: {:ok, TextDelta.state}
                | {:error, error_reason}

  @doc """
  Applies given delta to a particular text state, resulting in a new state.

  Text state is a set of `t:TextDelta.Operation.insert/0` operations. If
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
  @spec apply(TextDelta.state, TextDelta.t) :: result
  def apply(state, delta) do
    case delta_within_text_length?(delta, state) do
      true ->
        {:ok, TextDelta.compose(state, delta)}
      false ->
        {:error, :length_mismatch}
    end
  end

  @doc """
  Applies given delta to a particular text state, resulting in a new state.

  Equivalent to `&TextDelta.Application.apply/2`, but instead of returning
  ok/error tuples returns a new state or raises a `RuntimeError`.
  """
  @spec apply!(TextDelta.state, TextDelta.t) :: TextDelta.state | no_return
  def apply!(state, delta) do
    case __MODULE__.apply(state, delta) do
      {:ok, new_state} ->
        new_state
      {:error, reason} ->
        raise "Can not apply delta to state: #{Atom.to_string(reason)}"
    end
  end

  defp delta_within_text_length?(delta, state) do
    TextDelta.length(state) >= TextDelta.length(delta, [:retain, :delete])
  end
end
