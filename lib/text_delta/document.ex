defmodule TextDelta.Document do
  @moduledoc """
  Document-related logic like splitting it into lines etc.
  """

  alias TextDelta.Operation

  @typedoc """
  Reason for an error.
  """
  @type error_reason :: :bad_document

  @typedoc """
  Line segments.

  Each line has a delta of the content on that line (minus `\n`) and a set of
  attributes applied to the entire block.
  """
  @type line_segments :: [{TextDelta.state(), TextDelta.Attributes.t()}]

  @typedoc """
  Result of getting document lines.

  An ok/error tuple. Represents either a successful retrieval in form of
  `{:ok, [line]}` or an error in form of `{:error, reason}`.
  """
  @type lines_result ::
          {:ok, line_segments}
          | {:error, error_reason}

  @doc """
  Breaks document into multiple line segments.

  Given document will be split according to newline characters (`\n`).

  ## Examples

  successful application:

      iex> doc =
      iex>  TextDelta.new()
      iex>  |> TextDelta.insert("hi\\nworld")
      iex>  |> TextDelta.insert("\\n", %{header: 1})
      iex> TextDelta.lines(doc)
      {:ok, [ {%TextDelta{ops: [%{insert: "hi"}]}, %{}},
              {%TextDelta{ops: [%{insert: "world"}]}, %{header: 1}} ]}

  error handling:

      iex> doc = TextDelta.retain(TextDelta.new(), 3)
      iex> TextDelta.lines(doc)
      {:error, :bad_document}
  """
  @spec lines(TextDelta.state()) :: lines_result
  def lines(doc) do
    case valid_document?(doc) do
      true -> {:ok, op_lines(TextDelta.operations(doc), TextDelta.new())}
      false -> {:error, :bad_document}
    end
  end

  @doc """
  Breaks document into multiple line segments.

  Equivalent to `&TextDelta.Document.lines/1`, but instead of returning
  ok/error tuples raises a `RuntimeError`.
  """
  @spec lines!(TextDelta.state()) :: line_segments | no_return
  def lines!(doc) do
    case lines(doc) do
      {:ok, lines} ->
        lines

      {:error, reason} ->
        raise "Can not get lines from document: #{Atom.to_string(reason)}"
    end
  end

  defp op_lines([%{insert: ins} = op | rest], delta) when ins == "\n" do
    [{delta, Map.get(op, :attributes, %{})} | op_lines(rest, TextDelta.new())]
  end

  defp op_lines([%{insert: ins} = op | rest], delta)
       when not is_bitstring(ins) do
    op_lines(rest, TextDelta.append(delta, op))
  end

  defp op_lines([%{insert: ins} = op | rest], delta) do
    op_from_split_string = fn
      "\n" -> Operation.insert("\n")
      othr -> Operation.insert(othr, Map.get(op, :attributes, %{}))
    end

    case String.split(ins, ~r/\n/, include_captures: true, trim: true) do
      [_] ->
        op_lines(rest, TextDelta.append(delta, op))

      mul ->
        mul
        |> Enum.map(op_from_split_string)
        |> Kernel.++(rest)
        |> op_lines(delta)
    end
  end

  defp op_lines([], delta) do
    case Kernel.length(TextDelta.operations(delta)) do
      0 -> []
      _ -> [{delta, %{}}]
    end
  end

  defp valid_document?(document) do
    TextDelta.length(document) == TextDelta.length(document, [:insert])
  end
end
