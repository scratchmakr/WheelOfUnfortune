local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Difficulties = require(ReplicatedStorage.Shared.Constants.Difficulties)
local RblxUtils = require(ReplicatedStorage.Packages.RblxUtils)
local Weight = require(ReplicatedStorage.Shared.Utils.Weight)
local Events = require(ReplicatedStorage.Shared.Constants.Events)
local EventTypes = require(ReplicatedStorage.Shared.Types.Events)
local DifficultyTypes = require(ReplicatedStorage.Shared.Types.Difficulties)

local SpinService = {}

local weightPool = {}
for key, metadata in Difficulties do
    weightPool[key] = metadata.Weight
end

local eventsPool = {}

for key, metadata in Events do
    local eventsTable = eventsPool[metadata.Difficulty] or {}
    eventsTable[key] = 1
    eventsPool[metadata.Difficulty] = eventsTable
end

print("eventsPool", eventsPool)
function SpinService.rollEvent(seed: number)
    local random = Random.new(seed)
    
    local offset = random:NextInteger(-15, 15)
    local randomDifficulty = Weight.getRandomKeyFromDictionary(weightPool, random)
    local randomEvent = Weight.getRandomKeyFromDictionary(eventsPool[randomDifficulty], random)
    -- return {
    --     difficultyKey = randomDifficulty,
    --     eventKey = randomEvent,
    --     offset = offset,
    -- }

    return {
        difficultyKey = DifficultyTypes.DEATH,
        eventKey = EventTypes.TILE_OUTLINE,
        offset = offset,
    }
end

return SpinService