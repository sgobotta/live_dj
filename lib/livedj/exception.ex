defmodule Livedj.Exception do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      defexception Keyword.merge(
                     [reason: nil, message: nil],
                     Keyword.get(unquote(opts), :fields, [])
                   )
    end
  end
end
