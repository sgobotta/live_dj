defmodule Livedj.Accounts.Guest do
  @moduledoc """
  Represents an unauthenticated visitor with a stable session identity.
  """

  @enforce_keys [:id, :username]
  defstruct [:id, :username]

  @type t :: %__MODULE__{id: binary(), username: binary()}
end
