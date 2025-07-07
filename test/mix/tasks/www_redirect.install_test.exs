defmodule Mix.Tasks.WwwRedirect.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  setup do
    [
      igniter:
        test_project(
          files: %{
            "lib/test_web/endpoint.ex" => """
            defmodule BlogWeb.Endpoint do
              use Phoenix.Endpoint, otp_app: :blog

              @session_options [
                store: :cookie,
                key: "_app_key",
                signing_salt: "foobar",
                same_site: "Lax"
              ]

              socket("/live", Phoenix.LiveView.Socket,
                websocket: [connect_info: [:peer_data, session: @session_options]],
                longpoll: [connect_info: [session: @session_options]]
              )

              plug(Plug.Static,
                at: "/",
                from: :blog,
                gzip: false,
                only: BlogWeb.static_paths()
              )
            end
            """
          }
        )
        |> Igniter.Project.Application.create_app(Test.Application)
        |> apply_igniter!()
    ]
  end

  test "installation the plug", %{igniter: igniter} do
    igniter
    |> Igniter.compose_task("www_redirect.install", [])
    |> assert_has_patch("lib/test_web/endpoint.ex", """
    + |  plug(WwwRedirect, to: :non_www)
    + |
      |  plug(Plug.Static,
    """)
  end
end
