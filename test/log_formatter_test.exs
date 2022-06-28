defmodule LogFormatterTest do
  use ExUnit.Case
  doctest LogFormatter

  test "greets the world" do
    assert LogFormatter.hello() == :world
  end
end
