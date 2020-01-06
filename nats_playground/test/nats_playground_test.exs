defmodule NatsPlaygroundTest do
  use ExUnit.Case
  doctest NatsPlayground

  test "greets the world" do
    assert NatsPlayground.hello() == :world
  end
end
