defmodule IascTpSubastas.PageController do
  use IascTpSubastas.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
