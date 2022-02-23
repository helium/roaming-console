defmodule ConsoleWeb.Monitor do
  use Agent
  
  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get_packet_purchaser_address do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def update_packet_purchaser_address(address) do
    Agent.update(MODULE, fn state -> Map.put(state, :address, address) end)
  end

  def get_packets_state do
    Agent.get(__MODULE__, fn state -> Map.get(state, :packets_state) end)
  end

  def add_to_packets_state(tag, payload) do
    Agent.update(__MODULE__, fn state -> Map.put(state, :packets_state, [{tag, payload} | state.packets_state]) end)
  end

  def remove_from_packets_state(count) do
    Agent.update(__MODULE__, fn state -> Map.put(state, :packets_state, Enum.drop(state.packets_state, -1 * count)) end)
  end

  def get_packets_error_state do
    Agent.get(__MODULE__, fn state -> Map.get(state, :packets_error_state) end)
  end

  def add_to_packets_error_state(payload) do
    Agent.update(__MODULE__, fn state -> Map.put(state, :packets_error_state, [payload | state.packets_error_state]) end)
  end

  def remove_from_packets_error_state do
    Agent.update(__MODULE__, fn state -> Map.put(state, :packets_error_state, Enum.drop(state.packets_error_state, -1)) end)
  end

  def get_amqp_publish_conn do
    Agent.get(__MODULE__, fn state -> Map.get(state, :amqp_publish_conn) end)
  end

  def update_amqp_publish_conn(tag) do
    Agent.update(__MODULE__, fn state -> Map.put(state, :amqp_publish_conn, tag) end)
  end

  def get_amqp_consume_conn do
    Agent.get(__MODULE__, fn state -> Map.get(state, :amqp_consume_conn) end)
  end

  def update_amqp_consume_conn(tag) do
    Agent.update(__MODULE__, fn state -> Map.put(state, :amqp_consume_conn, tag) end)
  end
end
