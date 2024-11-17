defmodule Acx.Enforcer.ListMappingPolicies do
  @moduledoc """
  Enforcer 'list_mapping_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  defmacro __using__(_opts) do
    quote do
      @doc """
      Lists mapping policies and can take a filter that matches any position
      or displaced filter that matches positionally

      ## Examples

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "author", "reader"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "admin", "author"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "alice", "author"})
          ...> Enforcer.list_mapping_policies(e, ["author"])
          [
            {:g, "alice", "author"},
            {:g, "admin", "author"},
            {:g, "author", "reader"}
          ]

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "author", "reader"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "admin", "author"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "alice", "author"})
          ...> Enforcer.list_mapping_policies(e, 2, ["author"])
          [
            {:g, "alice", "author"},
            {:g, "admin", "author"}
          ]

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "author", "reader"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "admin", "author"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "alice", "author"})
          ...> Enforcer.list_mapping_policies(e, 1, ["admin", "author"])
          [
            {:g, "admin", "author"}
          ]
      """
      @spec list_mapping_policies(t(), integer(), keyword()) :: [mapping()]
      def list_mapping_policies(
            %__MODULE__{mapping_policies: mapping_policies},
            idx,
            criteria
          )
          when is_list(criteria) and is_integer(idx) do
        mapping_policies
        |> Enum.filter(fn mapping ->
          Tuple.to_list(mapping)
          |> Enum.slice(idx, length(criteria))
          |> Kernel.==(criteria)
        end)
      end

      @spec list_mapping_policies(Acx.Enforcer.t(), maybe_improper_list) :: [mapping()]
      def list_mapping_policies(
            %__MODULE__{mapping_policies: mapping_policies},
            criteria
          )
          when is_list(criteria) do
        mapping_policies
        |> Enum.filter(fn mapping ->
          list = Tuple.to_list(mapping)
          criteria |> Enum.all?(fn c -> c in list end)
        end)
      end

      @spec list_mapping_policies(Acx.Enforcer.t()) :: [mapping()]
      def list_mapping_policies(%__MODULE__{mapping_policies: mapping_policies}),
        do: mapping_policies
    end
  end
end
