defmodule PlumMail.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = 8000

    children = [
      %{id: :cowboy, start: {:gleam@http@cowboy, :start, [&:plum_mail@web@router.handle/1, port]}}
    ]

    opts = [strategy: :one_for_one, name: PlumMail.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
