defmodule LChatWeb.LChatPage do
  use LChatWeb, :live_view
  alias LChat.Schemas.Message
  alias LChatWeb.LChatComponents.FunctionComponents
  alias LChat.Context.MessagesRepo

  @per_page 30
  def mount(_params, session, socket) do
    user = LChat.Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(message_form: get_message_changeset(nil, user.id) |> to_form())
     |> stream(
       :messages,
       MessagesRepo.get_messages_with_preload(:desc, 1, @per_page) |> Enum.reverse()
     )
     |> assign(total_pages_loaded: 1)
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
    MessagesRepo.create_message(%{
      content: content,
      user_id: socket.assigns.message_form.source.changes.user_id
    })

    {:noreply,
     socket
     |> stream_insert(
       :messages,
       MessagesRepo.get_last_msg_from_user(socket.assigns.message_form.source.changes.user_id)
     )
     |> assign(
       message_form: get_message_changeset(nil, socket.assigns.current_user.id) |> to_form()
     )
     |> push_event("scroll_down", %{})}
  end

  def handle_event("msg_is_being_typed", %{"message" => %{"content" => content}}, socket) do
    {:noreply,
     socket
     |> assign(
       message_form:
         get_message_changeset(content, socket.assigns.message_form.source.changes.user_id)
         |> Map.put(:action, :validate)
         |> to_form()
     )}
  end

  def handle_event("load_more_messages", _params, socket) do
    loaded_msgs =
      MessagesRepo.get_messages_with_preload(
        :desc,
        socket.assigns.total_pages_loaded + 1,
        @per_page
      )
      |> Enum.reverse()

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

  defp get_message_changeset(content, user_id) do
    %Message{} |> Message.changeset(%{content: content, user_id: user_id})
  end
end
