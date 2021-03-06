defmodule ConsoleWeb.GraphqlChannel do
  use Phoenix.Channel

  def join("graphql:orgs_index_table", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:configuration_index", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:invitations_table", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:members_table", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:api_keys", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:dc_index", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:dc_purchases_table", _message, socket) do
    {:ok, socket}
  end

  def join("graphql:alerts_index", _message, socket) do
    {:ok, socket}
  end
end
