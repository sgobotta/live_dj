defmodule Livedj.Repo.Migrations.UpdateVideosAddChannelField do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :channel, :string
    end
  end
end
