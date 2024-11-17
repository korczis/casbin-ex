defmodule Acx.Enforcer.RemoveMappingPolicy do
  @moduledoc """
  Enforcer 'remove_mapping_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Internal.RoleGroup
  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Removes the connection of the role to the permission and its corresponding
      mapping policy from storage.
      """
      @spec remove_mapping_policy(t(), {atom(), String.t(), String.t()}) ::
              t() | {:error, String.t()}
      def remove_mapping_policy(
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
             group <- RoleGroup.remove_inheritance(group, {role1, role2}),
             mappings <- Enum.reject(mappings, fn m -> m == mapping end),
             {:ok, adapter} <-
               PersistAdapter.remove_policy(adapter, {mapping_name, [role1, role2]}) do
          %{
            enforcer
            | role_groups: %{groups | mapping_name => group},
              mapping_policies: mappings,
              persist_adapter: adapter,
              env: %{env | mapping_name => RoleGroup.stub_2(group)}
          }
        else
          nil ->
            {:error, "mapping name not found: `#{mapping_name}`"}
        end
      end

      @spec remove_mapping_policy(t(), {atom(), String.t(), String.t(), String.t()}) ::
              t() | {:error, String.t()}
      def remove_mapping_policy(
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
             group <- RoleGroup.remove_inheritance(group, {role1, role2 <> dom}),
             mappings <- Enum.reject(mappings, fn m -> m == mapping end),
             {:ok, _adpater} <-
               PersistAdapter.remove_policy(adapter, {mapping_name, [role1, role2, dom]}) do
          %{
            enforcer
            | role_groups: %{groups | mapping_name => group},
              mapping_policies: mappings,
              persist_adapter: adapter,
              env: %{env | mapping_name => RoleGroup.stub_3(group)}
          }
        else
          nil ->
            {:error, "mapping name not found: `#{mapping_name}`"}
        end
      end

      def remove_mapping_policy!(
            %__MODULE__{} = enforcer,
            {mapping_name, role1, role2}
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
        case remove_mapping_policy(enforcer, {mapping_name, role1, role2}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end

      def remove_mapping_policy!(
            %__MODULE__{} = enforcer,
            {mapping_name, role1, role2, dom}
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) and is_binary(dom) do
        case remove_mapping_policy(enforcer, {mapping_name, role1, role2, dom}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end
    end
  end
end
