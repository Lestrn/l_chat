defmodule LChatWeb.LChatPage do
  use LChatWeb, :live_view
  alias LChat.Schemas.Message
  alias LChatWeb.LChatComponents.FunctionComponents
  alias LChat.Context.MessagesRepo

  def mount(_params, session, socket) do
    user = LChat.Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(message_form: get_message_changeset(nil, user.id) |> to_form())
     |> assign(messages: MessagesRepo.get_messages_with_preload())}
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
     |> assign(messages: MessagesRepo.get_messages_with_preload())
     |> assign(
       message_form: get_message_changeset(nil, socket.assigns.current_user.id) |> to_form()
     )}
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

  defp get_message_changeset(content, user_id) do
    %Message{} |> Message.changeset(%{content: content, user_id: user_id})
  end
end
