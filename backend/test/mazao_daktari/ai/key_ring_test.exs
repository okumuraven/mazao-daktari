defmodule MazaoDaktari.AI.KeyRingTest do
  use ExUnit.Case, async: true

  alias MazaoDaktari.AI.KeyRing

  defp start_ring(pool) do
    name = :"key_ring_test_#{System.unique_integer([:positive])}"
    pid = start_supervised!({KeyRing, pool: pool, name: name})
    {pid, name}
  end

  test "checkout returns :empty for an unconfigured pool" do
    {_pid, name} = start_ring([])
    assert KeyRing.checkout(name) == :empty
  end

  test "checkout round-robins across the pool in order" do
    pool = [
      %{provider: :gemini, key: "g1"},
      %{provider: :gemini, key: "g2"},
      %{provider: :nvidia, key: "n1"}
    ]

    {_pid, name} = start_ring(pool)

    assert {:ok, %{key: "g1"}} = KeyRing.checkout(name)
    assert {:ok, %{key: "g2"}} = KeyRing.checkout(name)
    assert {:ok, %{key: "n1"}} = KeyRing.checkout(name)
    # wraps back to the start
    assert {:ok, %{key: "g1"}} = KeyRing.checkout(name)
  end

  test "a rate-limited entry is skipped by subsequent checkouts" do
    pool = [%{provider: :gemini, key: "g1"}, %{provider: :gemini, key: "g2"}]
    {_pid, name} = start_ring(pool)

    {:ok, entry} = KeyRing.checkout(name)
    assert entry.key == "g1"

    KeyRing.report_rate_limited(name, entry)
    # give the async cast time to land before the next call
    _ = :sys.get_state(name)

    assert {:ok, %{key: "g2"}} = KeyRing.checkout(name)
    assert {:ok, %{key: "g2"}} = KeyRing.checkout(name)
  end

  test "checkout returns :empty once every entry is in cooldown" do
    pool = [%{provider: :gemini, key: "g1"}, %{provider: :nvidia, key: "n1"}]
    {_pid, name} = start_ring(pool)

    KeyRing.report_rate_limited(name, %{provider: :gemini, key: "g1"})
    KeyRing.report_rate_limited(name, %{provider: :nvidia, key: "n1"})
    _ = :sys.get_state(name)

    assert KeyRing.checkout(name) == :empty
  end

  test "pool_size reflects the configured pool regardless of cooldowns" do
    pool = [%{provider: :gemini, key: "g1"}, %{provider: :nvidia, key: "n1"}]
    {_pid, name} = start_ring(pool)

    assert KeyRing.pool_size(name) == 2
    KeyRing.report_rate_limited(name, %{provider: :gemini, key: "g1"})
    _ = :sys.get_state(name)
    assert KeyRing.pool_size(name) == 2
  end
end
