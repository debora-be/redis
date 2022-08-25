defmodule Redis.Server do
  require Logger

  alias Redis.Parser
  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client, 0)
    loop_acceptor(socket)
  end

  defp serve(socket, state) do
    case read_line(socket) do
      {:ok, data} ->
        state = state <> data

        case Parser.decode(state) do
          {:ok, command} ->
            handle_command(socket, command)
            serve(socket, "")

          {:incomplete, _} ->
            serve(socket, state)
        end

      {:error, reason} ->
        Logger.info("Receive error: #{inspect(reason)}")
    end
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp reply(socket, data) do
    :gen_tcp.send(socket, data)
  end

  defp handle_command(socket, command) do
    case command do
      ["SET", key, value] ->
        Redis.Kv.set(key, value)
        reply(socket, "+OK\r\n")

      ["GET", key] ->
        case Redis.Kv.get(key) do
          {:ok, value} -> reply(socket, "+#{value}\r\n")
          {:error, :not_found} -> reply(socket, "$-1\r\n")
        end
    end
  end
end
