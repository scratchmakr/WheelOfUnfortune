local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Shared.Network)

local EventsFolder = ReplicatedStorage.Shared.Services.Events

local EventController = {}

function EventController.init()
    Network.PlayEventAnimations:Client():On(function(animationProps)
        -- print("animationProps", animationProps)
        local eventKey = animationProps.eventKey

        local gameModule = EventsFolder:FindFirstChild(eventKey)
        -- print("gameModule", gameModule)
        if gameModule then
            gameModule = require(gameModule)
            local playAnimationsFunction = gameModule.PlayAnimations
            if typeof(playAnimationsFunction) == "function" then
                playAnimationsFunction(animationProps)
            else
                warn("PlayAnimations function is not a function: ", eventKey)
            end
        end
    end)
end

return EventController