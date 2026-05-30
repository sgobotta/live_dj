defmodule Livedj.Sessions.Chat.Commands.Parser do
  @moduledoc """
  Parses raw chat input into a tagged command tuple.

  Plain text passes through as `{:text, content}`.
  Slash commands are parsed into typed tuples or return `{:error, {:unknown_command, name}}`.
  """

  @known_commands ~w(me skip queue name msg)

  @type parse_result ::
          {:ok, {:text, binary()}}
          | {:ok, {:me, binary()}}
          | {:ok, {:skip, nil}}
          | {:ok, {:queue, binary()}}
          | {:ok, {:name, binary()}}
          | {:ok, {:msg, binary(), binary()}}
          | {:error, {:unknown_command, binary()}}

  @spec parse(binary()) :: parse_result()
  def parse("/" <> rest) do
    {command, args} =
      case String.split(rest, " ", parts: 2) do
        [cmd] -> {cmd, ""}
        [cmd, args] -> {cmd, args}
      end

    if command in @known_commands do
      parse_command(command, args)
    else
      {:error, {:unknown_command, command}}
    end
  end

  def parse(text), do: {:ok, {:text, text}}

  @spec parse_command(binary(), binary()) :: parse_result()
  defp parse_command("me", args), do: {:ok, {:me, args}}
  defp parse_command("skip", _args), do: {:ok, {:skip, nil}}
  defp parse_command("queue", url), do: {:ok, {:queue, url}}
  defp parse_command("name", new_name), do: {:ok, {:name, new_name}}

  defp parse_command("msg", args) do
    case String.split(args, " ", parts: 2) do
      [room_id, content] -> {:ok, {:msg, room_id, content}}
      [room_id] -> {:ok, {:msg, room_id, ""}}
    end
  end
end
