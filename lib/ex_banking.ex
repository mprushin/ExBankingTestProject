defmodule ExBanking do
  use Application

  @moduledoc """
  ExBanking module.
  Banking OTP Application
  """

  @doc """
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

  @doc """
  Function creates new user in the system
  New user has zero balance of any currency
  """
  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    ExBanking.Registry.create(ExBanking.Registry, user)
  end

  @doc """
  Increases user's balance in given `currency` by `amount` value
  Returns `new_balance` of the user in given format
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.handle(account, currency, amount)
    end
  end

  @doc """
  Decreases user's balance in given `currency` by `amount` value
  Returns `new_balance` of the user in given format
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.handle(account, currency, -amount)
    end
  end

  @doc """
  Returns 'balance' of the user in given format
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    with {:ok, account} <- ExBanking.Registry.lookup(ExBanking.Registry, user) do
      ExBanking.Account.get(account, currency)
    end
  end

  @doc """
  Decreases `from_user`'s balance in given `currency` by `amount` value
  Increases `to_user`'s balance in given `currency` by `amount` value
  Returns balance of `from_user` and `to_user` in given format
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    from_lookup_response = ExBanking.Registry.lookup(ExBanking.Registry, from_user)
    to_lookup_response = ExBanking.Registry.lookup(ExBanking.Registry, to_user)

    with {:ok, from_account} <- from_lookup_response,
         {:ok, to_account} <- to_lookup_response,
         {:ok, from_user_balance} <- ExBanking.Account.handle(from_account, currency, -amount),
         {:ok, to_user_balance} <- ExBanking.Account.handle(to_account, currency, amount) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:error, :user_does_not_exist} ->
        if from_lookup_response == {:error, :user_does_not_exist} do
          {:error, :sender_does_not_exist}
         else
           {:error, :receiver_does_not_exist}
        end
      err ->  err
    end
  end
end
