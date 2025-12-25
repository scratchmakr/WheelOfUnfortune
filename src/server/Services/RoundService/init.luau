local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptRegistrationService = game:GetService("ScriptRegistrationService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Configs = require(ReplicatedStorage.Shared.Constants.Configs)
local Promise = require(ReplicatedStorage.Packages.Promise)
local SpinService = require(ReplicatedStorage.Shared.Services.SpinService)
local Network = require(ReplicatedStorage.Shared.Network)
local EventTypes = require(ReplicatedStorage.Shared.Types.Events)
local Events = require(ReplicatedStorage.Shared.Constants.Events)
local AnimationUtils = require(ReplicatedStorage.Shared.Utils.Animation)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.Character)
local Spring = require(ReplicatedStorage.Packages.Spring)

local Assets = ReplicatedStorage.Shared.Assets
local WinningAnimations = Assets:WaitForChild("WinningAnimations")
local DefaultWinningAnimation = WinningAnimations:WaitForChild("Default")

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ToolService = require(ServerScriptService.Server.Services.ToolService)
local DataService = require(ServerScriptService.Server.Services.DataService)

local EventsFolder = ReplicatedStorage.Shared.Services.Events
local Format = require(EventsFolder.Format)

local RoundService = {}

local Scriptables = workspace:WaitForChild("Scriptables")
local MainPlatform = Scriptables:WaitForChild("MainPlatform")
local Grass = MainPlatform:WaitForChild("Grass")
local Dirt = MainPlatform:WaitForChild("Dirt")
local Borders = MainPlatform:WaitForChild("Borders")
local SpawnPart: Part = MainPlatform:WaitForChild("SpawnPart")
local WheelCFrame = Scriptables:WaitForChild("WheelCFrame").Value
local Wheel = Scriptables:WaitForChild("Wheel")
local LeverModel = Wheel:WaitForChild("Lever")

local DEFAULT_MAP_SIZE = 75

local function checkMinimumPlayers()
    return #Players:GetPlayers() >= Configs.MINIMUM_PLAYERS
end

