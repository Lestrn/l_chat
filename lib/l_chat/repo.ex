defmodule LChat.Repo do
  use Ecto.Repo,
    otp_app: :l_chat,
    adapter: Ecto.Adapters.Postgres
end
