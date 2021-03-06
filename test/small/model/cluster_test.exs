defmodule BreakingPP.Model.ClusterTest do
  use ExUnit.Case, async: true
  alias BreakingPP.Model.{Cluster, Node, Session}

  test "it can be created" do
    assert %Cluster{} = Cluster.new
  end

  test "started nodes can be accessed" do
    c = Cluster.new
    assert Cluster.started_nodes(c) == []
  end

  test "one node can be marked as started" do
    c = Cluster.new
    n = Node.new(1)
    c = Cluster.start_node(c, n)
    assert Cluster.started_nodes(c) == [n]
  end

  test "multiple nodes can be started" do
    c = Cluster.new
    n1 = Node.new(1)
    n2 = Node.new(2)
    c = Cluster.start_nodes(c, [n1, n2])
    assert Cluster.started_nodes(c) == [n1, n2]
  end

  test "stopped nodes can be accessed" do
    c = Cluster.new
    assert Cluster.stopped_nodes(c) == []
  end

  test "one node can be marked as stopped" do
    c = Cluster.new
    n = Node.new(1)
    c = Cluster.stop_node(c, n)
    assert Cluster.stopped_nodes(c) == [n]
  end

  test "node that is started and stopped is removed from started nodes" do
    c = Cluster.new
    n = Node.new(1)
    c = Cluster.start_node(c, n)
    c = Cluster.stop_node(c, n)
    assert Cluster.started_nodes(c) == []
    assert Cluster.stopped_nodes(c) == [n]
  end

  test "node that is stopped and started is removed from stopped nodes" do
    c = Cluster.new
    n = Node.new(1)
    c = Cluster.stop_node(c, n)
    c = Cluster.start_node(c, n)
    assert Cluster.started_nodes(c) == [n]
    assert Cluster.stopped_nodes(c) == []
  end

  test "a node can be checked for being stopped" do
    c = Cluster.new
    n1 = Node.new(1)
    n2 = Node.new(2)
    c = Cluster.stop_node(c, n1)
    assert Cluster.node_stopped?(c, n1)
    refute Cluster.node_stopped?(c, n2)
  end

  test "a node can be checked for being started" do
    c = Cluster.new
    n1 = Node.new(1)
    n2 = Node.new(2)
    c = Cluster.start_node(c, n1)
    c = Cluster.stop_node(c, n2)
    assert Cluster.node_started?(c, n1)
    refute Cluster.node_started?(c, n2)
  end

  test "sessions can be accessed" do
    {c, [n]} = given_cluster_with_nodes(1)
    c = Cluster.start_node(c, n)
    assert Cluster.sessions(c, n) == []
  end

  test "sessions can be added" do
    {c, [n]} = given_cluster_with_nodes(1)
    [s1, s2] = given_sessions(n, 2)

    c = Cluster.add_sessions(c, [s1, s2])

    assert Cluster.sessions(c) == [s1, s2]
  end

  test "sessions can be removed" do
    {c, [n1]} = given_cluster_with_nodes(1)
    [s1, s2, s3] = given_sessions(n1, 3)
    c = Cluster.add_sessions(c, [s1, s2, s3])

    c = Cluster.remove_sessions(c, [s1, s3])

    assert Cluster.sessions(c) == [s2]
  end

  test "sessions from a stopped node are removed" do
    {c, [n1, n2]} = given_cluster_with_nodes(2)
    sessions1 = given_sessions(n1, 2)
    sessions2 = given_sessions(n2, 3)
    c = Cluster.start_node(c, [n1, n2])
    c = Cluster.add_sessions(c, sessions1 ++ sessions2)

    c = Cluster.stop_node(c, n1)

    assert Cluster.sessions(c) == sessions2
  end

  test "it can check for split between nodes" do
    {c, [n1, n2, n3]} = given_cluster_with_nodes(3)

    c = Cluster.split(c, n1, n2)

    assert Cluster.split_between?(c, n1, n2)
    assert Cluster.split_between?(c, n2, n1)
    refute Cluster.split_between?(c, n2, n3)
    refute Cluster.split_between?(c, n3, n2)
  end

  test "sessions can be checked for one node" do
    {c, [n]} = given_cluster_with_nodes(1)
    sessions = given_sessions(n, 2)

    c = Cluster.add_sessions(c, sessions)

    assert Cluster.sessions(c, n) == sessions
  end

  test "sessions are removed if there's a split between nodes" do
    {c, [n1, n2]} = given_cluster_with_nodes(2)
    {s1, s2} = {given_sessions(n1, 2), given_sessions(n2, 3)}
    c = Cluster.add_sessions(c, s1 ++ s2)

    c = Cluster.split(c, n1, n2)

    assert Cluster.sessions(c, n1) == s1
    assert Cluster.sessions(c, n2) == s2
  end

  test "sessions are re-added after nodes join again" do
    {c, [n1, n2]} = given_cluster_with_nodes(2)
    {s1, s2} = {given_sessions(n1, 2), given_sessions(n2, 3)}
    c = Cluster.add_sessions(c, s1 ++ s2)
    c = Cluster.split(c, n1, n2)

    c = Cluster.join(c, n1, n2)

    assert Cluster.sessions(c, n1) == s1 ++ s2
    assert Cluster.sessions(c, n2) == s1 ++ s2
  end

  defp given_cluster_with_nodes(n) do
    c = Cluster.new
    nodes = given_nodes(n)
    {Cluster.start_nodes(c, nodes), nodes}
  end

  defp given_sessions(node, n) do
    Enum.map(1..n, fn i -> Session.new(node, "#{i}") end)
  end

  defp given_nodes(n) do
    Enum.map(1..n, fn i -> Node.new(i) end)
  end

end