function RoundService.init()
    print("RoundService initialized")

    local alivePlayers = {}
    local eventTrove = Trove.new()
    local props: Format.format = {
        eventTrove = eventTrove,
        playersAlive = alivePlayers,
        roundEnded = false,
        functions = nil,
        eventKey = nil,
        seed = nil,
        inProgress = false,
    }
    local activatedLever = false
    Network.ClickLever:Server():On(function()
        if not props.inProgress then
            return
        end
        activatedLever = true
    end)

    local functions = {
        teleportBackToPlatform = function(player: Player)
            RoundService.addPlayer(player, props, true)
        end,

        resizeMap = RoundService.resizeMap,
        changeHumanoidStats = RoundService.changeHumanoidStats,
    }
    props.functions = functions

    local function startRound()
        print("Minimum players reached, starting round")
        repeat
            task.wait(0.1)
        until checkMinimumPlayers()

        local chosenEvent
        local resolve, reject
        Promise.new(function(res, rej)
            resolve, reject = res, rej
            -- print("intermission", resolve, reject)
            for i = 1, Configs.INTERMISSION_TIME do
                -- print("Intermission time: ", i)
                if not checkMinimumPlayers() then
                    reject()
                end
                task.wait(0.1)
            end
            resolve()
        end):andThen(function()
            print("Round started", resolve, reject)
            props.inProgress = true
            if not checkMinimumPlayers() then
                reject()
            end

            for _, player in Players:GetPlayers() do
                if table.find(alivePlayers, player) then
                    continue
                end
                RoundService.addPlayer(player, props)
            end

            local totalRounds = 0
            repeat
                activatedLever = false

                local finishTime = workspace.DistributedGameTime + 10
                local leverTrove = Trove.new()
                for _, player in Players:GetPlayers() do
                    Network.SendAnnouncement:Server():Fire(player, "Spin the wheel!", finishTime)
                    leverTrove:Add(function()
                        Network.ClickLever:Server():Fire(player)
                        Network.SendAnnouncement:Server():Fire(player, "")
                    end)
                end
                repeat task.wait(0.1) until activatedLever or workspace.DistributedGameTime >= finishTime
                leverTrove:Destroy()
                task.wait(2.5) -- wait for plankton animation on client
                totalRounds += 1
                props.roundEnded = false
                local seed = os.time()
                local eventData = SpinService.rollEvent(seed)
                local correspondingGame = EventsFolder:FindFirstChild(eventData.eventKey)
                if correspondingGame then
                    chosenEvent = eventData.eventKey
                    props.eventKey = chosenEvent
                    props.seed = seed
                    local eventModule = require(correspondingGame)
                    local gameFunction = eventModule.Start
                    if typeof(gameFunction) == "function" then
                        for _, player in Players:GetPlayers() do
                            Network.SpinWheel:Server():Fire(player, seed)
                        end
                        task.wait(10)
                        local map = gameFunction(props)
                        local wheelCFrame = map and map:FindFirstChild("WheelCFrame")
                        if wheelCFrame then
                            Wheel:PivotTo(wheelCFrame.Value)
                            for _, child in LeverModel:GetChildren() do
                                if child:IsA("BasePart") and child.Transparency == 0 then
                                    child.Transparency = 1
                                    props.eventTrove:Add(function()
                                        child.Transparency = 0
                                    end)
                                end
                            end
                        else
                            Wheel.Parent = script
                        end
                        RoundService.toggleBorders()
                        repeat task.wait(0.1) until props.roundEnded or #props.playersAlive <= 0

                        for _, player in alivePlayers do
                            Network.ToggleOthersVisibility:Server():Fire(player, true)
                        end

                        RoundService.toggleBorders(true)
                        props.eventTrove:Clean()
                        Wheel.Parent = Scriptables
                        RoundService.resizeMap(DEFAULT_MAP_SIZE)
                        for _, player in alivePlayers do
                            RoundService.changeHumanoidStats(player, {
                                WalkSpeed = StarterPlayer.CharacterWalkSpeed,
                                JumpHeight = StarterPlayer.CharacterJumpHeight,
                            })
                        end
                        if #alivePlayers <= 1 then
                            resolve()
                        end
                    else
                        warn("Game function is not a function: ", eventData.eventKey)
                        reject()
                    end
                else
                    warn("No corresponding game found for event: ", eventData.eventKey)
                    reject()
                end
            until #alivePlayers <= 1 or totalRounds >= Configs.MAX_ROUNDS

            if totalRounds >= Configs.MAX_ROUNDS then -- sudden death slap battles on shrinking platform
                for _, player in alivePlayers do
                    ToolService.givePlayerTool(player, "Fists", true)
                end
            end

            -- insta respawn
            -- local seed = os.time()
            -- local eventData = SpinService.rollEvent(seed)
            -- local correspondingGame = script:FindFirstChild(eventData.eventKey)
            -- if correspondingGame then
            --     chosenEvent = eventData.eventKey
            --     local gameFunction = require(correspondingGame)
            --     for _, player in Players:GetPlayers() do
            --         Network.SpinWheel:Server():Fire(player, seed)
            --     end
            --     task.wait(10)
            --     if typeof(gameFunction) == "function" then
            --         local map = gameFunction(props)
            --         local wheelCFrame = map and map:FindFirstChild("WheelCFrame")
            --         if wheelCFrame then
            --             Wheel:PivotTo(wheelCFrame.CFrame)
            --         end
            --         repeat task.wait(0.1) until props.roundEnded
            --     else
            --         warn("Game function is not a function: ", eventData.eventKey)
            --         reject()
            --     end
            -- else
            --     warn("No corresponding game found for event: ", eventData.eventKey)
            --     reject()
            -- end
            resolve()

        end):catch(function(error)
            warn("Round failed, restarting", error)
        end):await()

        props.inProgress = false
        task.wait(0.25)
        if #alivePlayers <= 1 then
            local winner = alivePlayers[1]
            local character = winner and winner.Character
            local humanoid = character and character:WaitForChild("Humanoid")
            if humanoid then
                -- local winnerDocument = DataService.documents[winner]
                -- local winnerData = winnerDocument and winnerDocument:read()
                -- if winnerDocument then
                --     winnerDocument:write({Wins = winnerData + 1})
                -- end
                local leaderstats = winner.leaderstats
                local wins = leaderstats and leaderstats:FindFirstChild("Wins")
                local gold = wins and leaderstats:FindFirstChild("Gold")
                if gold then
                    wins.Value += 1
                    gold.Value += 250
                end

                humanoid.WalkSpeed = 25
                humanoid.JumpHeight = 7.2
                character:ScaleTo(4)
                character:PivotTo(character:GetPivot() + Vector3.new(0, 20, 0))
                local winningAnimation = AnimationUtils.LoadAnimation(character, DefaultWinningAnimation)
                if winningAnimation then
                    winningAnimation.Looped = true
                    winningAnimation:Play()
                end
            end
        end
        Wheel:PivotTo(WheelCFrame)

        task.wait(5)
        for _, player in alivePlayers do
            RoundService.removePlayer(player, props)
        end

        -- for _, player in alivePlayers do
        --     local eventMetadata = Events[chosenEvent]
        --     if eventMetadata then
        --         local reward = eventMetadata.Rewards
        --         if reward then
        --             local gold = reward.Gold
        --             local wins = reward.Wins
        --             if gold then
        --                 player.leaderstats.Gold.Value += gold
        --             end
        --             if wins then
        --                 player.leaderstats.Wins.Value += wins
        --             end
        --         end
        --     end
        -- end
        
        startRound()
    end
    
    startRound()

    Players.PlayerRemoving:Connect(function(player)
        local index = table.find(alivePlayers, player)
        if index then
            table.remove(alivePlayers, index)
        end
    end)
