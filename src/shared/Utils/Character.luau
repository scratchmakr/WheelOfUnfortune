local CharacterUtils = {}

function CharacterUtils.getPositionWithinPlatform(platform: Part, randomY: boolean?, seed: number?)
    local random = seed and Random.new(seed) or Random.new()
    local x1, z1 = platform.Position.X + platform.Size.X / 2, platform.Position.Z + platform.Size.Z / 2
    local y1, y2 = platform.Position.Y + platform.Size.Y / 2, platform.Position.Y - platform.Size.Y / 2
    local x2, z2 = platform.Position.X - platform.Size.X / 2, platform.Position.Z - platform.Size.Z / 2
    local randX, randY, randZ = random:NextNumber(math.min(x1, x2), math.max(x1, x2)), random:NextNumber(math.min(y1, y2), math.max(y1, y2)), random:NextNumber(math.min(z1, z2), math.max(z1, z2))
    return Vector3.new(randX, randomY and randY or platform.Position.Y, randZ)
end

function CharacterUtils.teleportWithinPlatform(character: Model, platform: Part)
    if not (character and platform) then
        return warn(`Unable to teleport character onto platform`, character, platform)
    end
    
    local spawnPosition = CharacterUtils.getPositionWithinPlatform(platform, false)
    local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")
    local humanoid = humanoidRootPart and character:WaitForChild("Humanoid")
    if humanoid then
        humanoidRootPart.CFrame = CFrame.new(spawnPosition) * CFrame.Angles(platform.CFrame:ToEulerAngles())
        return true
    end

    return false
end

function CharacterUtils.getMass(character: Model)
    local totalMass = 0

    for _, descendant in character:GetDescendants() do
        if descendant:IsA("BasePart") then
            totalMass += descendant:GetMass()
        end
    end

    return totalMass
end

function CharacterUtils.toggleVisibility(character: Model, toggle: boolean?)
    toggle = not not toggle
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            descendant.Transparency = toggle and 1 or 0
        end

        if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            descendant.Enabled = toggle
        end
    end
end

return CharacterUtils