defmodule KaspoExTest do
  use ExUnit.Case
  doctest KaspoEx

  test "greets the world" do
    assert KaspoEx.hello() == :world
  end
end
