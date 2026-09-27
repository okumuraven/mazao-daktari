defmodule MazaoDaktari.Repo do
  use Ecto.Repo,
    otp_app: :mazao_daktari,
    adapter: Ecto.Adapters.Postgres
end
