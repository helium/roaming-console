defmodule Console.Jobs do
  # This module defines the jobs to be ran by Quantum scheduler
  # as defined in config/config.exs

  alias Console.Email
  alias Console.Mailer
  alias Console.Organizations
  alias Console.Alerts
  alias Console.AlertEvents
  alias Console.Repo

  def send_alerts do
    # to avoid spamming customers with multiple notifications for the same event, get notifications in 5-min batches
    now = Timex.now
    buffer = -5
    alertable_email_events = AlertEvents.get_unsent_alert_events_since("email", Timex.shift(now, minutes: buffer))
    alertable_webhook_events = AlertEvents.get_unsent_alert_events_since("webhook", Timex.shift(now, minutes: buffer))

    # send emails for this batch, grouped by event type and label
    Enum.each(Enum.group_by(alertable_email_events, &Map.take(&1, [:alert_id, :event])), fn {identifiers, events} ->
      Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
        send_specific_event_email(identifiers, events)
      end)
    end)

    Enum.each(Enum.group_by(alertable_webhook_events, &Map.take(&1, [:alert_id, :event])), fn {identifiers, events} ->
      Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
        send_webhook(identifiers, events)
      end)
    end)
  end

  defp send_specific_event_email(identifiers, events) do
    alert = Alerts.get_alert(identifiers.alert_id)
    alert_event_email_config = alert.config[identifiers.event]["email"]

    # continue w/ email if the setting for the specific label
    if alert_event_email_config != nil do
      # based on settings, prepare info needed for email
      organization = Organizations.get_organization(alert.organization_id)
      roles = case alert_event_email_config["recipient"] do
        "admin" -> ["admin"]
        "manager" -> ["manager"]
        "read" -> ["read"]
        "all" -> ["admin", "manager", "read"]
      end
      recipients = Organizations.get_memberships_by_organization_and_role(alert.organization_id, roles) |> Enum.map(fn (member) -> member.email end)
      details = Enum.map(events, fn (e) -> e.details end)
      has_hotspot_info = case Enum.find(details, fn d -> d["hotspot"] !== nil and length(Map.keys(d["hotspot"])) > 0 end) do
        nil -> false
        _ -> true
      end

      Enum.each(events, fn e -> AlertEvents.mark_alert_event_sent(e) end)
    end
  end

  defp send_webhook(identifiers, events) do
    alert = Alerts.get_alert(identifiers.alert_id)
    alert_event_webhook_config = alert.config[identifiers.event]["webhook"]

    if alert_event_webhook_config != nil do
      organization = Organizations.get_organization(alert.organization_id)

      # sanitize events by removing __meta__ field which causes JSON serializing differences on request end
      sanitized_events = Enum.map(events, fn e -> Map.delete(Map.from_struct(e), :__meta__) end)

      payload = Poison.encode!(sanitized_events)
      headers = [
        {"X-Helium-Hmac-SHA256", :crypto.hmac(:sha256, organization.webhook_key, payload) |> Base.encode64(padding: true)},
        {"Content-Type", "application/json"}
      ]
      HTTPoison.post(alert_event_webhook_config["url"], payload, headers)
      Enum.each(events, fn e -> AlertEvents.mark_alert_event_sent(e) end)
    end
  end

  def delete_sent_alerts do
    # since events are kept as "sent" so we can check against flapping, delete them in 25-hr batches, 24 + 1 to delete alerts triggered in last 5 min before reset
    buffer = -25
    AlertEvents.delete_sent_alert_events_since(Timex.shift(Timex.now, hours: buffer))
  end
end
