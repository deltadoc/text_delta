defmodule TextDelta.Attributes do
  @moduledoc """
  Attributes represent format associated with `t:TextDelta.Operation.insert/0`
  or `t:TextDelta.Operation.retain/0` operations. This library uses maps to
  represent attributes.

  Same as `TextDelta.Delta`, attributes are composable and transformable. This
  library does not make any assumptions about attribute types, values or
  composition.
  """

  @typedoc """
  A set of attributes applicable to an operation.
  """
  @type t :: map

  @typedoc """
  Atom representing transformation priority. Should we prioritise left or right
  side?
  """
  @type priority :: :left | :right

  @doc """
  Composes two sets of attributes into one.

  Simplest way to think about composing arguments is two maps being merged (in
  fact, that's exactly how it is implemented at the moment).

  The only thing that makes it different from standard map merge is an optional
  `keep_nils` flag. This flag controls if we want to cleanup all the `null`
  attributes before returning.

  This function is used by `TextDelta.Delta.compose/2`.

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
    Map.merge(attrs_a, attrs_b)
  end

  def compose(attrs_a, attrs_b, false) do
    attrs_a
    |> Map.merge(attrs_b)
    |> remove_nils()
  end

  @doc """
  Transforms given attribute set against another.

  This function is used by `TextDelta.Delta.transform/3`.

  ## Example

      iex> TextDelta.Attributes.transform(%{italic: true},
      iex>                                %{bold: true}, :left)
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
    remove_duplicates(attrs_b, attrs_a)
  end

  defp remove_nils(result) do
    result
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Enum.into(%{})
  end

  defp remove_duplicates(attrs_a, attrs_b) do
    attrs_a
    |> Enum.filter(fn {key, _} -> not Map.has_key?(attrs_b, key) end)
    |> Enum.into(%{})
  end
end
