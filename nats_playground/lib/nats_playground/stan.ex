defmodule Stan do
  use GenServer

  def start_link(opts) do
    genserver_opts = Keyword.take(opts, [:name])
    GenServer.start_link(__MODULE__, Map.new(opts), genserver_opts)
  end

  @impl true
  def init(%{connection_settings: connection_settings} = opts) do
    {:ok, gnat} = Gnat.start_link(connection_settings)

    opts =
      opts
      |> Map.delete(:connection_settings)
      |> Map.put(:gnat, gnat)

    init(opts)
  end

  @impl true
  def init(%{gnat: gnat} = opts) do
    conn_req = Pb.ConnectRequest.new(
      clientID: nuid(),
      heartbeatInbox: "_HEARTBEAT.#{nuid()}",
      protocol: 1,
      connID: nuid(),
      pingInterval: 20,
      pingMaxOut: 3
    )

    {:ok, _} = Gnat.sub(gnat, self(), conn_req.heartbeatInbox)
    {:ok, conn_resp} = request(gnat, "_STAN.discover.test-cluster", conn_req)

    state = %{
      gnat: gnat,
      conn_id: conn_req.connID,
      pub_prefix: conn_resp.pubPrefix,
      topic_heartbeat: conn_req.heartbeatInbox,
      topic_close: conn_resp.closeRequests,
      topic_ping: conn_resp.pingRequests,
      topic_sub_close: conn_resp.subCloseRequests,
      topic_sub: conn_resp.subRequests,
      topic_unsub: conn_resp.unsubRequests
    }

    {:ok, state}
  end

  def handle_info({:msg, %{topic: topic}}, %{topic_heartbeat: topic} = state) do
    {:ok, _} = request(state.gnat, state.topic_ping, Pb.Ping.new(connID: state.conn_id))
    {:noreply, state}
  end

  defp nuid(), do: :crypto.strong_rand_bytes(12) |> Base.encode16

  defp request(gnat, topic, %req_module{} = req) do
    IO.inspect(req, label: ">>> #{topic}")
    resp_module = response_module(req_module)

    {:ok, %{body: body}} = Gnat.request(gnat, topic, req_module.encode(req))

    result = resp_module.decode(body)

    IO.inspect(result, label: "<<<")

    result
    |> case do
      %{error: ""} = result -> {:ok, result}
      %{error: error} = result -> {:error, error}
    end
  end

  defp response_module(request_type)
  defp response_module(Pb.ConnectRequest), do: Pb.ConnectResponse
  defp response_module(Pb.Ping), do: Pb.PingResponse
end
