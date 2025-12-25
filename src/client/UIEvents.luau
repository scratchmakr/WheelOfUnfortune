local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local UIEvents = {
    NewEvent = Signal.new() :: Signal.Signal<any>,
}

return UIEvents