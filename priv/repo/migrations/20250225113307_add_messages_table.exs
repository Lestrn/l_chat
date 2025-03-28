defmodule LChat.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: true
      timestamps(type: :utc_datetime)
    end
  end
end
