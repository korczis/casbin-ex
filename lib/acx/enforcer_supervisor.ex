# lib/acx/enforcer_supervisor/behaviour.ex
defmodule Acx.EnforcerSupervisor.Behaviour do
  @moduledoc """
  Behaviour module that defines the EnforcerSupervisor interface
  """

  defmacro __using__(opts \\ []) do
    server_module = Keyword.get(opts, :server_module)

    quote do
      use DynamicSupervisor

      require Logger

      def start_link(args \\ []) do
        DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
      end

      def init(args) do
        DynamicSupervisor.init(strategy: :one_for_one)
      end

      @doc """
      Starts a new `Enforcer` process and supervises it
      """
      def start_enforcer(ename, cfile) do
        child_spec = unquote(server_module).child_spec(ename, cfile)

        Logger.debug("Starting enforcer, child_spec: #{inspect(child_spec)}")
        DynamicSupervisor.start_child(__MODULE__, child_spec)
      end

      defoverridable [
        start_link: 1,
        init: 1,
        start_enforcer: 2
      ]

      unquote(Macro.expand(opts, __ENV__))
    end
  end
end

defmodule Acx.EnforcerSupervisor do
  @moduledoc """
  Default implementation of the EnforcerSupervisor
  """

  use Acx.EnforcerSupervisor.Behaviour

  defmacro __using__(opts \\ []) do
    quote() do
      use Acx.EnforcerSupervisor.Behaviour, unquote(opts)
    end
  end
end
