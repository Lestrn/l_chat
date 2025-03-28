defmodule LChatWeb.LChatPage do
  use LChatWeb, :live_view
  alias LChat.Schemas.Message
  alias LChat.Context.MessagesRepo
  alias LChatWeb.Presence

  def mount(_params, session, socket) do
    user = LChat.Accounts.get_user_by_session_token(session["user_token"])

    if(connected?(socket)) do
      MessagesRepo.subscribe()

      {:ok, _} =
        Presence.track(self(), MessagesRepo.get_pubsub_topc(), user.id, %{
          username: user.username,
          is_typing: false
        })
    end

    {:ok,
     socket
     |> assign(message_form: get_message_changeset(nil, user.id) |> to_form())
     |> assign(edit_msg_form: nil)
     |> assign(total_pages_loaded: 1)
     |> assign(per_page: 100)
     |> assign(presences: Presence.list(MessagesRepo.get_pubsub_topc()) |> simple_presence_map())
     |> assign(message_id: nil)
     |> assign(show_edit_msg_modal: false)
     |> stream(:messages, [])}
  end

  def handle_event("load_messages", %{"screen_height" => screen_height}, socket) do
    per_page = (screen_height / 43) |> Float.round() |> trunc()

    {:noreply,
     socket
     |> stream(
       :messages,
       MessagesRepo.get_messages_with_preload(:desc, 1, per_page)
       |> Enum.reverse()
     )
     |> assign(per_page: per_page)
     |> push_event("scroll_down", %{})}
  end

  def handle_event("save", %{"message" => %{"content" => ""}}, socket) do
    {:noreply,
     socket
     |> assign(
       message_form:
         get_message_changeset(nil, socket.assigns.message_form.source.changes.user_id)
         |> Map.put(:action, :validate)
         |> to_form()
     )}
  end

  def handle_event("save", %{"message" => %{"content" => content}}, socket) do
    current_user_id = socket.assigns.message_form.source.changes.user_id

    MessagesRepo.create_message(%{
      content: content,
      user_id: current_user_id
    })

    change_meta_if_user_is_typing(current_user_id, false)

    {:noreply,
     socket
     |> assign(
       message_form:
         get_message_changeset(nil, current_user_id)
         |> to_form()
     )}
  end

  def handle_event("msg_is_being_typed", %{"message" => %{"content" => content}}, socket) do
    current_user_id = socket.assigns.message_form.source.changes.user_id

    if content == "" do
      change_meta_if_user_is_typing(current_user_id, false)
    else
      change_meta_if_user_is_typing(current_user_id, true)
    end

    {:noreply,
     socket
     |> assign(
       message_form:
         get_message_changeset(content, current_user_id)
         |> Map.put(:action, :validate)
         |> to_form()
     )}
  end

  def handle_event("load_more_messages", _params, socket) do
    loaded_msgs =
      MessagesRepo.get_messages_with_preload(
        :desc,
        socket.assigns.total_pages_loaded + 1,
        socket.assigns.per_page
      )

    if loaded_msgs != [] do
      {:noreply,
       Enum.reduce(loaded_msgs, socket, fn message, acc_socket ->
         stream_insert(acc_socket, :messages, message, at: 0)
       end)
       |> update(:total_pages_loaded, fn tpl -> tpl + 1 end)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_msg_id_for_context", %{"message-id" => message_id}, socket) do
    {:noreply, socket |> assign(message_id: message_id)}
  end

  def handle_event("open_modal_edit_msg", %{"message-id" => message_id}, socket) do
    with %Message{} = message <- MessagesRepo.get_message(message_id) do
      {:noreply,
       socket
       |> assign(edit_msg_form: Message.changeset(message) |> to_form())
       |> assign(show_edit_msg_modal: true)}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Message was not found")}
    end
  end

  def handle_event("close_edit_msg_modal", _, socket) do
    {:noreply,
     socket

     |> assign(show_edit_msg_modal: false)}
  end

  def handle_event("validate_edit_msg", %{"message" => %{"content" => content}}, socket) do
    current_user_id = socket.assigns.message_form.source.changes.user_id

    {:noreply,
     socket
     |> assign(
       edit_msg_form:
         get_message_changeset(content, current_user_id)
         |> Map.put(:action, :validate)
         |> to_form()
     )}
  end

  def handle_event("save_edit_msg", %{"message" => %{"content" => content}}, socket) do
    current_user_id = socket.assigns.current_user.id

    with {:ok, _message} <-
           MessagesRepo.update_message(socket.assigns.message_id, %{
             content: content,
             user_id: current_user_id
           }) do
      {:noreply,
       socket
       |> put_flash(:info, "Msg was updated")
       |> assign(show_edit_msg_modal: false)}
    else
      _ ->
        {:noreply,
         socket
         |> assign(
           edit_msg_form:
             get_message_changeset(content, current_user_id)
             |> Map.put(:action, :validate)
             |> to_form()
         )}
    end
  end

  def handle_event("delete_message", %{"message-id" => message_id}, socket) do
    with {:ok, _} <- MessagesRepo.delete_message!(message_id) do
      {:noreply, socket |> put_flash(:info, "Message was deleted")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Something went wrong deleting the msg")}
    end
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> push_event("scroll_down", %{
       current_user_owns_msg: socket.assigns.current_user.id == message.user.id
     })}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply,
     socket
     |> stream_delete(:messages, message)}
  end

  def handle_info({:message_updated, message}, socket) do
    {:noreply,
     socket
     |> stream_insert(:messages, message)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    {:noreply,
     socket
     |> remove_presences(diff.leaves)
     |> add_presences(diff.joins)}
  end

  defp get_message_changeset(content, user_id) do
    %Message{} |> Message.changeset(%{content: content, user_id: user_id})
  end

  defp simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} -> {user_id, meta} end)
  end

  defp add_presences(socket, joins) do
    simple_presence_map(joins)
    |> Enum.reduce(socket, fn {user_id, meta}, socket ->
      update(socket, :presences, &Map.put(&1, user_id, meta))
    end)
  end

  defp remove_presences(socket, leaves) do
    simple_presence_map(leaves)
    |> Enum.reduce(socket, fn {user_id, _}, socket ->
      update(socket, :presences, &Map.delete(&1, user_id))
    end)
  end

  defp change_meta_if_user_is_typing(current_user_id, is_typing) do
    %{metas: [meta | _]} = Presence.get_by_key(MessagesRepo.get_pubsub_topc(), current_user_id)

    new_meta = %{meta | is_typing: is_typing}

    Presence.update(self(), MessagesRepo.get_pubsub_topc(), current_user_id, new_meta)
  end
end
