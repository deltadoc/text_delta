defmodule TextDelta.Difference do
  @moduledoc """
  Document diffing.

  Given valid document states A and B, generate a delta that when applied to A
  will result in B.
  """

  alias TextDelta.{Operation, Attributes}

  @typedoc """
  Reason for an error.
  """
  @type error_reason :: :bad_document

  @typedoc """
  Result of getting a diff.

  An ok/error tuple. Represents either a successful diffing in form of
  `{:ok, delta}` or an error in form of `{:error, reason}`.
  """
  @type result :: {:ok, TextDelta.t}
                | {:error, error_reason}

  @doc """
  Calculates a difference between two documents in form of new delta.

  ## Examples

  successful application:

      iex> doc_a =
      iex>  TextDelta.new()
      iex>  |> TextDelta.insert("hello")
      iex> doc_b =
      iex>  TextDelta.new()
      iex>  |> TextDelta.insert("goodbye")
      iex> TextDelta.diff(doc_a, doc_b)
      {:ok, %TextDelta{ops: [
        %{insert: "g"},
        %{delete: 4},
        %{retain: 1},
        %{insert: "odbye"}]}}

  error handling:

      iex> doc = TextDelta.retain(TextDelta.new(), 3)
      iex> TextDelta.diff(doc, doc)
      {:error, :bad_document}
  """
  @spec diff(TextDelta.state, TextDelta.state) :: result
  def diff(first, second) do
    case valid_document?(first) and valid_document?(second) do
      true ->
        fst_ops = TextDelta.operations(first)
        snd_ops = TextDelta.operations(second)
        result =
          fst_ops
          |> string_from_ops()
          |> String.myers_difference(string_from_ops(snd_ops))
          |> mdiff_to_delta(fst_ops, snd_ops, TextDelta.new())
          |> TextDelta.trim()
        {:ok, result}
      false ->
        {:error, :bad_document}
    end
  end

  @doc """
  Calculates a difference between two documents in form of new delta.

  Equivalent to `&TextDelta.Difference.diff/2`, but instead of returning
  ok/error tuples raises a `RuntimeError`.
  """
  @spec diff!(TextDelta.state, TextDelta.state) :: TextDelta.t | no_return
  def diff!(first, second) do
    case diff(first, second) do
      {:ok, delta} -> delta
      {:error, reason} ->
        raise "Can not diff documents: #{Atom.to_string(reason)}"
    end
  end

  defp string_from_ops(ops) do
    ops
    |> Enum.map(&string_from_op/1)
    |> Enum.join()
  end

  defp string_from_op(%{insert: str}) when is_bitstring(str), do: str
  defp string_from_op(%{insert: _}), do: List.to_string([0])

  defp mdiff_to_delta([], _, _, delta), do: delta
  defp mdiff_to_delta([{_, ""} | rest], fst, snd, delta) do
    mdiff_to_delta(rest, fst, snd, delta)
  end
  defp mdiff_to_delta([{type, str} | rest], fst, snd, delta) do
    str_len = String.length(str)
    case type do
      :ins ->
        {op, new_snd} = next_op_no_longer_than(snd, str_len)
        op_len = Operation.length(op)
        {_, substr} = String.split_at(str, op_len)
        new_delta = TextDelta.append(delta, op)
        mdiff_to_delta([{:ins, substr} | rest], fst, new_snd, new_delta)
      :del ->
        {op, new_fst} = next_op_no_longer_than(fst, str_len)
        op_len = Operation.length(op)
        {_, substr} = String.split_at(str, op_len)
        new_delta = TextDelta.append(delta, Operation.delete(op_len))
        mdiff_to_delta([{:del, substr} | rest], new_fst, snd, new_delta)
      :eq ->
        {{op1, new_fst}, {op2, new_snd}} =
          next_op_no_longer_than(fst, snd, str_len)
        op_len = Operation.length(op1)
        {_, substr} = String.split_at(str, op_len)
        if op1.insert == op2.insert do
          attrs =
            op1
            |> Map.get(:attributes, %{})
            |> Attributes.diff(Map.get(op2, :attributes, %{}))
          new_delta = TextDelta.retain(delta, op_len, attrs)
          mdiff_to_delta([{:eq, substr} | rest], new_fst, new_snd, new_delta)
        else
          new_delta =
            delta
            |> TextDelta.append(op2)
            |> TextDelta.append(Operation.delete(op_len))
          mdiff_to_delta([{:eq, substr} | rest], new_fst, new_snd, new_delta)
        end
    end
  end

  defp next_op_no_longer_than([op | rest], max_len) do
    op_len = Operation.length(op)
    if op_len <= max_len do
      {op, rest}
    else
      {op1, op2} = Operation.slice(op, max_len)
      {op1, [op2 | rest]}
    end
  end

  defp next_op_no_longer_than([op1 | rest1], [op2 | rest2], max_len) do
    len = Enum.min([Operation.length(op1), Operation.length(op2), max_len])
    {next_op_no_longer_than([op1 | rest1], len),
     next_op_no_longer_than([op2 | rest2], len)}
  end

  defp valid_document?(document) do
    TextDelta.length(document) == TextDelta.length(document, [:insert])
  end
end
