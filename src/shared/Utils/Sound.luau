local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local SoundUtils = {}

function SoundUtils.playSound(soundID: number | Sound, parent: Instance?, pitchVariation: boolean?)

    local sound
    if typeof(soundID) == "Instance" then
        sound = soundID:Clone()
    elseif typeof(soundID) == "number" then
        sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(soundID)
    else
        warn("Invalid sound ID", soundID)
        return
    end
    
    if pitchVariation then
        sound.Pitch = Random.new():NextNumber(0.9, 1.1)
    end

    sound.SoundGroup = SoundService.SoundGroups.SFX
    sound.Parent = parent or workspace
    sound:Play()
    repeat task.wait() until sound.IsPlaying
    local soundLength = if sound.TimeLength <= 0 then 5 else sound.TimeLength
    -- print("soundLength", soundLength)
    Debris:AddItem(sound, soundLength)

    return sound
end

return SoundUtils