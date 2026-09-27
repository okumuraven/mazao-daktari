defmodule MazaoDaktari.DataCase do
  @moduledoc """
  Test case for tests that need `MazaoDaktari.Repo` access, wrapping each
  test in a sandboxed, rolled-back transaction.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias MazaoDaktari.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MazaoDaktari.DataCase
    end
  end

  setup tags do
    MazaoDaktari.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MazaoDaktari.Repo, shared: not tags[:async])
    ExUnit.Callbacks.on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
