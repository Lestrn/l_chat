defmodule LChat.Context.MessagesRepo do
  import Ecto.Query, warn: false
  alias LChat.Repo
  alias LChat.Schemas.Message
  alias LChat.Accounts.User

  def subscribe() do
    Phoenix.PubSub.subscribe(LChat.PubSub, "lchat")
  end

  def broadcast({:ok, message}, tag) do
    Phoenix.PubSub.broadcast(LChat.PubSub, "lchat", {tag, message})
    {:ok, message}
  end

  def get_message(id), do: Repo.get(Message, id)

  def get_message_with_preload(id) do
    from(message in Message,
      where: message.id == ^id,
      preload: [:user]
    )
    |> Repo.one()
  end

  def get_last_msg_from_user(user_id) do
    from(m in Message,
      join: u in User,
      on: m.user_id == u.id,
      where: u.id == ^user_id,
      order_by: [desc: m.inserted_at],
      preload: [:user],
      select: m,
      limit: 1
    )
    |> Repo.one()
  end

  def get_messages_with_preload(sort_by, current_page, per_page) do
    from(message in Message, order_by: [{^sort_by, message.inserted_at}, {^sort_by, message.id}])
    |> paginate_messages(current_page, per_page)
    |> preload_user()
    |> Repo.all()
  end

  def paginate_messages(query, current_page, per_page) do
    offset = max((current_page - 1) * per_page, 0)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  def preload_user(query) do
    from(message in query,
      preload: [:user]
    )
  end

  def get_messages(), do: Repo.all(Message)

  def get_messages_with_preload() do
    from(message in Message,
      preload: [:user]
    )
    |> Repo.all()
  end

  def update_message(id, attrs) do
    with %Message{} = message <- Repo.get(Message, id) do
      message
      |> Message.changeset(attrs, %{validate_msg_ownership: Map.has_key?(attrs, :user_id)})
      |> Repo.update()
    else
      nil -> {:error, "Message was not found"}
    end
  end

  def create_message(attrs) do
    with {:ok, message} <- Repo.insert(%Message{} |> Message.changeset(attrs)) do
      {:ok, Repo.preload(message, [:user])}
      |> broadcast(:message_created)
    else
      {:error, changeset} -> {:error, changeset}
      _ -> {:error, "Unexpected error"}
    end
  end

  def delete_message(id) do
    with %Message{} = message <- Repo.get(Message, id) do
      Repo.delete(message)
    else
      nil -> {:error, "Message was not found"}
    end
  end

  def clear_msgs() do
    Repo.delete_all(Message)
  end
end
