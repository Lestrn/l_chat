defmodule LChat.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    belongs_to :user, LChat.Accounts.User, foreign_key: :user_id
    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs, opts \\ %{}) do
    message
    |> cast(attrs, [:content, :user_id])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:content, :user_id])
    |> validate_user_exists()
    |> maybe_validate_message_ownership(Map.get(opts, :validate_msg_ownership))
  end

  defp validate_user_exists(changeset) do
    user_id = get_field(changeset, :user_id)

    if user_id && !LChat.Accounts.get_user(user_id) do
      add_error(changeset, :user_id, "User does not exist")
    else
      changeset
    end
  end

  defp maybe_validate_message_ownership(changeset, true) do
    if Map.has_key?(changeset.changes, :user_id) do
      add_error(changeset, :user_id, "Cant change ownership of user")
    else
      changeset
    end
  end

  defp maybe_validate_message_ownership(changeset, _) do
    changeset
  end
end
