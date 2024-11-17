defmodule Acx.Enforcer.Allow do
  @moduledoc """
  Enforcer 'allow' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model

  defmacro __using__(_opts) do
    quote do
      @doc """
      Returns `true` if `request` is allowed, otherwise `false`.
      """
      @spec allow?(t(), [String.t()]) :: boolean()
      def allow?(%__MODULE__{model: model} = e, request) when is_list(request) do
        matched_policies = list_matched_policies(e, request)
        Model.allow?(model, matched_policies)
      end
    end
  end
end
