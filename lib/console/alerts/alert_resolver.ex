defmodule Console.Alerts.AlertResolver do
  alias Console.Repo
  import Ecto.Query

  alias Console.Alerts

  def find(_, %{context: %{current_organization: current_organization}}) do
    alerts = Alerts.get_alert(current_organization)
    
    { :ok, alerts }
  end
end
