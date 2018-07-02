defmodule ExBanking.AccountTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, account} = ExBanking.Account.start_link([])
    %{account: account}
  end

  test "new account has 0 value in any currency", %{account: account} do
    assert ExBanking.Account.get(account, "rur") == 0
    assert ExBanking.Account.get(account, "usd") == 0
  end

  test "account handle operation", %{account: account} do
    assert ExBanking.Account.get(account, "rur") == 0

    ExBanking.Account.handle(account, "rur", 10)
    assert ExBanking.Account.get(account, "rur") == 10

    ExBanking.Account.handle(account, "rur", -5)
    assert ExBanking.Account.get(account, "rur") == 5
  end

  test "account without enough money", %{account: account} do
    assert ExBanking.Account.get(account, "rur") == 0

    assert ExBanking.Account.handle(account, "rur", -10) == :not_enough_money
  end
end
