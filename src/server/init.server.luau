local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Packages.Loader)

local ServerScriptService = game:GetService("ServerScriptService")
local Services = Loader.LoadChildren(ServerScriptService.Server.Services)

for _, module in Services do
    local initFunction = module.init
    if typeof(initFunction) == "function" then
        task.spawn(initFunction)
    end
end

return Services