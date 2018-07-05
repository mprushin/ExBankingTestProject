defmodule ExBanking.ValidatorTest do
  use ExUnit.Case, async: true
  import ExBanking.Validator

  test "validate_string success" do
    assert validate_string("abc") == :ok
  end

  test "validate_string fail" do
    assert validate_string([1, 2, 3]) == {:error, :wrong_arguments}
  end

  test "validate_money success" do
    assert validate_money(1) == :ok
    assert validate_money(1.22) == :ok
    assert validate_money(1.22000) == :ok
  end

  test "validate_money fail" do
    assert validate_money(1.222) ==  {:error, :wrong_arguments}
    assert validate_money(-1) ==  {:error, :wrong_arguments}
    assert validate_money("1,222") ==  {:error, :wrong_arguments}
  end
end
