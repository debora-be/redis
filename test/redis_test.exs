defmodule RedisTest do
  use ExUnit.Case
  doctest Redis

  test "greets the world" do
    assert Redis.hello() == :world
  end
end
