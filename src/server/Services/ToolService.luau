local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Shared.Assets
local ToolAssets = Assets:WaitForChild("Tools")

local ToolService = {}

function ToolService.givePlayerTool(player: Player, toolName: string, equip: boolean?)
    local tool = ToolAssets:FindFirstChild(toolName)
    if tool then
        local character = player.Character
        local alreadyHasTool = not not (player.Backpack:FindFirstChild(toolName) or (character and character:FindFirstChild(toolName)))
        if alreadyHasTool then
            return
        end
        
        local toolInstance = tool:Clone()
        toolInstance.Parent = equip and character or player.Backpack
    end
end

function ToolService.revokePlayerTool(player: Player, toolName: string)
    local tool = ToolAssets:FindFirstChild(toolName)
    if tool then
        local ancestors = {player.Character, player.Backpack}
        for _, ancestor in ancestors do
            for _, toolInstance in ancestor:GetChildren() do
                if toolInstance:IsA("Tool") and toolInstance.Name == toolName then
                    toolInstance:Destroy()
                end
            end
        end
    end
end

return ToolService