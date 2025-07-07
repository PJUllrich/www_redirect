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

