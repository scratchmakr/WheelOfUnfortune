local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Network = require(ReplicatedStorage.Shared.Network)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)

local StarterPlayer = game:GetService("StarterPlayer")

local Assets = ReplicatedStorage.Shared.Assets
local LaserParkourAssets = Assets.LaserParkour
local Map = LaserParkourAssets.LaserParkour

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local ROUND_TIMER = 40

local LaserParkour = {}

function LaserParkour.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local memorizationPeriod = true
    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local goalTime = Fusion.Value(10000000)

    local playersAlive = props.playersAlive
    local playersFinished = {}
    eventTrove:Add(function()
        for _, player in playersAlive do
            if not table.find(playersFinished, player) then
                local character = player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            else
                props.functions.teleportBackToPlatform(player)
            end
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersFinished, #playersAlive)
        props.roundEnded = true
    end)

    local newMap = Map:Clone()
    newMap.Parent = workspace

    task.defer(function()
        task.wait(1)
        local animationProps = {
            seed = seed,
            map = newMap,
            eventKey = props.eventKey
        } :: Format.animationProps

        for _, player in Players:GetPlayers() do
            Network.PlayEventAnimations:Server():Fire(player, animationProps)
            task.delay(1, function()
                local finishMemorizationTime = workspace.DistributedGameTime + MEMORIZATION_TIME
                goalTime:set(finishMemorizationTime)
                for _, player in playersAlive do
                    Network.SendAnnouncement:Server():Fire(player, "Memorize the pattern", finishMemorizationTime)
                end
            end)
        end
    end)
    
    eventTrove:Add(newMap)
    eventTrove:Add(newMap.FinishPart.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            table.insert(playersFinished, player)
            -- TODO: ADD FINISH SFX
            if #playersFinished >= #playersAlive then
                props.eventTrove:Clean()
            end
        end
    end))

    local tileParts = {}
    local randomPattern = presetPatterns[random:NextInteger(1, #presetPatterns)]
    
    for i = 1, #randomPattern do
        local tile = tostring(randomPattern[i])
        local tilePart = newMap.Tiles:FindFirstChild(tile)
        local main = tilePart and tilePart:FindFirstChild("Main")
        if main then
            table.insert(tileParts, main)
        end
    end
    print("randomPattern", randomPattern, tileParts)

    task.delay(3, function()
        local tileChildren = newMap.Tiles:GetChildren()
        for i = 1, #tileChildren do
            local tile = newMap.Tiles:FindFirstChild(tostring(i))
            local main = tile:FindFirstChild("Main")
            if main and main:IsA("Part") then
                local revealed = false
                local isSafe = table.find(tileParts, main)
                eventTrove:Add(main.Touched:Connect(function(hit)
                    local player = Players:GetPlayerFromCharacter(hit.Parent)
                    local character = player and player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    local humanoidRootPart = humanoid and character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        if isSafe and not revealed then
                            revealed = true
                            main.Color = Color3.fromRGB(101, 202, 101)
                            SoundUtils.playSound(LaserParkourAssets.Correct, humanoidRootPart)
                        elseif not isSafe then
                            humanoid.Health = 0
                            SoundUtils.playSound(LaserParkourAssets.Incorrect, humanoidRootPart)
                        end
                    end
                end))
            end
        end
        task.wait(0.1)
        for i = 1, #tileParts do
            local tile = tileParts[i]
            tile.Color = Color3.fromRGB(101, 202, 101)
            SoundUtils.playSound(LaserParkourAssets.Correct)
            task.wait(0.1)
        end
    end)

    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() then
            if memorizationPeriod then
                memorizationPeriod = false
                local finishTime = workspace.DistributedGameTime + ROUND_TIMER
                goalTime:set(finishTime)
                newMap.Border:Destroy()
                for _, tile in tileParts do
                    tile.Color = Color3.fromRGB(163, 162, 165)
                end

                for _, player in playersAlive do
                    Network.SendAnnouncement:Server():Fire(player, "Make it across by following your memorized pattern!", finishTime)
                end
            else
                print("round ended, tile outline")
                eventTrove:Clean()
            end
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }

    return newMap
end

function LaserParkour.PlayAnimations(props: Format.animationProps)
    local random = Random.new(props.seed)
    local newMap = props.map
    local randomPattern = presetPatterns[random:NextInteger(1, #presetPatterns)]
    print("randomPattern", randomPattern)

    for _, tile in newMap.Tiles:GetChildren() do
        for _, child in tile:GetChildren() do
            if child:IsA("BasePart") then
                child.Transparency = 1
            end
        end
        tile:PivotTo(tile:GetPivot() + TILE_OFFSET)
    end

    task.wait(1)
    local playedSound = false
    local tileChildren = newMap.Tiles:GetChildren()
    for i = 1, #tileChildren do
        local tile = newMap.Tiles:FindFirstChild(tostring(i))
        -- Spring.target(tile, 0.7, 1.5, {
            -- Pivot = tile:GetPivot() - TILE_OFFSET,
        -- })
        for _, child in tile:GetChildren() do
            if child:IsA("BasePart") then
                Spring.target(child, 0.7, 1.5, {
                    Transparency = 0,
                    Position = child.Position - TILE_OFFSET,
                })
            end
        end

        if not playedSound then
            SoundUtils.playSound(Assets.SFX.Pop)
            playedSound = true
        end
        if i % 4 == 0 then
            task.wait(0.1)
            playedSound = false
        end
    end
end

return LaserParkour