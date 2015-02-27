defmodule Phoenix.HTML do
  @moduledoc """
  Conveniences for working HTML strings and templates.

  When used, it brings the given functionality:

    * `Phoenix.HTML`- imports functions for handle HTML safety;

    * `Phoenix.HTML.Controller` - imports controllers functions
      commonly used in views;

    * `Phoenix.HTML.Tag` - imports functions for generating HTML tags;

  ## HTML Safe

  One of the main responsibilities of this module is to
  provide convenience functions for escaping and marking
  HTML code as safe.

  By default, data output in templates is not considered
  safe:

      <%= "<hello>" %>

  will be shown as:

      &lt;hello&gt;

  User data or data coming from the database is almost never
  considered safe. However, in some cases, you may want to tag
  it as safe and show its original contents:

      <%= safe "<hello>" %>

  Keep in mind most helpers will automatically escape your data
  and return safe content:

      <%= tag :p, "<hello>" %>

  will properly output:

      <p>&lt;hello&gt;</p>

  """

  @doc false
  defmacro __using__(_) do
    quote do
      use Phoenix.HTML.Controller

      import Phoenix.HTML
      import Phoenix.HTML.Tag
    end
  end

  @type safe    :: {:safe, unsafe}
  @type unsafe  :: iodata

  @doc """
  Marks the given value as safe.

      iex> Phoenix.HTML.safe("<hello>")
      {:safe, "<hello>"}
      iex> Phoenix.HTML.safe({:safe, "<hello>"})
      {:safe, "<hello>"}

  """
  @spec safe(unsafe | safe) :: safe
  def safe({:safe, value}), do: {:safe, value}
  def safe(value) when is_binary(value) or is_list(value), do: {:safe, value}

  @doc """
  Concatenates data in the given list safe.

      iex> Phoenix.HTML.safe_concat(["<hello>", "safe", "<world>"])
      {:safe, "&lt;hello&gt;safe&lt;world&gt;"}

  """
  @spec safe_concat([unsafe | safe]) :: safe
  def safe_concat(list) when is_list(list) do
    Enum.reduce(list, {:safe, ""}, &safe_concat(&2, &1))
  end

  @doc """
  Concatenates data safely.

      iex> Phoenix.HTML.safe_concat("<hello>", "<world>")
      {:safe, "&lt;hello&gt;&lt;world&gt;"}

      iex> Phoenix.HTML.safe_concat({:safe, "<hello>"}, "<world>")
      {:safe, "<hello>&lt;world&gt;"}

      iex> Phoenix.HTML.safe_concat("<hello>", {:safe, "<world>"})
      {:safe, "&lt;hello&gt;<world>"}

      iex> Phoenix.HTML.safe_concat({:safe, "<hello>"}, {:safe, "<world>"})
      {:safe, "<hello><world>"}

      iex> Phoenix.HTML.safe_concat({:safe, "<hello>"}, {:safe, '<world>'})
      {:safe, ["<hello>"|'<world>']}

  """
  @spec safe_concat(unsafe | safe, unsafe | safe) :: safe
  def safe_concat({:safe, data1}, {:safe, data2}), do: {:safe, io_concat(data1, data2)}
  def safe_concat({:safe, data1}, data2), do: {:safe, io_concat(data1, io_escape(data2))}
  def safe_concat(data1, {:safe, data2}), do: {:safe, io_concat(io_escape(data1), data2)}
  def safe_concat(data1, data2), do: {:safe, io_concat(io_escape(data1), io_escape(data2))}

  defp io_escape(data) when is_binary(data),
    do: Phoenix.HTML.Safe.BitString.to_iodata(data)
  defp io_escape(data) when is_list(data),
    do: Phoenix.HTML.Safe.List.to_iodata(data)

  defp io_concat(d1, d2) when is_binary(d1) and is_binary(d2), do:
    d1 <> d2
  defp io_concat(d1, d2), do:
    [d1|d2]

  @doc """
  Escapes the HTML entities in the given term, returning iodata.

      iex> Phoenix.HTML.html_escape("<hello>")
      {:safe, "&lt;hello&gt;"}

      iex> Phoenix.HTML.html_escape('<hello>')
      {:safe, ["&lt;", 104, 101, 108, 108, 111, "&gt;"]}

      iex> Phoenix.HTML.html_escape(1)
      {:safe, "1"}

      iex> Phoenix.HTML.html_escape({:safe, "<hello>"})
      {:safe, "<hello>"}
  """
  @spec html_escape(Phoenix.HTML.Safe.t) :: safe
  def html_escape({:safe, _} = safe),
    do: safe
  def html_escape(other) when is_binary(other),
    do: {:safe, Phoenix.HTML.Safe.BitString.to_iodata(other)}
  def html_escape(other),
    do: {:safe, Phoenix.HTML.Safe.to_iodata(other)}
end
