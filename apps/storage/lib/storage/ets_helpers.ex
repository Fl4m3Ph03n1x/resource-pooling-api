defmodule Storage.EtsHelpers do
  @moduledoc """
  Contains utility functions and wrappers for common operations with the ETS
  dependency. Aims to maximize code reuse and minimize code duplication by
  forcing standard handlers.
  """

  alias ETS.Set

  @spec handle_access_entry_response({:error, atom} | {:ok, any}, any) ::
          {:error, {atom, any}} | {:ok, any}
  def handle_access_entry_response({:ok, result}, _data), do: {:ok, result}
  def handle_access_entry_response({:error, reason}, data), do: {:error, {reason, data}}

  @spec handle_reset_response({:ok, Set.t} | {:error, atom}) ::
  {:ok, :table_reseted} | {:error, atom}
  def handle_reset_response({:ok, _table}), do: {:ok, :table_reseted}
  def handle_reset_response({:error, _reason} = error), do: error

  @spec handle_modify_entry_response({:error, atom} | {:ok, Set.t}, any) ::
          {:error, {atom, any}} | {:ok, any}
  def handle_modify_entry_response({:ok, _table}, data), do: {:ok, data}
  def handle_modify_entry_response({:error, reason}, data), do: {:error, {reason, data}}
end
