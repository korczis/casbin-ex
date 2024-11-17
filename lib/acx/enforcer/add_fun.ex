defmodule Acx.Enforcer.AddFun do
  @moduledoc """
  Enforcer 'add_fun' implementation
  """

  use Acx.Enforcer.TypeSpecs

  defmacro __using__(_opts) do
    quote do
      @doc """
      Adds a user-defined function to the enforcer.

      Like built-in function `regex_match?/2`, you can define your own
      function and add it to the enforcer to use in your matcher expression.
      Note that the `fun_name` must match the name used in the matcher
      expression.

      ## Examples

          iex> cfile = "../../test/data/rbac.conf" |> Path.expand(__DIR__)
          ...> {:ok, e} = Enforcer.init(cfile)
          ...> my_fun = fn x, y -> x + y end
          ...> e = e |> Enforcer.add_fun({:my_fun, my_fun})
          ...> %Enforcer{env: %{my_fun: f}} = e
          ...> f.(1, 2)
          3
      """
      @spec add_fun(t(), {atom(), function()}) :: t()
      def add_fun(%__MODULE__{env: env} = enforcer, {fun_name, fun})
          when is_atom(fun_name) and is_function(fun) do
        %{enforcer | env: Map.put(env, fun_name, fun)}
      end
    end
  end
end
