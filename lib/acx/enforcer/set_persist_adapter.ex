defmodule Acx.Enforcer.SetPersistAdapter do
  @moduledoc """
  Enforcer 'set_persist_adapter' implementation
  """

  use Acx.Enforcer.TypeSpecs

  defmacro __using__(_opts) do
    quote do
      @doc """
      Sets the provided adapter to manage persisting rules in storage.
      """
      def set_persist_adapter(%__MODULE__{} = enforcer, adapter) do
        %{enforcer | persist_adapter: adapter}
      end
    end
  end
end
