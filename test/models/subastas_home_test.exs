require SubastasHome

defmodule SubastasHomeTest do
  use ExUnit.Case

  test "upsert, when no there is no value for that key" do
    {:ok, home} = SubastasHome.start_link

    SubastasHome.upsert(home, 1, "datos")
    assert SubastasHome.get(home, 1) == "datos"
  end

  test "upsert, when there was another value for that key stored" do
    {:ok, home} = SubastasHome.start_link

    SubastasHome.upsert(home, 1, "datos")
    SubastasHome.upsert(home, 1, "datos2")
    assert SubastasHome.get(home, 1) == "datos2"
  end

  test "get, when there is no value for that key" do
    {:ok, home} = SubastasHome.start_link

    assert SubastasHome.get(home, 1) == nil
  end

  test "delete" do
    {:ok, home} = SubastasHome.start_link

    SubastasHome.upsert(home, 1, "datos")
    SubastasHome.delete(home, 1)
    assert SubastasHome.get(home, 1) == nil
  end

  test "get_all" do
    {:ok, home} = SubastasHome.start_link

    SubastasHome.upsert(home, 1, "datos")
    SubastasHome.upsert(home, 2, "datos2")

    assert SubastasHome.get_all(home) == %{ 1 => "datos", 2 => "datos2"}
  end
end