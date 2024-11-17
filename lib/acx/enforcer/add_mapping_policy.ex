defmodule Acx.Enforcer.AddMappingPolicy do
  @moduledoc """
  Enforcer 'add_mapping_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Makes `role1` inherit from (or has role ) `role2`. The `mapping_name`
      should be one of the names given in the model configuration file under
      the `role_definition` section. For example if your role definition look
      like this:

        [role_definition]
        g = _, _

      then `mapping_name` should be the atom `:g`.

      ## Examples

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> %Enforcer{env: %{g: g}} = e
          ...> false = g.("admin", "bob")
          ...> g.("bob", "admin")
          true

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> e = e |> Enforcer.add_mapping_policy({:g, "admin", "author"})
          ...> %Enforcer{env: %{g: g}} = e
          ...> g.("bob", "author")
          true

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> invalid_mapping = {:g2, "bob", "admin"}
          ...> {:error, msg} = e |> Enforcer.add_mapping_policy(invalid_mapping)
          ...> msg
          "mapping name not found: `g2`"

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          ...> e |> Enforcer.add_mapping_policy({:g, "bob", "admin"})
          {:error, :already_existed}
      """
      @spec add_mapping_policy(t(), {atom(), String.t(), String.t()}) ::
              t() | {:error, String.t()}
      def add_mapping_policy(
            %__MODULE__{persist_adapter: adapter} = enforcer,
            {mapping_name, role1, role2} = mapping
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
        with {:ok, new_enforcer} <- load_mapping_policy(enforcer, mapping),
             {:ok, adapter} <- PersistAdapter.add_policy(adapter, {mapping_name, [role1, role2]}) do
          %{new_enforcer | persist_adapter: adapter}
        else
          {:error, reason} ->
            {:error, reason}
        end
      end

      def add_mapping_policy(
            %__MODULE__{persist_adapter: adapter} = enforcer,
            {mapping_name, role1, role2, dom} = mapping
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) and is_binary(dom) do
        with {:ok, new_enforcer} <- load_mapping_policy(enforcer, mapping),
             {:ok, adapter} <-
               PersistAdapter.add_policy(adapter, {mapping_name, [role1, role2, dom]}) do
          %{new_enforcer | persist_adapter: adapter}
        else
          {:error, reason} ->
            {:error, reason}
        end
      end

      def add_mapping_policy!(
            %__MODULE__{} = enforcer,
            {mapping_name, role1, role2}
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
        case add_mapping_policy(enforcer, {mapping_name, role1, role2}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end

      def add_mapping_policy!(
            %__MODULE__{} = enforcer,
            {mapping_name, role1, role2, dom}
          )
          when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) and is_binary(dom) do
        case add_mapping_policy(enforcer, {mapping_name, role1, role2, dom}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end
    end
  end
end
