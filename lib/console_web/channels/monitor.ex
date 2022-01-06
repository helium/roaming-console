defmodule ConsoleWeb.Monitor do
  use Agent
  
  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get_packet_purchaser_address do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def update_packet_purchaser_address(address) do
    Agent.update(__MODULE__, fn _ -> address end)
  end
end
