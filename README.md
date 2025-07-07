# WwwRedirect

A Plug for redirecting HTTP requests between www and non-www versions of domains.

This library redirects requests between `www.example.com` and `example.com` based on your preference.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `www_redirect` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:www_redirect, "~> 0.1.0"}
  ]
end
```

## Install with [Igniter]()

```
mix igniter.install www_redirect
```

### Usage

```elixir
# Redirect to non-www (default behavior)
# E.g. `www.example.com` -> `example.com`
plug WwwRedirect
plug WwwRedirect, to: :non_www

# Redirect to www
# E.g. `https://example.com/path` -> `https://www.example.com/path`
plug WwwRedirect, to: :www
```

### Configuration Options

The plug accepts the following options:

- `:to` - Specifies the redirect target. Can be `:www` (default) or `:non_www`.
  - `:www` - Redirects bare domains to www versions (e.g., `example.com` → `www.example.com`)
  - `:non_www` - Redirects www domains to bare versions (e.g., `www.example.com` → `example.com`)

### Fixing Tests

Phoenix/Plug sets the `conn.host` to `www.example.com` by default, which might break your tests after adding `WwwRedirect` to your endpoint. Unfortunately, it's not possible to configure the `conn.host` in test globally since it's [a default value](https://github.com/elixir-plug/plug/blob/065976d85f3d079d4f22dde7897c2e7f67c596e0/lib/plug/adapters/test/conn.ex#L50) but you can update your `conn_case.ex` like this:

```elixir
# test/support/conn_case.ex

# ...
setup tags do
  # ...
  {:ok, conn: Phoenix.ConnTest.build_conn() |> Map.put(:host, "example.com")}
end
```

This will set the `conn.host` to `example.com` instead of `www.example.com` in all your tests. You can always set it back by running `Map.put(conn, :host, "www.example.com")` in your test.
