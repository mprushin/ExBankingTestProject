defmodule ExBanking.Account do
  use Agent

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
    Agent.get(account, fn map -> Map.get(map, currency, 0) end)
  end

  @doc """
  Handle `operation` into `account`, apply value to the current value for specified currency and account
  """
  def handle(account, currency, value) do
    if get(account, currency) + value < 0 do
      :not_enough_money
    else
      Agent.update(account, fn map ->
        Map.update(map, currency, value, fn old_val -> old_val + value end)
      end)
    end
  end
end
