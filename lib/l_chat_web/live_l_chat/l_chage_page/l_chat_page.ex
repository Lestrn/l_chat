defmodule LChatWeb.LChatPage do
  use LChatWeb, :live_view
  alias LChat.Schemas.Message
  alias LChatWeb.LChatComponents.FunctionComponents
  alias LChat.Context.MessagesRepo

  def mount(_params, __session, socket) do
    {:ok,
     socket
     |> assign(message_form: Message.changeset(%Message{}, %{}) |> to_form())
     |> assign(messages: MessagesRepo.get_messages_with_preload())}
  end

  def handle_event("save", %{"message" => %{"content" => content}}, socket) do
    MessagesRepo.create_message(%{content: content, user_id: socket.assigns.current_user.id})

    {:noreply,
     socket
     |> assign(messages: MessagesRepo.get_messages_with_preload())
     |> assign(message_form: Message.changeset(%Message{}, %{}) |> to_form())}
  end
end
