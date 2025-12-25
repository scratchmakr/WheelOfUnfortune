local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Shared.Network)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.Character)

local CharacterController = {}

function CharacterController.init()
    Network.ToggleOthersVisibility:Client():On(function(toggle)
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer then
                local character = plr.Character
                if character then
                    CharacterUtils.toggleVisibility(character, toggle)
                end
            end
        end
    end)
end

return CharacterController