require Integer

defmodule Home do
  def start(map) do
    spawn fn -> loop(map) end
  end

  def loop(map) do
    receive do

      {:put, key, value} ->
          loop(Map.put(map, key, value))

      {:get, key, ref} ->
          send ref, {:ok, Map.get(map, key)}
          loop(map)

      {:delete, key} ->
          loop(Map.delete(map, key))

      {:accum, key, delta} ->
          loop(Map.update!(map, key, fn it -> it + delta end))
    end
  end
end