defmodule ExBanking.Registry do
  use GenServer

    ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the account pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a account associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:lookup, name}, _from, names) do
    if Map.has_key?(names, name) do
      {:reply, {:ok, Map.fetch(names, name)}, names}
    else
      {:reply, {:error, :user_does_not_exist}, names}
    end

  end

  def handle_call({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:reply, {:error, :user_already_exists}, names}
    else
      {:ok, account} = ExBanking.Account.start_link([])
      {:reply, :ok, Map.put(names, name, account)}
    end
  end

end