end

function RoundService.addPlayer(player: Player, props: Format.format, justTeleport: boolean?)
    local character = player.Character
    local humanoid = character and character:WaitForChild("Humanoid")

    if humanoid then
        CharacterUtils.teleportWithinPlatform(character, SpawnPart)
        if not justTeleport then
            table.insert(props.playersAlive, player)
            local humConnection
            humConnection = humanoid.Died:Connect(function()
                local index = table.find(props.playersAlive, player)
                print("Player died", player.Name, index)
                if index then
                    table.remove(props.playersAlive, index)
                end
                Network.SendAnnouncement:Server():Fire(player, "You have been eliminated", workspace.DistributedGameTime + 3)
            end)
    
            props.eventTrove:Add(function()
                task.delay(5, function()
                    humConnection:Disconnect()
                end)
            end)
        end
    end
end

function RoundService.removePlayer(player: Player, props: Format.format)
    local index = table.find(props.playersAlive, player)
    if index then
        local removedPlayer = table.remove(props.playersAlive, index)
        
        pcall(function()
            removedPlayer:LoadCharacter()
        end)
    end
end

function RoundService.toggleBorders(toggle: boolean?)
    for _, border in Borders:GetChildren() do
        if border:IsA("BasePart") then
            -- border.Transparency = toggle and 0 or 1
            border.CanCollide = not not toggle
        end
    end
end

function RoundService.resizeMap(studs: number)
    Spring.target(Grass, 0.7, 1.5, {
        Size = Vector3.new(studs, Grass.Size.Y, studs),
    })
    Spring.target(Dirt, 0.7, 1.5, {
        Size = Vector3.new(studs, Dirt.Size.Y, studs),
    })
end

function RoundService.changeHumanoidStats(player: Player, properties: {[string]: any})
    local character = player.Character
    local humanoid = character and character:WaitForChild("Humanoid")
    if humanoid then
        for key, value in properties do
            humanoid[key] = value
        end
    end
end

return RoundService