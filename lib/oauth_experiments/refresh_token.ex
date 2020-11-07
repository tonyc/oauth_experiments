defmodule OauthExperiments.RefreshToken do
  use GenServer

  @ets_table :"refresh_token_data.dets"
  @token_key :prod_refresh_token

  @doc false
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)

    state = state |> Map.put(:ets_table, init_ets())

    schedule_refresh()
    schedule_fetch()

    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_data, state) do
    IO.puts "fetch_data()"

    state.ets_table
    |> :dets.lookup(@token_key)
    |> case do
      [prod_refresh_token: refresh_token] ->
        IO.puts "GET /stuff?token=#{refresh_token}"
      _ ->
        IO.puts "No refresh token, skipping fetch"
    end

    schedule_fetch()

    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh_token, state) do
    table = state.ets_table

    IO.puts("refresh_token(), table: #{inspect(table)}")

    refresh_token = UUID.uuid4()

    IO.puts "new token: #{inspect(refresh_token)}"

    :dets.insert(state.ets_table, {@token_key, refresh_token})

    schedule_refresh()

    {:noreply, state}
  end

  defp init_ets do
    {:ok, table} = :dets.open_file(@ets_table, [type: :set])

    table
  end

  defp schedule_refresh do
    self() |> Process.send_after(:refresh_token, 5000)
  end

  defp schedule_fetch do
    self() |> Process.send_after(:fetch_data, 1000)
  end

end
