defmodule Acx.Enforcer.AddPolicy do
  @moduledoc """
  Enforcer 'add_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Adds a new policy rule with key given by `key` and a list of
      attribute values `attr_values` to the enforcer.
      """
      @spec add_policy(t(), {atom(), [String.t()]}) :: t() | {:error, String.t()}
      def add_policy(
            %__MODULE__{persist_adapter: adapter} = enforcer,
            {_key, _attrs} = rule
          ) do
        with {:ok, enforcer} <- load_policy(enforcer, rule),
             {:ok, adapter} <- PersistAdapter.add_policy(adapter, rule) do
          %{enforcer | persist_adapter: adapter}
        else
          {:error, reason} -> {:error, reason}
          true -> {:error, :already_existed}
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
    end
  end
end
