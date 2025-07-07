defmodule Mix.Tasks.WwwRedirect.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  setup do
    [
      igniter:
        test_project(
          files: %{
            "lib/test_web/endpoint.ex" => """
            defmodule TestWeb.Endpoint do
              use Phoenix.Endpoint, otp_app: :test

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

              # Serve at "/" the static files from "priv/static" directory.
              #
              # You should set gzip to true if you are running phx.digest
              # when deploying your static files in production.
              plug(Plug.Static,
                at: "/",
                from: :test,
                gzip: false,
                only: TestWeb.static_paths()
              )

              plug(TestWeb.Router)
            end
            """,
            "lib/test_web/router.ex" => """
            defmodule TestWeb.Router do
              use Phoenix.Router

              scope "/", TestWeb do
                get "/", PageController, :index
              end
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
      |  # Serve at "/" the static files from "priv/static" directory.
    """)
  end
end
