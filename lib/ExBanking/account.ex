defmodule ExBanking.Account do
  use Agent, restart: :temporary

  @doc """
  Starts a new account
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Get value from `account`
  """
  def get(account, currency) do
    Agent.get(account, fn map ->
      {:ok, Map.get(map, currency, 0)}
    end)
  end

  @doc """
  Handle `operation` into `account`, apply value to the current value for specified currency and account
  Returns :ok or {:error, :not_enough_money} in case of error
  """
  def handle(account, currency, value) do
    {:ok, current_value} = get(account, currency)
    if current_value + value < 0 do
      {:error, :not_enough_money}
    else
      Agent.update(account, fn map ->
        Map.update(map, currency, value, fn old_val -> old_val + value end)
      end)
      get(account, currency)
    end
  end
end
