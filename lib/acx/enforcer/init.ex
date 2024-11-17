defmodule Acx.Enforcer.Init do
  @moduledoc """
  Enforcer 'init' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Internal.RoleGroup
  alias Acx.Model
  alias Acx.Persist.PersistAdapter
  alias Acx.Persist.ReadonlyFileAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Loads and contructs a model from the given config file `cfile`.
      """
      @spec init(String.t(), PersistAdapter.t()) :: {:ok, t()} | {:error, String.t()}
      def init(cfile, adapter) when is_binary(cfile) do
        case init(cfile) do
          {:error, reason} ->
            {:error, reason}

          {:ok, module} ->
            module = set_persist_adapter(module, adapter)
            {:ok, module}
        end
      end

      @doc """
      Loads and contructs a model from the given config file `cfile`.
      """
      @spec init(String.t()) :: {:ok, t()} | {:error, String.t()}
      def init(cfile) when is_binary(cfile) do
        case Model.init(cfile) do
          {:error, reason} ->
            {:error, reason}

          {:ok, %Model{role_mappings: role_mappings} = model} ->
            role_groups =
              role_mappings
              |> Enum.map(fn m -> {m, RoleGroup.new(m)} end)

            # TODO: What if one of the mapping name in `role_mappings`
            # conflicts with some built-in function names?
            env =
              role_groups
              |> Enum.map(fn {name, g} -> {name, RoleGroup.stub_2(g)} end)
              |> Map.new()
              |> Map.merge(init_env())

            {
              :ok,
              %__MODULE__{
                model: model,
                role_groups: role_groups |> Map.new(),
                persist_adapter: create_adapter(),
                env: env
              }
            }
        end
      end

      def create_adapter() do
        Application.get_env(:acx, :adapter, Acx.Persist.ReadonlyFileAdapter)
        |> create_adapter()
      end

      def create_adapter(nil) do
        Logger.error("PersistentAdapter configuration is invalid!")
        {:error, :invalid_configuration}
      end

      def create_adapter(module) when is_atom(module) do
        create_adapter({module, :new, []})
      end

      def create_adapter({module, args}) do
        create_adapter({module, :new, args})
      end

      def create_adapter({module, function, args} = adapter) do
        Logger.debug("#{__MODULE__} Creating PersistentAdapter - #{inspect(adapter)}")
        apply(module, function, args)
      end
    end
  end
end
