local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Red = require(ReplicatedStorage.Packages.Red)

local EventFormat = require(ReplicatedStorage.Shared.Services.Events.Format)

return {
    SpinWheel = Red.Event("SpinWheel", function(seed)
        assert(typeof(seed) == "number", "Seed must be a number")
        return seed
    end),

    ClickLever = Red.Event("ClickLever", function()
        return
    end),

    PlayEventAnimations = Red.Event("PlayEventAnimations", function(animationProps)
        local seed = animationProps.seed
        local map = animationProps.map
        local eventKey = animationProps.eventKey
        assert(typeof(seed) == "number", "Seed must be a number")
        assert(typeof(map) == "Model", "Map must be a model")
        assert(typeof(eventKey) == "string", "Event key must be a string")
        return animationProps
    end),

    SendAnnouncement = Red.Event("SendAnnouncement", function(announcement, finishTime) -- finish time is the game distributed time when the announcement should finish
        assert(typeof(finishTime) == "number", "finishTime must be a number")
        assert(typeof(announcement) == "string", "Announcement must be a string")
        return announcement, finishTime
    end),

    TakeDamage = Red.Event("TakeDamage", function(damage)
        assert(typeof(damage) == "number", "Damage must be a number")
        return damage
    end),

    ToggleOthersVisibility = Red.Event("ToggleOthersVisibility", function(toggle)
        assert(typeof(toggle) == "boolean", "Toggle must be a boolean")
        return toggle
    end),

}