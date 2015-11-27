defmodule Home.PersistentSubastas do
  defmacro __using__(_) do
    quote do
      use GenServer
      alias IascTpSubastas.Subasta

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      def start(opts \\ []) do
        GenServer.start(__MODULE__, :ok, opts)
      end

      def get_all(server) do
        GenServer.call server, { :get_all }
      end

      def get_all(server, ids) do
        GenServer.call server, { :get_all, ids }
      end

      def get(server, id_subasta) do
        GenServer.call server, { :get, id_subasta }
      end

      def insert(server, datos_subasta) do
        GenServer.call server, { :insert, datos_subasta }
      end

      def update(server, id_subasta, datos_subasta) do
        GenServer.call server, { :update, id_subasta, datos_subasta }
      end

      def delete(server, id_subasta) do
        GenServer.call server, { :delete, id_subasta }
      end

      # -- Callbacks

      def init(:ok) do
        { :ok, {} }
      end

      def handle_call({ :get_all }, _from, _state) do
        all = IascTpSubastas.Repo.all(Subasta)
        allMaps = Enum.map all, fn(it) -> Map.from_struct it end

        { :reply, allMaps, _state }
      end

      def handle_call({ :get_all, ids}, _from, _state) do
        all = IascTpSubastas.Repo.all(Subasta)
        allMaps = Enum.map fn(it) -> Map.from_struct it end
        requiredIds = Enum.filter allMaps, fn(it) ->
          Enum.member? ids, it[:id]
        end

        { :reply, requiredIds, _state }
      end

      def handle_call({ :get, id_subasta }, _from, _state) do
        struct = IascTpSubastas.Repo.get!(Subasta, id_subasta)
        { :reply, Map.from_struct(struct), _state }
      end

      def handle_call({ :insert, datos_subasta }, _from, _state) do
        changeset = Subasta.changeset(%Subasta{}, datos_subasta)
        { :ok, struct } = IascTpSubastas.Repo.insert(changeset)
        result = Map.from_struct struct

        { :reply, result[:id], _state }
      end

      def handle_call({ :update, id_subasta, datos_subasta }, _from, _state) do
        subasta = IascTpSubastas.Repo.get!(Subasta, id_subasta)

        changeset = Subasta.changeset(subasta, datos_subasta)
        IascTpSubastas.Repo.update(changeset)

        { :reply, :ok, _state }
      end

      def handle_call({ :delete, id_subasta }, _from, _state) do
        subasta = IascTpSubastas.Repo.get!(Subasta, id_subasta)
        IascTpSubastas.Repo.delete!(subasta)

        { :reply, :ok, _state }
      end

      defoverridable [init: 1, handle_call: 3, get_all: 1, get_all: 2, get: 2, insert: 2, update: 3, delete: 2]
    end
  end
end