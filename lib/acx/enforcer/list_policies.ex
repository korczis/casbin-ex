defmodule Acx.Enforcer.ListPolicies do
  @moduledoc """
  Enforcer 'list_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  defmacro __using__(_opts) do
    quote do
      @doc """
      Returns a list of policies in the given enforcer that match the
      given criteria.

      For example, in order to get all policy rules with the key `:p`
      and the `act` attribute is `"read"`, you can call `list_policies/2`
      function with second argument:

      `%{key: :p, act: "read"}`

      By passing in an empty map or an empty list to the second argument
      of the function `list_policies/2`, you'll effectively get all policy
      rules in the enforcer (without filtered).

      ## Examples

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> pfile = "../../test/data/acl.csv" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.load_policies!(pfile)
          ...> e |> Enforcer.list_policies(%{sub: "peter"})
          [
          %Acx.Model.Policy{
            attrs: [sub: "peter", obj: "blog_post", act: "read", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "peter", obj: "blog_post", act: "modify", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "peter", obj: "blog_post", act: "create", eft: "allow"],
            key: :p
          }
          ]
      """
      @spec list_policies(t(), map() | keyword()) :: [Model.Policy.t()]
      def list_policies(
            %__MODULE__{policies: policies},
            criteria
          )
          when is_map(criteria) or is_list(criteria) do
        policies
        |> Enum.filter(fn %{key: key, attrs: attrs} ->
          list = [{:key, key} | attrs]
          criteria |> Enum.all?(fn c -> c in list end)
        end)
      end

      def list_policies(%__MODULE__{policies: policies}), do: policies
    end
  end
end
