--- @alias LightBoat.KeyHandlerReturn string|boolean|nil

--- @alias LightBoat.KeyHandlerFn fun(): LightBoat.KeyHandlerReturn

--- @class LightBoat.KeyHandlerSpec
--- @field priority number
--- @field handler LightBoat.KeyHandlerFn

--- @class LightBoat.ComplexEventSpec
--- @field event string
--- @field pattern? string|string[]

--- @alias LightBoat.EventSpec string|LightBoat.ComplexEventSpec

--- @class LightBoat.KeyChainSpec : vim.keymap.set.Opts
--- @field key string The actual key to be mapped
--- @field mode string|string[]
--- @field desc? string
--- @field extra_opts? any
--- @field handler table<string, LightBoat.KeyHandlerSpec|boolean>

--- @class LightBoat.BufferKeyChainSpec : LightBoat.KeyChainSpec
--- @field map_on_event LightBoat.EventSpec[]
--- @field unmap_on_event? LightBoat.EventSpec[]

--- @alias LightBoat.GlobalKeyChainSpec LightBoat.KeyChainSpec

--- @alias LightBoat.GlobalKeySpec table<string, LightBoat.GlobalKeyChainSpec|boolean>

--- @alias LightBoat.BufferKeySpec table<string, LightBoat.BufferKeyChainSpec|boolean>

--- @class LightBoat.LineWiseOpt
--- @field consider_wrap? boolean|fun():boolean
--- @field increase_count boolean
