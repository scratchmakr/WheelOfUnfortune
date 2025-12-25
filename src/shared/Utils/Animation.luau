local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationUtils = {}

function AnimationUtils.LoadAnimation(character: Model, animation: Animation): AnimationTrack?
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChild("Animator")
    if animator then
        return animator:LoadAnimation(animation)
    end
    return nil
end

function AnimationUtils.PlayAnimation(character: Model, animation: AnimationTrack)
    animation:Play()
end

return AnimationUtils