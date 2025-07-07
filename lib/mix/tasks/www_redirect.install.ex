defmodule Mix.Tasks.WwwRedirect.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Installs WwwRedirect into your Endpoint."
  end

  @spec example() :: String.t()
  def example do
    "mix www_redirect.install"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Installs the WwwRedirect Plug in your Endpoint.

    ## Example

    ```sh
    #{example()}
    ```

    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.WwwRedirect.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :www_redirect,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      {igniter, routers} =
        Igniter.Libs.Phoenix.list_routers(igniter)

      {igniter, endpoints} =
        Enum.reduce(routers, {igniter, []}, fn router, {igniter, endpoints} ->
          {igniter, new_endpoints} = Igniter.Libs.Phoenix.endpoints_for_router(igniter, router)
          {igniter, endpoints ++ new_endpoints}
        end)

      if endpoints != [] do
        Enum.reduce(endpoints, igniter, fn endpoint, igniter ->
          setup_endpoint(igniter, endpoint)
        end)
      else
        Mix.shell().error("Could not find any endpoints to install the WwwRedirect plug.")
        exit({:shutdown, 1})
      end
    end

    defp setup_endpoint(igniter, endpoint) do
      Igniter.Project.Module.find_and_update_module!(igniter, endpoint, fn zipper ->
        zipper
        |> Igniter.Code.Common.within(&add_plug/1)
        |> then(&{:ok, &1})
      end)
    end

    defp add_plug(zipper) do
      with :error <-
             Igniter.Code.Function.move_to_function_call_in_current_scope(
               zipper,
               :plug,
               [1, 2],
               &Igniter.Code.Function.argument_equals?(&1, 0, WwwRedirect)
             ),
           {:ok, zipper} <-
             Igniter.Code.Function.move_to_function_call_in_current_scope(
               zipper,
               :plug,
               [1, 2],
               &Igniter.Code.Function.argument_equals?(&1, 0, Plug.Static)
             ) do
        Igniter.Code.Common.add_code(zipper, "plug WwwRedirect, to: :non_www", placement: :before)
      else
        _ ->
          zipper
      end
    end
  end
else
  defmodule Mix.Tasks.WwwRedirect.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'www_redirect.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
