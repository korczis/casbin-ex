defmodule Acx.Enforcer.ListMatchedPolicies do
  @moduledoc """
  Enforcer 'list_matched_policies' implementation
  """

  use Acx.Enforcer.TypeSpecs

  alias Acx.Model

  defmacro __using__(_opts) do
    quote do
      @doc """
      Returns a list of policy rules in the given enforcer that match the
      given `request`.
      """
      @spec list_matched_policies(t(), [String.t()]) :: [Model.Policy.t()]
      def list_matched_policies(
            %__MODULE__{model: model, policies: policies, env: env},
            request
          )
          when is_list(request) do
        case Model.create_request(model, request) do
          {:error, _reason} ->
            []

          {:ok, req} ->
            policies
            |> Enum.filter(fn pol -> Model.match?(model, req, pol, env) end)
        end
      end
    end
  end
end
