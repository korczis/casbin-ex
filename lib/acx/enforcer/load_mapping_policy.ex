defmodule Acx.Enforcer.LoadMappingPolicy do
  @moduledoc """
  Enforcer 'load_mapping_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Internal.RoleGroup

  defmacro __using__(_opts) do
    quote do
      @spec load_mapping_policy(t(), {atom(), String.t(), String.t()}) ::
              t() | {:error, String.t()}
      defp load_mapping_policy(
             %__MODULE__{
               mapping_policies: mappings,
               role_groups: groups,
               env: env,
               persist_adapter: adapter
             } = enforcer,
             {mapping_name, role1, role2} = mapping
           )
           when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
        with group when not is_nil(group) <- Map.get(groups, mapping_name),
             false <- Enum.member?(mappings, mapping),
             group <- RoleGroup.add_inheritance(group, {role1, role2}) do
          new_enforcer = %{
            enforcer
            | role_groups: %{groups | mapping_name => group},
              mapping_policies: [mapping | mappings],
              persist_adapter: adapter,
              env: %{env | mapping_name => RoleGroup.stub_2(group)}
          }

          {:ok, new_enforcer}
        else
          nil ->
            {:error, "mapping name not found: `#{mapping_name}`"}

          true ->
            {:error, :already_existed}
        end
      end

      @spec load_mapping_policy(t(), {atom(), String.t(), String.t(), String.t()}) ::
              t() | {:error, String.t()}
      defp load_mapping_policy(
             %__MODULE__{
               mapping_policies: mappings,
               role_groups: groups,
               env: env,
               persist_adapter: adapter
             } = enforcer,
             {mapping_name, role1, role2, dom} = mapping
           )
           when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) and is_binary(dom) do
        with group when not is_nil(group) <- Map.get(groups, mapping_name),
             false <- Enum.member?(mappings, mapping),
             group <- RoleGroup.add_inheritance(group, {role1, role2 <> dom}) do
          new_enforcer = %{
            enforcer
            | role_groups: %{groups | mapping_name => group},
              mapping_policies: [mapping | mappings],
              persist_adapter: adapter,
              env: %{env | mapping_name => RoleGroup.stub_3(group)}
          }

          {:ok, new_enforcer}
        else
          nil ->
            {:error, "mapping name not found: `#{mapping_name}`"}

          true ->
            {:error, :already_existed}
        end
      end

      defp load_mapping_policy!(
             %__MODULE__{} = enforcer,
             {mapping_name, role1, role2}
           )
           when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
        case load_mapping_policy(enforcer, {mapping_name, role1, role2}) do
          {:error, :already_existed} ->
            enforcer

          {:error, reason} ->
            raise ArgumentError, message: reason

          {:ok, enforcer} ->
            enforcer
        end
      end

      defp load_mapping_policy!(
             %__MODULE__{} = enforcer,
             {mapping_name, role1, role2, dom}
           )
           when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) and is_binary(dom) do
        case load_mapping_policy(enforcer, {mapping_name, role1, role2, dom}) do
          {:error, :already_existed} ->
            enforcer

          {:error, reason} ->
            raise ArgumentError, message: reason

          {:ok, enforcer} ->
            enforcer
        end
      end
    end
  end
end
