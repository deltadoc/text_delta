# All modules here are only for bacwards compatibility and will be removed in
# next major bump - 2.0. Please upgrade to the new public API ASAP.

defmodule TextDelta.Delta do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.Delta.{Transformation, Composition}

  @doc false
  def new(ops \\ []) do
    ops
    |> TextDelta.new()
    |> unwrap()
  end

  @doc false
  def insert(delta, el, attrs \\ %{}) do
    delta
    |> wrap()
    |> TextDelta.insert(el, attrs)
    |> unwrap()
  end

  @doc false
  def retain(delta, len, attrs \\ %{}) do
    delta
    |> wrap()
    |> TextDelta.retain(len, attrs)
    |> unwrap()
  end

  @doc false
  def delete(delta, len) do
    delta
    |> wrap()
    |> TextDelta.delete(len)
    |> unwrap()
  end

  @doc false
  def append(nil, op), do: append(new(), op)
  def append(delta, op) do
    delta
    |> wrap()
    |> TextDelta.append(op)
    |> unwrap()
  end

  defdelegate compose(delta_a, delta_b), to: Composition
  defdelegate transform(delta_a, delta_b, priority), to: Transformation

  @doc false
  def trim(delta) do
    delta
    |> wrap()
    |> TextDelta.trim()
    |> unwrap()
  end

  @doc false
  def length(delta, included_ops \\ [:insert, :retain, :delete]) do
    delta
    |> wrap()
    |> TextDelta.length(included_ops)
  end

  @doc false
  def wrap(ops), do: TextDelta.new(ops)

  @doc false
  def unwrap(delta), do: TextDelta.operations(delta)
end

defmodule TextDelta.Delta.Composition do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.Delta

  @doc false
  def compose(delta_a, delta_b) do
    delta_a
    |> Delta.wrap()
    |> TextDelta.compose(Delta.wrap(delta_b))
    |> Delta.unwrap()
  end
end

defmodule TextDelta.Delta.Transformation do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  alias TextDelta.Delta

  @doc false
  def transform(delta_a, delta_b, priority) do
    delta_a
    |> Delta.wrap()
    |> TextDelta.transform(Delta.wrap(delta_b), priority)
    |> Delta.unwrap()
  end
end

defmodule TextDelta.Delta.Iterator do
  # Deprecated and to be removed in 2.0
  @moduledoc false

  defdelegate next(deltas, skip_type \\ nil), to: TextDelta.Iterator
end
