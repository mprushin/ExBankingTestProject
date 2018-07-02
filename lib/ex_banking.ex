defmodule ExBanking do
  use Application

  @moduledoc """
  ExBanking test module.
  """

  @doc """


  ## Examples


  """
  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  def start(_type, _args) do
    ExBanking.Supervisor.start_link(name: ExBanking.Supervisor)
  end

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    ExBanking.Registry.create(ExBanking.Registry, user)
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.handle(account, currency, amount)
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.handle(account, currency, -amount)
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.get(account, currency)
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    with {:ok, from_account} <- ExBanking.Registry.lookup(ExBanking.Registry, from_user),
         {:ok, to_account} <- ExBanking.Registry.lookup(ExBanking.Registry, to_user),
         {:ok, from_user_balance} <- ExBanking.Account.handle(from_account, currency, -amount),
         {:ok, to_user_balance} <- ExBanking.Account.handle(to_account, currency, amount) do
      {:ok, from_user_balance, to_user_balance}
    end
  end
end
