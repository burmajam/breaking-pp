defmodule BreakingPP.Test.TrackerAppTest do
  use ExUnit.Case
  import BreakingPP.Test.Eventually
  alias MapSet, as: S

  test "it returns empty list of sessions when no-one is connected" do
    given_no_sessions()
    r = HTTPoison.get!("http://localhost:4000/sessions")
    assert Poison.decode!(r.body) == []
  end

  test "it returns connected session id" do
    given_no_sessions()
    _s = Socket.Web.connect!("localhost", 4000, path: "/sessions/1")
    assert sessions() == ["1"]
  end

  test "it returns many connected session ids" do
    given_no_sessions()
    ids = Enum.map(1..100, &Integer.to_string/1)
    for id <- ids, do: given_session(id)

    assert S.difference(S.new(sessions()), S.new(ids)) == S.new
  end

  test "it doesn't return session id that connected and disconnected" do
    given_no_sessions()
    s1 = given_session("1")
    _s2 = given_session("2")
    :ok = Socket.Web.close(s1)
    assert eventually(fn -> sessions() == ["2"] end)
  end

  test "it reports its own status" do
    r = HTTPoison.get!("http://localhost:4000/status")
    assert r.status_code == 200
  end

  defp given_no_sessions do
    eventually(fn -> sessions() == [] end)
  end

  defp sessions do
    r = HTTPoison.get!("http://localhost:4000/sessions")
    Poison.decode!(r.body)
  end

  defp given_session(id) do
    Socket.Web.connect!("localhost", 4000, path: "/sessions/#{id}")
  end

end
