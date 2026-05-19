defmodule Livedj.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end

    execute(
      "UPDATE users SET username = split_part(email, '@', 1)",
      "UPDATE users SET username = NULL"
    )
  end
end
