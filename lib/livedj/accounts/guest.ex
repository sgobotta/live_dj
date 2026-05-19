defmodule Livedj.Accounts.Guest do
  @moduledoc """
  Represents an unauthenticated visitor with a stable session identity.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: binary()}
end
