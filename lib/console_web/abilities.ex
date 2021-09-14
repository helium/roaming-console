defmodule ConsoleWeb.Abilities do
  alias Console.Organizations.Membership

  def can?(%Membership{role: "admin"}, _action, _controller) do
    true
  end

  def can?(%Membership{role: "manager"}, action, controller) do
    cond do
      controller == ConsoleWeb.DataCreditController -> false
      controller == ConsoleWeb.ApiKeyController -> false
      controller == ConsoleWeb.InvitationController and action in [:create, :delete] -> false
      controller == ConsoleWeb.MembershipController and action in [:update, :delete] -> false
      true -> true
    end
  end

  def can?(_membership, _action, _controller), do: false
end
