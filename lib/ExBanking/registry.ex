defmodule ExBanking.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the account pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the account exists, `{:error, :user_does_not_exist}` otherwise.
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, account, _}] -> {:ok, account}
      [] -> {:error, :user_does_not_exist}
    end
  end

  @doc """
  Opens transaction for the account/accounts pids for `users` stored in `server`.

  Returns `:ok` if the transaction is opened, `{:error, :too_many_requests_to_user}` or `{:error, :user_does_not_exist}` otherwise.
  """
  def open_transaction(server, users) do
    GenServer.call(server, {:open_transaction, users})
  end

  @doc """
  Closes transaction for the account/accounts pids for `users` stored in `server`.

  Returns `:ok` if the transaction is closed, `{:error, :user_does_not_exist}` otherwise.
  """
  def close_transaction(server, users) do
    GenServer.call(server, {:close_transaction, users})
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

  def init(table) do
    names = :ets.new(table, [:set, :protected, :named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, refs}) do
    if Map.has_key?(names, name) do
      {:reply, Map.fetch(names, name), {names, refs}}
    else
      {:reply, {:error, :user_does_not_exist}, {names, refs}}
    end
  end

  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, _pid} ->
        {:reply, {:error, :user_already_exists}, {names, refs}}

      {:error, :user_does_not_exist} ->
        {:ok, account} = ExBanking.Account.start_link([])
        ref = Process.monitor(account)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, account, 0})
        {:reply, :ok, {names, refs}}
    end
  end

  def handle_call({:open_transaction, users}, _from, {names, refs}) do
    case users |> Enum.flat_map(fn user -> :ets.lookup(names, user) end) do
      lookup_result when lookup_result |> length != users |> length ->
        {:reply, {:error, :user_does_not_exist}, {names, refs}}

      lookup_result ->
        lookup_result_filtered = lookup_result |> Enum.filter(fn {_, _, ops_count} -> ops_count >= 10 end)
        if length(lookup_result_filtered)>0 do
          case users do
            [_] -> {:reply, {:error, :too_many_requests_to_user}, {names, refs}}
            [user_from, user_to] ->
              case List.first(lookup_result_filtered) do
                {^user_from, _, _} -> {:reply, {:error, :too_many_requests_to_sender}, {names, refs}}
                {^user_to, _, _} -> {:reply, {:error, :too_many_requests_to_receiver}, {names, refs}}
              end
          end


        else
          lookup_result
          |> Enum.map(fn {name, account, ops_count} ->
            :ets.insert(names, {name, account, ops_count + 1})
          end)

          {:reply, :ok, {names, refs}}
        end
    end
  end

  def handle_call({:close_transaction, users}, _from, {names, refs}) do
    case users |> Enum.flat_map(fn user -> :ets.lookup(names, user) end) do
      lookup_result when lookup_result |> length != users |> length ->
        {:reply, {:error, :user_does_not_exist}, {names, refs}}

      lookup_result ->
        lookup_result
        |> Enum.map(fn {name, account, ops_count} ->
          :ets.insert(names, {name, account, ops_count - 1})
        end)

        {:reply, :ok, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
