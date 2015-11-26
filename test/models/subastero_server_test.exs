defmodule SubasteroServerTest do
  use ExUnit.Case

  test "inicialmente no hay subastas" do
    {:ok, subastero} = SubasteroServer.start_link

    subastas = SubasteroServer.listar_subastas subastero
    assert subastas = %{}
  end
end