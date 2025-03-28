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
end
