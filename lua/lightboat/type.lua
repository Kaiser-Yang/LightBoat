--- @class LightBoat.BigFileOpt
--- @field enabled boolean
--- @field total integer
--- @field every_line integer
--- @field on_changed fun(buffer: integer)

--- @class LightBoat.CommandSpec
--- @field enabled boolean
--- @field name string

--- @alias LightBoat.CommandOpt table<string, LightBoat.CommandSpec>

--- @class LightBoat.ComplexEventSpec
--- @field event string
--- @field pattern? string|string[]

--- @alias LightBoat.EventSpec string|LightBoat.ComplexEventSpec

--- @class LightBoat.BufferKeyChainSpec
--- @field map_on_event LightBoat.EventSpec[]
--- @field unmap_on_event? LightBoat.EventSpec[]

--- @class LightBoat.LineWiseOpt
--- @field consider_wrap? boolean|fun():boolean
--- @field increase_count boolean
