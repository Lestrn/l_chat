defmodule LChatWeb.LChatPage do
  use LChatWeb, :live_view
  alias LChat.Schemas.Message
  alias LChatWeb.LChatComponents.FunctionComponents

  def mount(_params, __session, socket) do
    {:ok,
     socket
     |> assign(message_form: Message.changeset(%Message{}, %{}) |> to_form())}
  end

  def handle_event("save", %{"message" => %{"context" => context}}, socket) do
    IO.inspect(context)
    {:noreply, socket}
  end
end
