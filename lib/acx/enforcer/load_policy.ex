defmodule Acx.Enforcer.LoadPolicy do
  @moduledoc """
  Enforcer 'load_policy' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model

  defmacro __using__(_opts) do
    quote do
      @spec load_policy(t(), {atom(), [String.t()]}) :: t() | {:error, String.t()}
      defp load_policy(
             %__MODULE__{model: model, policies: policies, persist_adapter: adapter} = enforcer,
             {key, attrs}
           ) do
        with {:ok, policy} <- Model.create_policy(model, {key, attrs}),
             false <- Enum.member?(policies, policy) do
          enforcer = %{enforcer | policies: [policy | policies], persist_adapter: adapter}
          {:ok, enforcer}
        else
          {:error, reason} -> {:error, reason}
          true -> {:error, :already_existed}
        end
      end

      defp load_policy!(%__MODULE__{} = enforcer, {key, attrs}) do
        case load_policy(enforcer, {key, attrs}) do
          {:error, reason} ->
            raise ArgumentError, message: reason

          {:ok, enforcer} ->
            enforcer
        end
      end
    end
  end
end
