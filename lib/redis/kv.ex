defmodule Redis.Kv do
  use GenServer
  require Logger

  @table :kv

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  def set(key, value) do
    :ets.insert(@table, {key, value})
    :ok
  end

  def delete(key) do
    :ets.delete(@table, key)
    :ok
  end

  # GenServer callbacks
  @impl true
  def init(opts) do
    pid = :ets.new(@table, [:set, :named_table, :public])
    Logger.info("Starting KV with ETS table #{pid}...")
    {:ok, opts}
  end
end
