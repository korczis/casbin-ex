defmodule Acx.Enforcer.SavePolicies do
  @moduledoc """
  Enforcer 'save_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Saves the updated list of policies using the configured PersistAdapter. This function
      is useful for adapters that don't do incremental add/removes for policies or for loading
      policies from one source and saving to another after changing adapters.
      """
      def save_policies(
            %__MODULE__{
              persist_adapter: adapter,
              policies: policies,
              mapping_policies: mapping_policies
            } = enforcer
          ) do

        Logger.debug("Saving policies - #{inspect(enforcer)}")

        policies =
          mapping_policies
          |> Enum.map(&Tuple.to_list(&1))
          |> Enum.map(fn [key | attrs] -> %{key: key, attrs: attrs} end)
          |> Enum.concat(policies)

        case PersistAdapter.save_policies(adapter, policies) do
          {:error, errors} -> {:error, errors}
          {:ok, adapter} -> %{enforcer | persist_adapter: adapter}
        end
      end

      def save_policies!(%__MODULE__{} = enforcer) do
        case save_policies(enforcer) do
          {:error, _} ->
            raise RuntimeError, message: "save failed"

          enforcer ->
            enforcer
        end
      end
    end
  end
end
