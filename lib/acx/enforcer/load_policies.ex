defmodule Acx.Enforcer.LoadPolicies do
  @moduledoc """
  Enforcer 'load_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model
  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Loads policy rules from external file given by the name `pfile` and
      adds them to the enforcer.

      A valid policy file should be a `*.csv` file, in which each line must
      have the following format:

        `pkey, attr1, attr2, attr3`

      in which `pkey` is the key of the policy rule, this key must match the
      policy definition in the enforcer. `attr1`, `attr2`, ... are the
      value of attributes specified in the policy definition.

      ## Examples

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> pfile = "../../test/data/acl.csv" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> e = e |> Enforcer.load_policies!(pfile)
          ...> %Enforcer{policies: policies} = e
          ...> policies
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
          },
          %Acx.Model.Policy{
            attrs: [sub: "bob", obj: "blog_post", act: "read", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "alice", obj: "blog_post", act: "read", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "alice", obj: "blog_post", act: "modify", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "alice", obj: "blog_post", act: "delete", eft: "allow"],
            key: :p
          },
          %Acx.Model.Policy{
            attrs: [sub: "alice", obj: "blog_post", act: "create", eft: "allow"],
            key: :p
          }
          ]
      """

      @spec load_policies!(t()) :: t() | {:error, any()}
      def load_policies!(%__MODULE__{persist_adapter: nil}) do
        {:error, "No adapter set and no policy file provided"}
      end

      @spec load_policies!(t()) :: t() | {:error, any()}
      def load_policies!(%__MODULE__{model: m, persist_adapter: adapter} = enforcer) do
        case PersistAdapter.load_policies(adapter) do
          {:ok, policies} ->
            policies
            |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
            |> Enum.filter(fn [key | _] -> Model.has_policy_key?(m, key) end)
            |> Enum.map(fn [key | attrs] -> {key, attrs} end)
            |> Enum.reduce(enforcer, &load_policy!(&2, &1))
        end
      end

      @spec load_policies!(t(), String.t()) :: t()
      def load_policies!(%__MODULE__{model: m} = enforcer, pfile)
          when is_binary(pfile) do
        adapter = Acx.Persist.ReadonlyFileAdapter.new(pfile)
        enforcer = %{enforcer | persist_adapter: adapter}

        case PersistAdapter.load_policies(adapter) do
          {:ok, policies} ->
            policies
            |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
            |> Enum.filter(fn [key | _] -> Model.has_policy_key?(m, key) end)
            |> Enum.map(fn [key | attrs] -> {key, attrs} end)
            |> Enum.reduce(enforcer, &load_policy!(&2, &1))
        end
      end
    end
  end
end
