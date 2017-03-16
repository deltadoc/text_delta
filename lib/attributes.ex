defmodule TextDelta.Attributes do
  @moduledoc """
  Attributes represent format associated with an insert or retain operations. To simplify things,
  this library uses simple maps to represent attributes.

  Same as deltas themselves, attributes are composable, diffable and transformable. This library
  does not make any assumptions about attribute types, values or composition, so no validation of
  that kind is provided.
  """

  @typedoc """
  A set of attributes applicable to an operation.
  """
  @type t :: map

  @typedoc """
  Atom representing transformation priority. Should we prioritise left or right side?
  """
  @type priority :: :left | :right

  @doc """
  Composes two sets of attributes into one.

  Simplest way to think about composing arguments is two maps being merged (in fact, that's exactly
  how it is implemented).

  The only thing that makes it different from standard map merge is a `keep_nils` flag - this flag
  controls if we want to cleanup all the `null` attributes before returning.

  This function is useful when composing, transforming or diffing deltas.

  ## Examples

    iex> TextDelta.Attributes.compose(%{color: "blue"}, %{italic: true})
    %{color: "blue", italic: true}

    iex> TextDelta.Attributes.compose(%{bold: true}, %{bold: nil}, true)
    %{bold: nil}

    iex> TextDelta.Attributes.compose(%{bold: true}, %{bold: nil}, false)
    %{}
  """
  @spec compose(t, t, boolean) :: t
  def compose(attrs_a, attrs_b, keep_nils \\ false)

  def compose(nil, attrs_b, keep_nils) do
    compose(%{}, attrs_b, keep_nils)
  end

  def compose(attrs_a, nil, keep_nils) do
    compose(attrs_a, %{}, keep_nils)
  end

  def compose(attrs_a, attrs_b, true) do
    attrs_a |> Map.merge(attrs_b)
  end

  def compose(attrs_a, attrs_b, false) do
    attrs_a
    |> Map.merge(attrs_b)
    |> remove_nils()
  end

  @doc """
  Calculates and returns difference between two sets of attributes.

  Given an initial set of attributes and the final one, this function will generate an attribute
  set that is when composed with original one would yield the final result.

  ## Examples

    iex> TextDelta.Attributes.diff(%{font: "arial", color: "blue"}, %{color: "red"})
    %{font: nil, color: "red"}
  """
  @spec diff(t, t) :: t
  def diff(attrs_a, attrs_b)

  def diff(nil, attrs_b), do: diff(%{}, attrs_b)
  def diff(attrs_a, nil), do: diff(attrs_a, %{})

  def diff(attrs_a, attrs_b) do
    %{}
    |> add_changes(attrs_a, attrs_b)
    |> add_deletions(attrs_a, attrs_b)
  end

  @doc """
  Transform given attribute set against another.

  ## Examples

    iex> TextDelta.Attributes.transform(%{italic: true}, %{bold: true}, :left)
    %{bold: true}
  """
  @spec transform(t, t, priority) :: t
  def transform(attrs_a, attrs_b, priority)

  def transform(nil, attrs_b, priority) do
    transform(%{}, attrs_b, priority)
  end

  def transform(attrs_a, nil, priority) do
    transform(attrs_a, %{}, priority)
  end

  def transform(_, attrs_b, :right) do
    attrs_b
  end

  def transform(attrs_a, attrs_b, :left) do
    attrs_b |> remove_duplicates(attrs_a)
  end

  defp remove_nils(result) do
    result
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Enum.into(%{})
  end

  defp add_changes(result, from, to) do
    to
    |> Enum.filter(fn {key, val} -> Map.get(from, key) != val end)
    |> Enum.into(%{})
    |> Map.merge(result)
  end

  defp add_deletions(result, from, to) do
    from
    |> Enum.filter_map(
         fn {key, _} -> not Map.has_key?(to, key) end,
         fn {key, _} -> {key, nil} end)
    |> Enum.into(%{})
    |> Map.merge(result)
  end

  defp remove_duplicates(a, b) do
    a
    |> Enum.filter(fn {key, _} -> not Map.has_key?(b, key) end)
    |> Enum.into(%{})
  end
end
