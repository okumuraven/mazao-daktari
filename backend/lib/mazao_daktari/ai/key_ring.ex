defmodule MazaoDaktari.AI.KeyRing do
  @moduledoc """
  Round-robins across a pool of AI provider API keys so a single free-tier
  quota/rate-limit doesn't take the whole diagnosis feature down.

  The pool is built once at startup from config (see `MazaoDaktari.AI.KeyRing.pool_from_env/0`):
  every configured Gemini key, followed by the NVIDIA key if present. Each
  entry is `%{provider: :gemini | :nvidia, key: String.t()}`.

  `checkout/0` returns the next entry that is not currently in cooldown,
  advancing a shared round-robin cursor. `report_rate_limited/1` puts an
  entry in cooldown for `@cooldown_ms` after it returns HTTP 429, so it's
  skipped by subsequent checkouts until the cooldown expires.

  Kept as a GenServer (not an Agent/ETS) so the round-robin index advances
  atomically under concurrent requests — two simultaneous diagnoses must
  not be handed the same key when a fresh one is available.
  """

  use GenServer

  @cooldown_ms 60_000

  defstruct pool: [], cursor: 0, cooldowns: %{}

  # Client API

  def start_link(opts) do
    pool = Keyword.get(opts, :pool, pool_from_env())
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, pool, name: name)
  end

  @doc "Returns `{:ok, %{provider: atom, key: String.t()}}` or `:empty` if the whole pool is in cooldown or unconfigured."
  def checkout(server \\ __MODULE__) do
    GenServer.call(server, :checkout)
  end

  @doc "Marks this provider/key pair as rate-limited; it's skipped by checkout/0 for #{@cooldown_ms}ms."
  def report_rate_limited(server \\ __MODULE__, entry)

  def report_rate_limited(server, %{provider: provider, key: key}) do
    GenServer.cast(server, {:report_rate_limited, provider, key})
  end

  @doc "How many pool entries are configured, regardless of cooldown state — used to bound retry loops."
  def pool_size(server \\ __MODULE__) do
    GenServer.call(server, :pool_size)
  end

  @doc false
  def pool_from_env do
    gemini_keys =
      System.get_env("GEMINI_API_KEYS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&%{provider: :gemini, key: &1})

    nvidia_entry =
      case System.get_env("NVIDIA_API_KEY") do
        nil -> []
        "" -> []
        key -> [%{provider: :nvidia, key: String.trim(key)}]
      end

    gemini_keys ++ nvidia_entry
  end

  # Server callbacks

  @impl true
  def init(pool), do: {:ok, %__MODULE__{pool: pool}}

  @impl true
  def handle_call(:pool_size, _from, state), do: {:reply, length(state.pool), state}

  @impl true
  def handle_call(:checkout, _from, %__MODULE__{pool: []} = state) do
    {:reply, :empty, state}
  end

  def handle_call(:checkout, _from, state) do
    now = System.monotonic_time(:millisecond)

    live_cooldowns =
      Enum.reject(state.cooldowns, fn {_key, until} -> until <= now end) |> Map.new()

    size = length(state.pool)

    case find_available(state.pool, live_cooldowns, state.cursor, size, 0) do
      {:ok, entry, next_cursor} ->
        {:reply, {:ok, entry}, %{state | cursor: next_cursor, cooldowns: live_cooldowns}}

      :none ->
        {:reply, :empty, %{state | cooldowns: live_cooldowns}}
    end
  end

  @impl true
  def handle_cast({:report_rate_limited, provider, key}, state) do
    until = System.monotonic_time(:millisecond) + @cooldown_ms
    cooldowns = Map.put(state.cooldowns, {provider, key}, until)
    {:noreply, %{state | cooldowns: cooldowns}}
  end

  defp find_available(_pool, _cooldowns, _cursor, size, tried) when tried >= size, do: :none

  defp find_available(pool, cooldowns, cursor, size, tried) do
    index = rem(cursor, size)
    entry = Enum.at(pool, index)

    if Map.has_key?(cooldowns, {entry.provider, entry.key}) do
      find_available(pool, cooldowns, cursor + 1, size, tried + 1)
    else
      {:ok, entry, cursor + 1}
    end
  end
end
