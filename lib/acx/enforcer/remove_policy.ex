defmodule Acx.Enforcer.RemovePolicy do
  @moduledoc """
  Enforcer 'remove_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model
  alias Acx.Persist.PersistAdapter

  defmacro __using__(_opts) do
    quote do
      @doc """
      Removes the policy rule or rules that match from the enforcer.
      """
      def remove_policy(
            %__MODULE__{model: model, policies: policies, persist_adapter: adapter} = enforcer,
            {key, attrs}
          ) do
        with {:ok, policy} <- Model.create_policy(model, {key, attrs}),
             true <- Enum.member?(policies, policy),
             {:ok, _adapter} <- PersistAdapter.remove_policy(adapter, {key, attrs}),
             policies <- Enum.reject(policies, fn p -> p == policy end) do
          %{enforcer | policies: policies}
        else
          false -> {:error, :nonexistent}
          {:error, reason} -> {:error, reason}
        end
      end

      @spec remove_policy!(any, any) :: t()
      def remove_policy!(%__MODULE__{} = enforcer, {key, attrs}) do
        case remove_policy(enforcer, {key, attrs}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          enforcer ->
            enforcer
        end
      end
    end
  end
end
