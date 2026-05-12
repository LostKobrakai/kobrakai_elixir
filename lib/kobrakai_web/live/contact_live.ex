defmodule KobrakaiWeb.ContactLive do
  use KobrakaiWeb, :live_view

  on_mount {KobrakaiWeb.Hooks, :current_path}
  on_mount {KobrakaiWeb.Hooks, :current_user}
  on_mount {KobrakaiWeb.Hooks, :localize}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid sm:grid-cols-2 gap-8 mb-64">
      <div>
        <p class="my-4">
          Ich freue mich auf Ihre Nachricht.
        </p>
        <table>
          <tbody>
            <tr>
              <th class="text-left w-24" scope="row">Telefon:</th>
              <td>
                <span class="tel">(+49)</span>
                <span class="tel">1522</span>
                <span class="tel">16</span>
                <span class="tel">16</span>
                <span class="tel">149</span>
              </td>
            </tr>
            <tr>
              <th class="text-left" scope="row">Email:</th>
              <td>benjaminmilde@kobrakai.de</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="prose dark:prose-invert">
        <p class="!my-4">Ich befinde mich in der Zeitzone <code>{@tz}</code>.</p>
        <p class="my-4">
          Es ist aktuell <time>{Localize.Time.to_string!(@now, format: :short)}</time> Uhr.
        </p>
        <.times_table now={@now} tz={@user_tz} />
        <p class="my-4">
          Zuletzt aktualisiert am
          <time>{Localize.Date.to_string!(@last_updated, format: :medium)}</time>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    tz = "Europe/Berlin"
    now = DateTime.now!(tz) |> DateTime.truncate(:second)
    last_updated = ~D[2026-05-04]

    {:ok,
     assign(socket,
       tz: tz,
       now: now,
       user_tz: get_connect_params(socket)["time_zone"],
       last_updated: last_updated
     )}
  end

  attr :now, DateTime, required: true
  attr :tz, :string, default: nil

  defp times_table(%{now: now, tz: tz} = assigns) do
    table_data =
      try do
        Enum.map(
          [
            ~T[09:00:00],
            ~T[12:00:00],
            ~T[18:00:00]
          ],
          fn time ->
            dt =
              case DateTime.new(DateTime.to_date(now), time, now.time_zone) do
                {:ok, dt} -> dt
                {:ambiguous, fdt, _ldt} -> fdt
                {:gap, fdt, _ldt} -> fdt
              end

            {dt, tz && DateTime.shift_zone!(dt, tz)}
          end
        )
      rescue
        _ -> nil
      end

    assigns = assign(assigns, table_data: table_data)

    ~H"""
    <table
      :if={@table_data}
      class={["!w-2/3 table-fixed", if(@now.time_zone == @tz, do: "opacity-25")]}
    >
      <thead>
        <tr>
          <th>{@now.time_zone}</th>
          <th>{@tz}</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={{my, user} <- @table_data}>
          <td><time>{Localize.Time.to_string!(my, format: :short)}</time></td>
          <td>
            <time :if={user}>
              {Localize.Time.to_string!(user, format: :short)}
            </time>
            <time :if={!user}>
              …
            </time>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
