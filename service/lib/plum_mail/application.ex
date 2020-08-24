defmodule PlumMail.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = port()
    {:ok, db_config} = :gleam@pgo.url_config(System.get_env("DATABASE_URL"))
    db_ssl = System.get_env("DATABASE_SSL") != "FALSE"
    db_config = [{:ssl, db_ssl} | db_config]

    children = [
      %{id: :pgo, start: {:gleam@pgo, :start_link, [:default, db_config]}, type: :supervisor},
      %{id: :cowboy, start: {:gleam@http@cowboy, :start, [&:plum_mail@web@router.handle/1, port]}}
    ]

    opts = [strategy: :one_for_one, name: PlumMail.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port() do
    with raw when is_binary(raw) <- System.get_env("PORT"), {port, ""} = Integer.parse(raw) do
      port
    else
      _ -> throw(ArgumentError)
    end
  end
end
