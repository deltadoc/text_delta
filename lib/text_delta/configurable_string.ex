defmodule TextDelta.ConfigurableString do
  @moduledoc """
  String configurable to support unicode or not.
  """

  @support_unicode Application.get_env(:text_delta, :support_unicode, true)

  @doc "Calculates the length of a given string"
  @spec length(String.t()) :: non_neg_integer
  def length(str) do
    if @support_unicode do
      String.length(str)
    else
      byte_size(str)
    end
  end

  @doc "Splits given string at the index"
  @spec split_at(String.t(), non_neg_integer) :: {String.t(), String.t()}
  def split_at(str, idx) do
    if @support_unicode do
      String.split_at(str, idx)
    else
      {binary_part(str, 0, idx), binary_part(str, idx, byte_size(str) - idx)}
    end
  end
end
