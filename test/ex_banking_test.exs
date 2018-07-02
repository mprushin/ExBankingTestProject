defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "greets the world" do
    assert ExBanking.create_user("Mike") == :ok
  end
end
