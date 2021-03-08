defmodule PlumMail.Application do
  @moduledoc false

  use Application

  def start_cowboy(config) do
    case :gleam@http@cowboy.start(&:plum_mail@web@router.handle(&1, config), port()) do
      {:ok, {:sender, pid, _other}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  def start(_type, _args) do
    :ok = Application.put_env(:pg_types, :json_config, {:jsone, [], [{:keys, :binary}]})
    {:ok, db_config} = :gleam@pgo.url_config(System.get_env("DATABASE_URL"))
    db_ssl = System.get_env("DATABASE_SSL") != "FALSE"
    db_config = [{:ssl, db_ssl} | db_config]

    {:ok, config} = :plum_mail@config.from_env()
    nil = :gleam@beam@logger.add_handler(&:plum_mail@logger.handle(config, &1, &2, &3))

    children = [
      %{id: :pgo, start: {:gleam@pgo, :start_link, [:default, db_config]}, type: :supervisor},
      %{
        id: :cowboy,
        start: {__MODULE__, :start_cowboy, [config]}
      }
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
