defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  test "main operations" do
    ExBanking.create_user("test")
    ExBanking.create_user("test2")

    assert {:ok, 0} = ExBanking.get_balance("test", "rur")
    assert {:ok, 10} = ExBanking.deposit("test", 10, "rur")
    assert {:ok, 5} = ExBanking.withdraw("test", 5, "rur")
    assert {:ok, 2, 3} = ExBanking.send("test", "test2", 3, "rur")
  end

  test "not enough money" do
    ExBanking.create_user("test3")

    assert {:error, :not_enough_money} = ExBanking.withdraw("test3", 1, "rur")
  end

  test "user already exists" do
    ExBanking.create_user("test4")
    assert {:error, :user_already_exists} = ExBanking.create_user("test4")
  end

  test "user doesn't exist" do
    assert {:error, :user_does_not_exist} =
             ExBanking.get_balance("user which is doesn't exist", "rur")
  end

  test "sender/receiver does not exist" do
    ExBanking.create_user("test5")
    ExBanking.deposit("test5", 100, "rur")

    assert {:error, :sender_does_not_exist} =
             ExBanking.send("user which is doesn't exist", "test5", 10, "rur")

    assert {:error, :receiver_does_not_exist} =
             ExBanking.send("test5", "user which is doesn't exist", 10, "rur")
  end

  test "send - not enough money" do
    ExBanking.create_user("test6")
    ExBanking.create_user("test7")
    ExBanking.deposit("test6", 10, "rur")

    assert {:error, :not_enough_money} = ExBanking.send("test6", "test7", 100, "rur")
  end

  test "send works" do
    ExBanking.create_user("test8")
    ExBanking.create_user("test9")
    ExBanking.deposit("test8", 10, "rur")

    assert {:ok, 5, 5} = ExBanking.send("test8", "test9", 5, "rur")
  end

  test "10 request in queue" do
    ExBanking.create_user("test10")

    for _ <- 0..10 do
      parent = self()

      Task.start(fn ->
        message = ExBanking.get_balance("test10", "rur")
        send(parent, {:test10, message})
      end)
    end

    message_list =
      for _ <- 0..10 do
        receive do
          {:test10, message} ->
            message
        end
      end

    # IO.put(inspect message_list)
    assert message_list
           |> Enum.any?(fn message -> {:error, :too_many_requests_to_user} = message end) == true

  end

end
