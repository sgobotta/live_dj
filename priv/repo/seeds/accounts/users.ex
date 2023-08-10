defmodule Livedj.Seeds.Accounts.Users do
  @moduledoc """
  Seeds for the User model
  """

  use Livedj.Seeds.Utils,
    repo: Livedj.Repo,
    json_file_path: "accounts/users.json",
    plural_element: "users",
    element_module: Livedj.Accounts.User,
    date_keys: [:confirmed_at, :inserted_at, :updated_at]
end
