defmodule ExBanking.Validator do
  def validate_string(str) do
    if(is_bitstring(str)) do
      :ok
    else
      {:error, :wrong_arguments}
    end
  end

  def validate_money(amount) do
    if(is_number(amount) and amount > 0 and Float.ceil(amount / 1, 2) == amount) do
      :ok
    else
      {:error, :wrong_arguments}
    end
  end
end
