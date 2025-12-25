local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Network = require(ReplicatedStorage.Shared.Network)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.Character)
local Circles = require(ReplicatedStorage.Shared.Utils.Circles)

local StarterPlayer = game:GetService("StarterPlayer")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(ReplicatedStorage.Shared.Utils.Sound)

local Assets = ReplicatedStorage.Shared.Assets
local SansLasersAssets = Assets.SansLasers
local GasterBlaster = SansLasersAssets.GasterBlaster
local RadiusPart = SansLasersAssets.Radius

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local SansLasers = {}
local CYCLES = 5
local BACK_DISTANCE = 20
local RATE = 0.03
local BLASTERS_PER_CYCLE = 75
local SURVIVAL_TIME = math.round(CYCLES * (RATE * BLASTERS_PER_CYCLE))
local DAMAGE = 15

local radius = RadiusPart.Size.Y / 2
local center = RadiusPart.Position
    
local slices = 50
local step = (2 * math.pi) / slices

print("SURVIVAL_TIME", SURVIVAL_TIME)
function SansLasers.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local playersAlive = props.playersAlive
    eventTrove:Add(function()
        for _, player in playersAlive do
            props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersAlive)
        props.roundEnded = true
    end)

    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Survive the lasers!", workspace.DistributedGameTime + SURVIVAL_TIME)
    end

    local startTime = workspace.DistributedGameTime + 0.75 -- max latency
    local animationProps: Format.animationProps = {
        map = nil,
        eventKey = props.eventKey,
        startTime = startTime,
    }

    

    for _, player in Players:GetPlayers() do
        Network.PlayEventAnimations:Server():Fire(player, animationProps)
    end
    task.spawn(function()
        while workspace.DistributedGameTime < startTime do
            RunService.Heartbeat:Wait()
        end

        local totalShots = CYCLES * slices
        local shotIndex = 0
        local lastShotTime = startTime

        while shotIndex < totalShots do
            lastShotTime += RATE
            shotIndex += 1
            -- print("shotIndex", shotIndex)
            local sliceIndex = (shotIndex - 1) % slices
            local origin, direction = Circles.computeRayForSlice(sliceIndex, slices, center, radius)
    
            local allCharacters = {}
            for _, plr in ipairs(playersAlive) do
                local char = plr.Character
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(allCharacters, char)
                end
            end
    
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Include
            raycastParams.FilterDescendantsInstances = allCharacters
            local raycastResult = workspace:Raycast(origin, direction, raycastParams)
            if raycastResult then
                print("raycast hit", raycastResult.Instance.Name)
                local hit = raycastResult.Instance
                local humanoid = hit and hit.Parent:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.Health -= DAMAGE
                end
            end

            task.wait(RATE)
        end
    end)

    task.delay(SURVIVAL_TIME, function()
        eventTrove:Clean()
    end)
end

function SansLasers.PlayAnimations(props: Format.animationProps) -- client
    local localPlayer = Players.LocalPlayer
    local startTime = props.startTime

    -- wait until synced start
	while workspace.DistributedGameTime < startTime do
		RunService.Heartbeat:Wait()
	end

    local times = 0
    repeat
        times += 1
        for i = 0, slices - 1 do
            local angle = i * step
        
            local edgePoint = center + Vector3.new(
                math.cos(angle),
                0,
                math.sin(angle)
            ) * radius
            local lookAtCF = CFrame.lookAt(edgePoint, center)
            local newBlaster = GasterBlaster:Clone()

            for _, part in newBlaster:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end

            newBlaster.Parent = workspace
            newBlaster:PivotTo(CFrame.new(edgePoint) * CFrame.Angles(lookAtCF:ToEulerAngles()) * CFrame.new(0, 0, BACK_DISTANCE))

            -- SoundUtils.playSound(SansLasersAssets.Charge, workspace)
            Spring.target(newBlaster, 1.1, 1, {
                Pivot = newBlaster:GetPivot() * CFrame.new(0, 0, -BACK_DISTANCE)
            })

            for _, part in newBlaster:GetDescendants() do
                if part:IsA("BasePart") and part.Name ~= "Blaster" and part.Name ~= "Hitbox" then
                    Spring.target(part, 1, 3, {
                        Transparency = 0
                    })
                end
            end

            -- print("blaster spawned")
            Spring.stop(newBlaster.Blast)
            newBlaster.Blast.Transparency = 0
            Spring.target(newBlaster.Blast, 1, 2, {
                Transparency = 1
            })
            -- local raycastParams = RaycastParams.new()
            -- raycastParams.FilterType = Enum.RaycastFilterType.Include
            -- raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
            -- local raycastResult = workspace:Raycast(newBlaster.Hitbox.Position, lookAtCF.LookVector * 100, raycastParams)
            -- if raycastResult then
            --     -- print("raycast hit", raycastResult.Instance.Name)
            --     local hit = raycastResult.Instance
            --     local humanoid = hit and hit.Parent:FindFirstChildWhichIsA("Humanoid")
            --     if humanoid then
            --         humanoid.Health -= DAMAGE
            --     end
            --     Network.TakeDamage:Client():Fire(localPlayer, DAMAGE)
            -- end

            task.delay(0.75, function()
                SoundUtils.playSound(SansLasersAssets.Shoot, workspace)
                Spring.target(newBlaster, 1.1, 1.5, {
                    Pivot = newBlaster:GetPivot() * CFrame.new(0, 0, BACK_DISTANCE)
                })
    
                for _, part in newBlaster:GetDescendants() do
                    if part:IsA("BasePart") and part.Name ~= "Blaster" then
                        Spring.target(part, 1, 3, {
                            Transparency = 1
                        })
                    end
                end
            end)

            task.wait(RATE)
        end
        print("blasters spawned", times)
    until times >= CYCLES
end

return SansLasers