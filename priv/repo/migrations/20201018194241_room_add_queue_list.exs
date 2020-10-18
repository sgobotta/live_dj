defmodule LiveDj.Repo.Migrations.RoomAddQueueList do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :queue, :jsonb, default: "[]"
    end
  end
end
