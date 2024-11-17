defmodule Acx.Enforcer.Behaviour do
  @moduledoc """
  TODO
  """

  defmacro __using__(opts \\ []) do
    quote do
      defstruct model: nil,
                policies: [],
                mapping_policies: [],
                role_groups: [],
                env: %{},
                persist_adapter: nil

      require Logger

      alias Acx.Model
      alias Acx.Internal.RoleGroup
      alias Acx.Persist.PersistAdapter

      use Acx.Enforcer.TypeSpecs

      use Acx.Enforcer.Init
      use Acx.Enforcer.Allow
      use Acx.Enforcer.AddPolicy
      use Acx.Enforcer.LoadPolicies
      use Acx.Enforcer.LoadPolicy
      use Acx.Enforcer.RemovePolicy
      use Acx.Enforcer.RemoveFilteredPolicy
      use Acx.Enforcer.ListPolicies
      use Acx.Enforcer.ListMatchedPolicies
      use Acx.Enforcer.LoadMappingPolicy
      use Acx.Enforcer.AddMappingPolicy
      use Acx.Enforcer.LoadMappingPolicies
      use Acx.Enforcer.ListMappingPolicies
      use Acx.Enforcer.RemoveMappingPolicy
      use Acx.Enforcer.SavePolicies
      use Acx.Enforcer.SetPersistAdapter
      use Acx.Enforcer.AddFun

      @doc """
      Returns `true` if the given string `str` matches the pattern
      string `^pattern$`.

      Returns `false` otherwise.

      ## Examples

          iex> Enforcer.regex_match?("/alice_data/foo", "/alice_data/.*")
          true
      """
      @spec regex_match?(String.t(), String.t()) :: boolean()
      def regex_match?(str, pattern) do
        case Regex.compile("^#{pattern}$") do
          {:error, _} ->
            false

          {:ok, r} ->
            Regex.match?(r, str)
        end
      end

      @doc """
      Returns `true` if `key1` matches the pattern of `key2`.

      Returns `false` otherwise.

      `key_match2?/2` can handle three types of path / patterns :

        URL path like `/alice_data/resource1`.
        `:` pattern like `/alice_data/:resource`.
        `*` pattern like `/alice_data/*`.

      ## Parameters

      - `key1` should be a URL path.
      - `key2` can be a URL path, a `:` pattern or a `*` pattern.

      ## Examples

          iex> Enforcer.key_match2?("alice_data/resource1", "alice_data/*")
          true
          iex> Enforcer.key_match2?("alice_data/resource1", "alice_data/:resource")
          true
      """
      @spec key_match2?(String.t(), String.t()) :: boolean()
      def key_match2?(key1, key2) do
        key2 = String.replace(key2, "/*", "/.*")

        with {:ok, r1} <- Regex.compile(":[^/]+"),
             match <- Regex.replace(r1, key2, "[^/]+"),
             {:ok, r2} <- Regex.compile("^" <> match <> "$") do
          Regex.match?(r2, key1)
        else
          _ -> false
        end
      end

      #
      # Helpers
      #

      defp init_env do
        %{
          regexMatch: &regex_match?/2,
          keyMatch2: &key_match2?/2
        }
      end

      defoverridable [
        # Core initialization and configuration
        init: 1,
        init: 2,
        allow?: 2,

        # Policy management
        add_policy: 2,
        add_policy!: 2,
        remove_policy: 2,
        remove_policy!: 2,
        remove_filtered_policy: 4,
        remove_filtered_policy!: 4,
        set_persist_adapter: 2,

        # Policy loading and listing
        load_policies!: 1,
        load_policies!: 2,
        list_policies: 1,
        list_policies: 2,
        list_matched_policies: 2,
        save_policies: 1,
        save_policies!: 1,

        # Mapping policies management
        add_mapping_policy: 2,
        add_mapping_policy!: 2,
        remove_mapping_policy: 2,
        remove_mapping_policy!: 2,
        load_mapping_policies!: 1,
        load_mapping_policies!: 2,
        list_mapping_policies: 1,
        list_mapping_policies: 2,
        list_mapping_policies: 3,

        # Function management
        add_fun: 2,

        # Helper functions
        regex_match?: 2,
        key_match2?: 2
      ]

      unquote(Macro.expand(opts, __ENV__))
    end
  end
end

defmodule Acx.Enforcer do
  use Acx.Enforcer.Behaviour

  defmacro __using__(opts \\ []) do
    quote do
      use Acx.Enforcer.Behaviour, unquote(opts)
    end
  end
end
