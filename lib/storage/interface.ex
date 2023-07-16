defmodule Storage.Interface do
  @callback init(map()) :: map()
  @callback load(map(), String.t) :: map()

  @callback add(map(), map()) :: map()
  @callback exists?(map(), atom(), tuple() | String.t) :: boolean()

  @callback save_storage(map(), String.t, :csv) :: boolean()
  @callback save_storage(map(), String.t, :md5) :: boolean()
end
