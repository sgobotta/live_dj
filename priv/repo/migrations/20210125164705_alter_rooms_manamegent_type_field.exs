defmodule LiveDj.Repo.Migrations.AlterRoomsManamegentTypeField do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :management_type, :string, default: "free"
    end
  end
end
