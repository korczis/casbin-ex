defmodule Acx.Enforcer do
  @moduledoc """
  TODO
  """

  defstruct [
    model: nil,
    policies: [],
    role_groups: [],
    env: %{}
  ]

  alias Acx.Model
  alias Acx.Internal.RoleGroup

  @type t() :: %__MODULE__{
    model: Model.t(),
    policies: [Model.Policy.t()],
    role_groups: %{atom() => RoleGroup.t()},
    env: map()
  }

  @doc """
  Loads and contructs a model from the given config file `cfile`.
  """
  @spec init(String.t()) :: {:ok, t()} | {:error, String.t()}
  def init(cfile) when is_binary(cfile) do
    case Model.init(cfile) do
      {:error, reason} ->
        {:error, reason}

      {:ok, %Model{role_mappings: role_mappings} = model} ->
        role_groups =
          role_mappings
          |> Enum.map(fn m -> {m, RoleGroup.new(m)} end)

        # TODO: What if one of the mapping name in `role_mappings`
        # conflicts with sone built-in function names?
        env =
          role_groups
          |> Enum.map(fn {name, g} -> {name, RoleGroup.stub(g)} end)
          |> Map.new()
          |> Map.merge(init_env())

        {
          :ok,
          %__MODULE__{
            model: model,
            role_groups: role_groups |> Map.new,
            env: env
          }
        }
    end
  end

  @doc """
  Returns `true` if `request` is allowed, otherwise `false`.
  """
  def allow?(%__MODULE__{model: model} = e, request) do
    matched_policies = list_matched_policies(e, request)
    Model.allow?(model, matched_policies)
  end

  #
  # Policy management.
  #

  @doc """
  Adds a new policy rule with key given by `key` and a list of
  attribute values `attr_values` to the enforcer.
  """
  @spec add_policy(t(), {atom(), [String.t()]}) :: t() | {:error, String.t()}
  def add_policy(
    %__MODULE__{model: model, policies: policies} = enforcer,
    {key, attrs}
  ) do
    case Model.create_policy(model, {key, attrs}) do
      {:error, reason} ->
        {:error, reason}

      {:ok, policy} ->
        case Enum.member?(policies, policy) do
          true ->
            {:error, :already_existed}

          false ->
            %{enforcer | policies: [policy | policies]}
        end
    end
  end

  @doc """
  Adds a new policy rule with key given by `key` and a list of attribute
  values `attr_values` to the enforcer.
  """
  def add_policy!(%__MODULE__{} = enforcer, {key, attrs}) do
    case add_policy(enforcer, {key, attrs}) do
      {:error, reason} ->
        raise ArgumentError, message: reason

      enforcer ->
        enforcer
    end
  end

  @doc """
  Loads policy rules from external file given by the name `pfile` and
  adds them to the enforcer.

  A valid policy file should be a `*.csv` file, in which each line must
  have the following format:

    `pkey, attr1, attr2, attr3`

  in which `pkey` is the key of the policy rule, this key must match the
  policy definition in the enforcer. `attr1`, `attr2`, ... are the
  value of attributes specified in the policy definition.
  """
  def load_policies!(%__MODULE__{model: m} = enforcer, pfile) do
    pfile
    |> File.read!
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ~r{,\s*}))
    |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
    |> Enum.filter(fn [key | _] -> Model.has_policy_key?(m, key) end)
    |> Enum.map(fn [key | attrs] -> {key, attrs} end)
    |> Enum.reduce(enforcer, &add_policy!(&2, &1))
  end

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
  """
  def list_policies(
    %__MODULE__{policies: policies},
    criteria
  ) when is_map(criteria) or is_list(criteria) do
    policies
    |> Enum.filter(fn %{key: key, attrs: attrs} ->
      list = [{:key, key} | attrs]
      criteria |> Enum.all?(fn c -> c in list end)
    end)
  end

  def list_policies(%__MODULE__{policies: policies}), do: policies

  @doc """
  Returns a list of policy rules in the given enforcer that match the
  given `request`.
  """
  def list_matched_policies(
    %__MODULE__{model: model, policies: policies, env: env},
    request
  ) do
    case Model.create_request(model, request) do
      {:error, _reason} ->
        []

      {:ok, req} ->
        policies
        |> Enum.filter(fn pol -> Model.match?(model, req, pol, env) end)
    end
  end

  #
  # RBAC role management
  #

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
  """
  @spec add_mapping_policy(t(), {atom(), String.t(), String.t()}) ::
  t() | {:error, String.t()}
  def add_mapping_policy(
    %__MODULE__{role_groups: groups, env: env} = enforcer,
    {mapping_name, role1, role2}
  ) when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
    case Map.get(groups, mapping_name) do
      nil ->
        {:error, "mapping name not found: `#{mapping_name}`"}

      group ->
        group =
          group
          |> RoleGroup.add_inheritance({role1, role2})

        %{
          enforcer |
          role_groups: %{groups | mapping_name => group},
          env: %{env | mapping_name => RoleGroup.stub(group)}
        }
    end
  end

  def add_mapping_policy!(
    %__MODULE__{} = enforcer,
    {mapping_name, role1, role2}
  ) when is_atom(mapping_name) and is_binary(role1) and is_binary(role2) do
    case add_mapping_policy(enforcer, {mapping_name, role1, role2}) do
      {:error, reason} ->
        raise ArgumentError, message: reason

      enforcer ->
        enforcer
    end
  end

  @doc """
  Loads mapping policies from a csv file and adds them to the enforcer.
  """
  def load_mapping_policies!(%__MODULE__{model: m} = enforcer, fname)
  when is_binary(fname) do
    fname
    |> File.read!
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ~r{,\s*}))
    |> Enum.map(fn [key | attrs] -> [String.to_atom(key) | attrs] end)
    |> Enum.filter(fn [key | _] -> Model.has_role_mapping?(m, key) end)
    |> Enum.map(fn [name, r1, r2] -> {name, r1, r2} end)
    |> Enum.reduce(enforcer, &add_mapping_policy!(&2, &1))
  end

  #
  # Build in stubs function
  #

  @doc """
  Returns `true` if the given string `str` matches the pattern
  string `^pattern$`.
  """
  def regex_match?(str, pattern) do
    case Regex.compile("^#{pattern}$") do
      {:error, _} ->
        false

      {:ok, r} ->
        Regex.match?(r, str)
    end
  end

  #
  # Helpers
  #

  defp init_env do
    %{
      regex_match?: &regex_match?/2
    }
  end

end
