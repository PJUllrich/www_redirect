defmodule WwwRedirectTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias WwwRedirect

  describe "init/1" do
    test "returns default options with :to set to :non_www" do
      opts = WwwRedirect.init([])
      assert opts == %{to: :non_www}
    end

    test "preserves existing options and adds defaults" do
      opts = WwwRedirect.init(some: "option")
      assert opts == %{some: "option", to: :non_www}
    end

    test "does not override explicitly set options" do
      opts = WwwRedirect.init(to: :non_www)
      assert opts == %{to: :non_www}
    end

    test "converts keyword list to map" do
      opts = WwwRedirect.init(to: :www, other: "value")
      assert opts == %{to: :www, other: "value"}
    end
  end

  describe "call/2 with :to set to :www" do
    test "redirects bare domain to www version with http and port" do
      conn = conn(:get, "http://example.com:443/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.example.com:443/path"]
      assert conn.halted == true
    end

    test "redirects bare domain to www version with https" do
      conn = conn(:get, "https://example.com/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://www.example.com/path"]
      assert conn.halted == true
    end

    test "does not redirect www domain" do
      conn = conn(:get, "http://www.example.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :www})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end

    test "does not redirect subdomains to www version" do
      conn = conn(:get, "http://api.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == nil
      assert conn.halted == false
    end

    test "does not redirect www domain with subdomain" do
      conn = conn(:get, "http://www.api.example.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :www})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end
  end

  describe "call/2 with :to set to :non_www" do
    test "redirects www domain to non-www version with http" do
      conn = conn(:get, "http://www.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com/path"]
      assert conn.halted == true
    end

    test "redirects www domain to non-www version with https" do
      conn = conn(:get, "https://www.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://example.com/path"]
      assert conn.halted == true
    end

    test "ignores subdomain to non-www version" do
      conn = conn(:get, "http://www.api.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == nil
      assert conn.halted == false
    end

    test "does not redirect bare domain" do
      conn = conn(:get, "http://example.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :non_www})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end

    test "does not redirect bare domain with subdomain" do
      conn = conn(:get, "http://api.example.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :non_www})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end

    test "handles case-insensitive www matching" do
      conn = conn(:get, "http://WWW.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com/path"]
      assert conn.halted == true
    end

    test "works with default options (no explicit :to)" do
      conn = conn(:get, "http://www.example.com/path")

      conn = WwwRedirect.call(conn, %{})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com/path"]
      assert conn.halted == true
    end
  end

  describe "edge cases" do
    test "handles domain that starts with www but is not www subdomain when redirecting to www" do
      conn = conn(:get, "http://wwwexample.com/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.wwwexample.com/path"]
      assert conn.halted == true
    end

    test "does not redirect domain that starts with www but is not www subdomain when redirecting to non-www" do
      conn = conn(:get, "http://wwwexample.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :non_www})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end

    test "ignores localhost when redirecting to www" do
      conn = conn(:get, "http://localhost/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == nil
      assert conn.halted == false
    end

    test "ignores www.localhost when redirecting to non-www" do
      conn = conn(:get, "http://www.localhost/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == nil
      assert conn.halted == false
    end

    test "ignores invalid :to option and passes through" do
      conn = conn(:get, "http://example.com/path")

      result_conn = WwwRedirect.call(conn, %{to: :invalid})

      assert result_conn == conn
      assert result_conn.status == nil
      assert result_conn.halted == false
    end
  end

  describe "protocol and port handling" do
    test "preserves https protocol when redirecting to www" do
      conn = conn(:get, "https://example.com/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://www.example.com/path"]
    end

    test "preserves https protocol when redirecting to non-www" do
      conn = conn(:get, "https://www.example.com/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["https://example.com/path"]
    end

    test "handles custom port when redirecting to www" do
      conn = conn(:get, "http://example.com:8080/path")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.example.com:8080/path"]
    end

    test "handles custom port when redirecting to non-www" do
      conn = conn(:get, "http://www.example.com:8080/path")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com:8080/path"]
    end

    test "omits default ports from redirect URLs" do
      # HTTP default port 80
      conn = conn(:get, "http://example.com:80/path")
      conn = WwwRedirect.call(conn, %{to: :www})
      assert get_resp_header(conn, "location") == ["http://www.example.com/path"]

      # HTTPS default port 443
      conn = conn(:get, "https://www.example.com:443/path")
      conn = WwwRedirect.call(conn, %{to: :non_www})
      assert get_resp_header(conn, "location") == ["https://example.com/path"]
    end

    test "preserves query parameters when redirecting to www" do
      conn = conn(:get, "http://example.com/search?q=test&page=2")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.example.com/search?q=test&page=2"]
    end

    test "preserves query parameters when redirecting to non-www" do
      conn = conn(:get, "http://www.example.com/search?q=test&page=2")

      conn = WwwRedirect.call(conn, %{to: :non_www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com/search?q=test&page=2"]
    end

    test "preserves complex paths with query parameters and custom ports" do
      conn = conn(:get, "http://example.com:3000/api/v1/users?active=true&sort=name")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302

      assert get_resp_header(conn, "location") == [
               "http://www.example.com:3000/api/v1/users?active=true&sort=name"
             ]
    end

    test "handles root path correctly" do
      conn = conn(:get, "http://example.com/")

      conn = WwwRedirect.call(conn, %{to: :www})

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.example.com/"]
    end
  end

  describe "integration test simulating Phoenix router usage" do
    test "works as a plug in a pipeline" do
      # Simulate how the plug would be used in a Phoenix router
      defmodule TestRouter do
        use Plug.Router

        plug(WwwRedirect, to: :www)
        plug(:match)
        plug(:dispatch)

        get "/test" do
          send_resp(conn, 200, "OK")
        end

        match _ do
          send_resp(conn, 404, "Not found")
        end
      end

      # Test bare domain gets redirected
      conn = conn(:get, "http://example.com/test")
      conn = TestRouter.call(conn, TestRouter.init([]))

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://www.example.com/test"]
      assert conn.halted == true

      # Test www domain passes through to the route
      conn = conn(:get, "http://www.example.com/test")
      conn = TestRouter.call(conn, TestRouter.init([]))

      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "works with non-www configuration in a pipeline" do
      defmodule TestRouterNonWww do
        use Plug.Router

        plug(WwwRedirect, to: :non_www)
        plug(:match)
        plug(:dispatch)

        get "/test" do
          send_resp(conn, 200, "OK")
        end

        match _ do
          send_resp(conn, 404, "Not found")
        end
      end

      # Test www domain gets redirected
      conn = conn(:get, "http://www.example.com/test")
      conn = TestRouterNonWww.call(conn, TestRouterNonWww.init([]))

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["http://example.com/test"]
      assert conn.halted == true

      # Test bare domain passes through to the route
      conn = conn(:get, "http://example.com/test")
      conn = TestRouterNonWww.call(conn, TestRouterNonWww.init([]))

      assert conn.status == 200
      assert conn.resp_body == "OK"
    end
  end
end
