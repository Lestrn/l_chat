defmodule LChatWeb.LChatComponents.FunctionComponents do
  use Phoenix.Component

  attr :icon_name, :string, required: true
  attr :icon_size, :string, required: true
  attr :svg_path, :string, required: true

  def icon(assigns) do
    ~H"""
    <svg class={@icon_size}>
      <use href={"#{@svg_path <> @icon_name}"}></use>
    </svg>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, required: true
  attr :message_id, :integer, required: true

  def context_menu(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <button
        phx-click="open_modal_edit_msg"
        phx-value-message-id={@message_id}
        class="block w-full text-left px-4 py-2 hover:bg-gray-100"
      >
        ✏️ Edit Message
      </button>
      <button
        phx-click="delete_message"
        phx-value-message-id={@message_id}
        class="block w-full text-left px-4 py-2 hover:bg-gray-100 text-red-500"
      >
        🗑 Delete Message
      </button>
    </div>
    """
  end

  attr :presences, :list, required: true

  def users_section(assigns) do
    ~H"""
    <div class="mr-20 py-5 px-5 bg-white shadow-lg rounded-lg overflow-y-auto">
      <h2 class="text-lg font-semibold text-gray-800 mb-4">Users Online</h2>
      <ul class="flex flex-col gap-4">
        <.user_profile
          :for={
            {_user_id, meta} <-
              @presences
              |> Enum.sort(fn {_id1, meta1}, {_id2, meta2} -> meta1.is_typing > meta2.is_typing end)
          }
          class="flex items-center gap-4 p-4 border-2 border-gray-300 rounded-lg shadow-md transition duration-300 hover:shadow-xl hover:border-gray-400"
          user_meta={meta}
        />
      </ul>
    </div>
    """
  end

  attr :user_meta, :map, required: true
  attr :class, :string

  def user_profile(assigns) do
    ~H"""
    <li class={@class}>
      <div class="flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 text-white text-lg font-bold shadow-md">
        {String.first(@user_meta.username)}
      </div>
      <div>
        <span class="font-medium text-gray-900">{@user_meta.username}</span>
        <div :if={@user_meta.is_typing} class="flex space-x-1 mt-1">
          <span class="w-2.5 h-2.5 bg-blue-500 rounded-full animate-typing shadow-md"></span>
          <span class="w-2.5 h-2.5 bg-blue-500 rounded-full animate-typing shadow-md [animation-delay:0.2s]">
          </span>
          <span class="w-2.5 h-2.5 bg-blue-500 rounded-full animate-typing shadow-md [animation-delay:0.4s]">
          </span>
        </div>
      </div>
    </li>
    """
  end

  attr :current_user, :map, required: true
  attr :message, :map, required: true
  attr :message_id, :integer, required: true

  def message(assigns) do
    ~H"""
    <div
      id={@message_id}
      phx-hook="ContextMenuHook"
      data-current-user-id={@current_user.id}
      data-message-user-id={@message.user.id}
    >
      <div class={"flex #{@current_user.id == @message.user.id && "justify-end"}"}>
        <div class="w-[45%] my-[15px]">
          <p class="font-medium p-[5px]">{@message.user.username}</p>
          <p class="break-words font-light p-[10px] bg-[#F2F7FB] ml-[20px] rounded-tr-xl rounded-br-xl rounded-bl-xl">
            {@message.content}
          </p>
          <p class="text-gray-400 text-xs float-right">
            {Timex.format!(@message.inserted_at, "%b %d, %Y, %H:%M:%S", :strftime)}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
