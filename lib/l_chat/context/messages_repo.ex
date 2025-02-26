defmodule LChat.Context.MessagesRepo do
  import Ecto.Query, warn: false
  alias LChat.Repo
  alias LChat.Schemas.Message

  def get_message(id), do: Repo.get(Message, id)

  def get_message_with_preload(id) do
    from(message in Message,
      where: message.id == ^id,
      preload: [:user]
    )
    |> Repo.one()
  end

  def get_messages(), do: Repo.all(Message)

  def get_messages_with_preload() do
    from(message in Message,
      preload: [:user]
    )
    |> Repo.all()
  end

  def update_message(id, attrs) do
    Repo.get(Message, id)
    |> Message.changeset(attrs, %{validate_msg_ownership: Map.has_key?(attrs, :user_id)})
    |> Repo.update()
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
