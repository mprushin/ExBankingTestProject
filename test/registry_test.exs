defmodule ExBanking.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    _ = start_supervised!({ExBanking.Registry, name: Context.Test})
    %{registry: Context.Test}
  end

  test "spawns accounts", %{registry: registry} do
    assert ExBanking.Registry.lookup(registry, "acc1") == {:error, :user_does_not_exist}

    ExBanking.Registry.create(registry, "acc1")
    assert {:ok, account} = ExBanking.Registry.lookup(registry, "acc1")

    ExBanking.Account.handle(account, "acc1", 1)
    assert ExBanking.Account.get(account, "acc1") == {:ok, 1}
  end

  test "removes accounts on exit", %{registry: registry} do
    ExBanking.Registry.create(registry, "acc1")
    {:ok, account} = ExBanking.Registry.lookup(registry, "acc1")
    Agent.stop(account)
    assert ExBanking.Registry.lookup(registry, "acc1") == {:error, :user_does_not_exist}
  end
end
