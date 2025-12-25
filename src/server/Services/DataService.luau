local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Shared.Constants.Data)
local Lapis = require(ReplicatedStorage.Packages.Lapis)

local DEFAULT_DATA = Data.TEMPLATE
local KEY_PREFIX = "Player"

local collection = Lapis.createCollection("PlayerData", {
    defaultData = DEFAULT_DATA,
    -- You can use t by osyrisrblx to typecheck your data at runtime.
    -- validate = t.strictInterface({ coins = t.integer }),
})

local DataService = {}
DataService.documents = {} :: {[Player]: {data: {Data.Data}}}
DataService.offlineDocuments = {} :: {[string]: {data: {Data.Data}}}

local function onPlayerAdded(player: Player)
    print("ON PLAYER ADDED", player)
    -- The second argument associates the document with the player's UserId which is useful
    -- for GDPR compliance.
    local function createLeaderstats(player: Player, document: Lapis.Document)
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    
        local data = document:read()
        -- print("DATA", data)
        local wins = Instance.new("IntValue", leaderstats)
        wins.Name = "Wins"
        wins.Value = data.Wins or 0
    
        local gold = Instance.new("IntValue", leaderstats)
        gold.Name = "Gold"
        gold.Value = data.Gold or 0

        gold.Changed:Connect(function()
            document:write({Gold = gold.Value})
        end)

        wins.Changed:Connect(function()
            document:write({Wins = wins.Value})
        end)
    end

    local USER = tostring(player.UserId)
    collection
        :load(`{KEY_PREFIX}{player.UserId}`, { player.UserId })
        :andThen(function(document)
            print("DOCUMENT", document)
            if player.Parent == nil then
                -- The player might have left before the document finished loading.
                -- The document needs to be closed because PlayerRemoving won't fire at this point.
                document:close():catch(warn)
                return
            end

            DataService.documents[player] = document
            -- document:write({Gold = 100})
            
            createLeaderstats(player, document)
            -- ServerEvents.DataLoaded:Fire(player)
            print("DEFAULT DATA", DEFAULT_DATA)
            -- Store.loadPlayerData(USER, DEFAULT_DATA)
        end)
        :catch(function(message)
            warn(`Player {player.Name}'s data failed to load: {message}`)
            -- Optionally, you can kick the player when their data fails to load:
            player:Kick("Data failed to load.")
        end)
end

local function onPlayerRemoving(player: Player)
    local document = DataService.documents[player]

    -- The document won't be added to the dictionary if PlayerRemoving fires bofore it finishes loading.
    if document ~= nil then
        DataService.documents[player] = nil
        document:close():catch(warn)
    end
end

function DataService.init()
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end
end

function DataService.getDocument(player: Player)
    return DataService.documents[player]
end

function DataService.loadOfflineDocument(user: number | string)
    local formattedUser = tostring(user)
    local offlineDocument = DataService.offlineDocuments[formattedUser]
    if offlineDocument then
        return offlineDocument
    end

    local document = collection:load(`{KEY_PREFIX}{formattedUser}`, { formattedUser })
    DataService.offlineDocuments[formattedUser] = document
    return document
end

return DataService