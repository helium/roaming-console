defmodule Console.Notifications.NotificationResolver do
  alias Console.Repo
  import Ecto.Query

  alias Console.Notifications

  def find(_, %{context: %{current_organization: current_organization}}) do
    notifications = Notifications.get_notification(current_organization)
    
    { :ok, notifications }
  end
end
