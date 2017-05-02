defmodule TextDelta.Attributes do
  @moduledoc """
  Attributes represent format associated with `t:TextDelta.Operation.insert/0`
  or `t:TextDelta.Operation.retain/0` operations. This library uses maps to
  represent attributes.

  Same as `TextDelta`, attributes are composable and transformable. This library
  does not make any assumptions about attribute types, values or composition.
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

  This function is used by `TextDelta.compose/2`.

  ## Examples

      iex> TextDelta.Attributes.compose(%{color: "blue"}, %{italic: true})
      %{color: "blue", italic: true}

      iex> TextDelta.Attributes.compose(%{bold: true}, %{bold: nil}, true)
      %{bold: nil}

      iex> TextDelta.Attributes.compose(%{bold: true}, %{bold: nil}, false)
      %{}
  """
  @spec compose(t, t, boolean) :: t
  def compose(first, second, keep_nils \\ false)

  def compose(nil, second, keep_nils) do
    compose(%{}, second, keep_nils)
  end

  def compose(first, nil, keep_nils) do
    compose(first, %{}, keep_nils)
  end

  def compose(first, second, true) do
    Map.merge(first, second)
  end

  def compose(first, second, false) do
    first
    |> Map.merge(second)
    |> remove_nils()
  end

  @doc """
  Transforms `right` attribute set against the `left` one.

  The function also takes a third `t:TextDelta.Attributes.priority/0`
  argument that indicates which set came first.

  This function is used by `TextDelta.transform/3`.

  ## Example

      iex> TextDelta.Attributes.transform(%{italic: true},
      iex>                                %{bold: true}, :left)
      %{bold: true}
  """
  @spec transform(t, t, priority) :: t
  def transform(left, right, priority)

  def transform(nil, right, priority) do
    transform(%{}, right, priority)
  end

  def transform(left, nil, priority) do
    transform(left, %{}, priority)
  end

  def transform(_, right, :right) do
    right
  end

  def transform(left, right, :left) do
    remove_duplicates(right, left)
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
