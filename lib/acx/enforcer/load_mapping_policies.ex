defmodule Acx.Enforcer.LoadMappingPolicies do
  @moduledoc """
  Enforcer 'load_mapping_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model
  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Loads mapping policies from the persist adapter and adds them to the enforcer.
      """
      def load_mapping_policies!(%__MODULE__{model: m, persist_adapter: adapter} = enforcer) do
        case PersistAdapter.load_policies(adapter) do
          {:ok, policies} ->
            policies
            |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
            |> Enum.filter(fn [key | _] -> Model.has_role_mapping?(m, key) end)
            |> Enum.map(fn
              [name, r1, r2] -> {name, r1, r2}
              [name, r1, r2, d] -> {name, r1, r2, d}
            end)
            |> Enum.reduce(enforcer, &load_mapping_policy!(&2, &1))
        end
      end

      @doc """
      Loads mapping policies from a csv file and adds them to the enforcer.

      A valid mapping policies file must be a `*.csv` file and each line of
      that file should have the following format:

        `mapping_name, role1, role2`

      where `mapping_name` is one of the names given in the config file under
      the role definition section.

      Note that you don't have to have a separate mapping policies file, instead
      you could just put all of your mapping policies inside your policy rules
      file.
      """
      def load_mapping_policies!(%__MODULE__{model: m} = enforcer, fname)
          when is_binary(fname) do
        fname
        |> File.read!()
        |> String.split("\n", trim: true)
        |> Enum.map(&String.split(&1, ~r{,\s*}))
        |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
        |> Enum.filter(fn [key | _] -> Model.has_role_mapping?(m, key) end)
        |> Enum.map(fn
          [name, r1, r2] -> {name, r1, r2}
          [name, r1, r2, d] -> {name, r1, r2, d}
        end)
        |> Enum.reduce(enforcer, &load_mapping_policy!(&2, &1))
      end
    end
  end
end
