defmodule Acx.Enforcer.RemoveFilteredPolicy do
  @moduledoc """
  Enforcer 'remove_filtered_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Removes policies with attributes that match the filter fields
      starting at the index.any()

        # Examples
            iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
            ...> {:ok, e} = Enforcer.init(cfile)
            ...> e = Enforcer.add_policy(e, {:p, ["admin", "blog_post", "write"]})
            ...> e = Enforcer.add_policy(e, {:p, ["reader", "blog_post", "read"]})
            ...> e = Enforcer.add_policy(e, {:p, ["admin", "blog_post", "delete"]})
            ...> e = Enforcer.remove_filtered_policy(e, :p, 0, ["admin"])
            ...> Enforcer.list_policies(e)
            [
              %Acx.Model.Policy{
                key: :p,
                attrs: [sub: "reader", obj: "blog_post", act: "read", eft: "allow"]
              }
            ]


            iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
            ...> {:ok, e} = Enforcer.init(cfile)
            ...> e = Enforcer.add_policy(e, {:p, ["admin", "blog_post", "write"]})
            ...> e = Enforcer.add_policy(e, {:p, ["reader", "blog_post", "read"]})
            ...> e = Enforcer.add_policy(e, {:p, ["admin", "blog_post", "delete"]})
            ...> e = Enforcer.add_policy(e, {:p, ["reader", "comment", "read"]})
            ...> e = Enforcer.remove_filtered_policy(e, :p, 1, ["blog_post"])
            ...> Enforcer.list_policies(e)
            [
              %Acx.Model.Policy{
                key: :p,
                attrs: [sub: "reader", obj: "comment", act: "read", eft: "allow"]
              }
            ]
      """
      @spec remove_filtered_policy(t(), atom(), integer(), keyword()) :: t() | {:error, any()}
      def remove_filtered_policy(
            %__MODULE__{policies: policies, persist_adapter: adapter} = enforcer,
            req_key,
            idx,
            req
          )
          when is_atom(req_key) and is_integer(idx) and is_list(req) do
        filtered_policies =
          policies
          |> Enum.reject(fn %{key: key, attrs: attrs} ->
            attr_values =
              attrs
              |> Enum.map(&elem(&1, 1))
              |> Enum.slice(idx, length(req))

            [key | attr_values] === [req_key | req]
          end)

        {:ok, adapter} = PersistAdapter.remove_filtered_policy(adapter, req_key, idx, req)
        %{enforcer | policies: filtered_policies, persist_adapter: adapter}
      end

      @spec remove_filtered_policy!(t(), atom(), integer(), keyword()) :: t() | {:error, any()}
      def remove_filtered_policy!(
            %__MODULE__{} = enforcer,
            req_key,
            idx,
            req
          )
          when is_atom(req_key) and is_integer(idx) and is_list(req) do
        case remove_filtered_policy(enforcer, req_key, idx, req) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end
    end
  end
end
