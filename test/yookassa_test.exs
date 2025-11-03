defmodule YookassaTest do
  use ExUnit.Case
  doctest Yookassa

  test "greets the world" do
    assert Yookassa.hello() == :world
  end
end
