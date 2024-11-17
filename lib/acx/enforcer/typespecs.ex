defmodule Acx.Enforcer.TypeSpecs do
  @moduledoc """
  Type specifications for the Enforcer module
  """

  defmacro __using__(_opts) do
    quote do
      @type mapping() ::
              {atom(), String.t(), String.t()}
              | {atom(), String.t(), String.t(), String.t()}

      @type t() :: %{
              __struct__: atom(),
              model: Acx.Model.t(),
              policies: [Acx.Model.Policy.t()],
              mapping_policies: [String.t()],
              role_groups: %{atom() => Acx.Internal.RoleGroup.t()},
              env: map(),
              persist_adapter: Acx.Persist.PersistAdapter.t()
            }
    end
  end
end
