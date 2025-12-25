local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Shared.Network)

local PlayerService = {}

function PlayerService.init()
    Network.TakeDamage:Server():On(function(player, damage)
        local character = player.Character
        local humanoid = character and character.Humanoid
        if humanoid then
            humanoid.Health -= damage
        end
    end)
end

return PlayerService