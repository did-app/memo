defmodule Mix.Tasks.ReportActivity do
  use Mix.Task

  def run([conversation_id, identifier_id]) do
    Application.ensure_all_started(:plum_mail)
    :plum_mail@metrics@metrics.execute(conversation_id, identifier_id)
  end
end
