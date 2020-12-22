defmodule LiveDj.Repo.Migrations.UpdatePlansExtraField do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :extra, :jsonb, default: "[]"
    end

  end
end
