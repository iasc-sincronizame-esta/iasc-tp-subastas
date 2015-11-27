defmodule IascTpSubastas do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    if System.get_env("type") == "client" do
      server = System.get_env "server"
      nick = System.get_env "nick"
      IO.puts "Connecting client #{nick} to #{server}"
      Node.connect(:"server@aldanaqm")

      {:ok, self}
    else
      start_server
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    IascTpSubastas.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_server do
    import Supervisor.Spec, warn: false
    children = [
      # Start the endpoint when the application starts
      supervisor(IascTpSubastas.Endpoint, []),
      # Start the Ecto repository
      worker(IascTpSubastas.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(IascTpSubastas.Worker, [arg1, arg2, arg3]),

      worker(SubasteroServer, [[name: {:global, GlobalSubastero}]], restart: :transient),
      worker(SubastasHome, [[name: {:global, GlobalSubastasHome}]], restart: :transient),
      worker(CompradoresHome, [[name: {:global, GlobalCompradoresHome}]], restart: :transient)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IascTpSubastas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
