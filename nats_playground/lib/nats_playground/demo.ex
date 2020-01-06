defmodule NatsPlayground.Demo do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def publish(server \\ __MODULE__, topic, msg) do
    GenServer.call(server, {:publish, topic, msg})
  end

  def subscribe(server \\ __MODULE__, topic) do
    GenServer.call(server, {:subscribe, topic})
  end

  def echo_request(server \\ __MODULE__, body) do
    GenServer.call(server, {:echo_request, body})
  end
  
  @impl true
  def init(_) do
    {:ok, gnat} = Gnat.start_link(%{host: '127.0.0.1', port: 4222})
    {:ok, _} = Gnat.sub(gnat, self(), "echo", queue_group: "echo_servers")
    {:ok, %{gnat: gnat}}
  end

  @impl true
  def handle_call({:publish, topic, msg}, _from, state) do
    result = Gnat.pub(state.gnat, topic, msg)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:subscribe, topic}, _from, state) do
    subscription = Gnat.sub(state.gnat, self(), topic)
    {:reply, subscription, state}
  end

  @impl true
  def handle_call({:echo_request, body}, from, state) do
    Task.start_link(fn ->
      result = Gnat.request(state.gnat, "echo", body)
      GenServer.reply(from, result)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:msg, %{topic: "echo"} = msg}, state) do
    IO.inspect(msg.body, label: "sending echo reply")
    Gnat.pub(state.gnat, msg.reply_to, msg.body)
    {:noreply, state}
  end

  @impl true
  def handle_info({:msg, msg}, state) do
    IO.inspect(msg, label: "receive")
    {:noreply, state}
  end
end
