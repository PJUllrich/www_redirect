defmodule WwwRedirect do
  @moduledoc """
  Redirects an HTTP request from WWW to Non-WWW and vice versa.

  Heavily inspired by: https://stackoverflow.com/a/36509559

  ## Options

  * `:to` - Specifies the redirect target. Can be `:www` or `:non_www` (default).
    - `:www` - Redirects bare domains to www versions (e.g., example.com -> www.example.com)
    - `:non_www` (default) - Redirects www domains to bare versions (e.g., www.example.com -> example.com)

  ## Examples

      # Redirect to non-www
      plug WwwRedirect
      plug WwwRedirect, to: :non_www

      # Redirect to www
      plug WwwRedirect, to: :www

  """

  import Plug.Conn

  def init(opts) do
    opts
    |> Keyword.put_new(:to, :non_www)
    |> Enum.into(%{})
  end

  def call(conn, opts) do
    redirect_to = Map.get(opts, :to, :non_www)
    subdomain = get_subdomain(conn.host)

    cond do
      redirect_to == :www and subdomain == :non_www ->
        conn
        |> Phoenix.Controller.redirect(external: www_url(conn))
        |> halt()

      redirect_to == :non_www and subdomain == :www ->
        conn
        |> Phoenix.Controller.redirect(external: non_www_url(conn))
        |> halt()

      true ->
        conn
    end
  end

  defp www_url(conn) do
    request_url = request_url(conn)
    String.replace(request_url, ~r/^(https?:\/\/)/i, "\\1www.")
  end

  defp non_www_url(conn) do
    request_url = request_url(conn)
    String.replace(request_url, ~r/^(https?:\/\/)www\./i, "\\1")
  end

  defp get_subdomain(host) do
    parts = host |> String.downcase() |> String.split(".")

    case parts do
      # bare domain like "example.com"
      [_, _] -> :non_www
      # www bare domain like "www.example.com"
      ["www", _, _] -> :www
      # everything else, subdomains like "api.example.com"
      _ -> :other
    end
  end
end
