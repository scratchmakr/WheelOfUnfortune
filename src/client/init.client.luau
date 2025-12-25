local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Packages.Loader)

local StarterPlayer = game:GetService("StarterPlayer")
local Controllers = StarterPlayer.StarterPlayerScripts.Client.Controllers
local controllerModules = Loader.LoadChildren(Controllers)

for _, module in controllerModules do
    local initFunction = module.init
    if typeof(initFunction) == "function" then
        initFunction()
    end
end

return controllerModules