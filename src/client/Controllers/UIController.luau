local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterPlayer = game:GetService("StarterPlayer")

local UIController = {}

function UIController.init()
    print("UIController initialized")

    for _, module in StarterPlayer.StarterPlayerScripts.Client.UI:GetChildren() do
        local initFunction = require(module)
        print("initFunction", initFunction, typeof(initFunction))
        if typeof(initFunction) == "function" then
            initFunction()
        end
    end
end

return UIController