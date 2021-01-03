defmodule Mix.Tasks.DispatchEmails do
  use Mix.Task

  def run(_) do
    Application.ensure_all_started(:plum_mail)
    :plum_mail@threads@dispatch_notifications.run()
  end
end
