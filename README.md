# NATS (Streaming) Demo w/ Elixir

**NOTE:** Really rough, no error handling really implemented

## 1. Starting up NATS servers

In one terminal window, run:


```sh
./start-nats-in-docker.sh
./start-nats-streaming-in-docker.sh
```

(two servers are unrelated, but the Elixir app will crash if either isn't
reachable)

## 2. Starting Elixir app

```sh
$ cd nats_playground
$ iex --sname dev1 -S mix
```

NATS Streaming `clientID` is derived from the node's name, so use a different
node name for the 2nd / 3rd concurrent clients, i.e.:

```sh
$ iex --sname dev2 -S mix
$ iex --sname dev3 -S mix
```

## 3. Playing around with NATS

The `NatsPlayground.Demo` module wraps a connection to the regular NATS server
for easy use from `iex`:

```elixir
iex> NatsPlayground.Demo.subscribe("hello.*")
iex> NatsPlayground.Demo.publish("hello.world", "Hello, earthlings.")
iex> NatsPlayground.Demo.publish("hello.space", "Hello, alians.")

# `NatsPlayground.Demo` echos back any requests on the `echo` topic

iex> NatsPlayground.Demo.echo_request("Hello!")
```

Can experiment with subscribing/publishing on different instances of iex
connected to the same NATS server.

## 4. Playing around with NATS Streaming

Can use the `Stan` module to access NATS Streaming

```elixir
# publish a message (no subscribers yet though)
iex> Stan.pub(Stan, "hello.world", "First message!")

# subscribe (the iex shell process) to hello.world subject
#   `max_in_flight: 2` - allow up to 2 "in flight" messages (messages delivered but not ack'd yet)
#   `durable_name: "sub1"` - create a durable subscription - server will store our position
#   `start_position: :first` - fetch all messages (in hello.world) from beginning of time
iex> {:ok, sub} = Stan.sub(Stan, self(), "hello.world", max_in_flight: 2, durable_name: "sub1", start_position: :first)

# grab the "First message!" sent to the iex process
iex> {:msg, ack1, msg1} = receive do x -> x end

# publish a couple more messages
iex> Stan.pub(Stan, "hello.world", "Second message!")
iex> Stan.pub(Stan, "hello.world", "Third message!")

# notice that we haven't got the third message yet because `max_in_flight: 2`
iex> flush

# ack the first message
iex> Stan.ack(Stan, ack1)

# we received the third message now!
iex> flush


#  ... restart iex (using name node name) ...


# After restarting iex (and hence disconnecting & reconnecting from NATS), we
# can open the subscription again  with the same durable name
iex> {:ok, sub} = Stan.sub(Stan, self(), "hello.world", max_in_flight: 2, durable_name: "sub1", start_position: :first)

# notice we get 'Second message!' and 'Third message!' because we haven't ack'd them yet
iex> flush
```
