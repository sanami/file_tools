defmodule Storage.Interface do
  @callback init(map()) :: map()
  @callback load(map(), String.t) :: map()
  @callback save(map()) :: map()
  @callback add(map(), map()) :: map()
  @callback exists?(map(), atom(), tuple() | String.t) :: boolean()
end
