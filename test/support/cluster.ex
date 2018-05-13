defmodule BreakingPP.Test.Cluster do
  import BreakingPP.Test.Eventually

  def cluster_started(size) do
    {_, 0} = cmd(["stop_cluster"])
    {_, 0} = cmd(["create_network"])
    Enum.map(1..size, fn i -> start_node(i, size) end)
  end

  def start_node(i, cluster_size) do
    {_, 0} = cmd(["start_node", "#{i} #{cluster_size}"])
    n = node_map(i)
    eventually(fn ->
      case HTTPoison.get("http://#{n.host}:#{n.port}/status", []) do
        {:ok, r} -> r.status_code == 200
        _ -> false
      end
    end)
    n
  end

  def node_map(i) do
    {ip, 0} = cmd(["node_ip", "#{i}"])
    %{host: String.trim(ip), port: 4000}
  end

  def session_connected(n, id) do
    s = Socket.Web.connect!(n.host, n.port, path: "/sessions/#{id}")
    Socket.active(s.socket)
    s 
  end

  def session_disconnected(socket) do
    Socket.Web.close(socket)
  end

  def sessions(n) do
    r = HTTPoison.get!("http://#{n.host}:#{n.port}/sessions")
    Poison.decode!(r.body) |> Enum.sort
  end

  defp cmd(cmd) do
    System.cmd(Path.join([File.cwd!, "priv", "cluster.sh"]), cmd)
  end

end
