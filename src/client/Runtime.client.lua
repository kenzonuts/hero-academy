--!strict

print("[HeroRecruitment] Client script starting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 15)
if sharedFolder == nil then
	warn("[HeroRecruitment] ReplicatedStorage.Shared missing. Connect Rojo to this place, then Stop and Play.")
	return
end

local Shared = sharedFolder
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

task.spawn(function()
	DisplayConfig.PreloadImages()
end)

local Hud = require(script.Parent:WaitForChild("Hud"))

Hud.Start(Remotes.Get(), function(_snapshot: Types.PlayerSnapshot) end)
print("[HeroRecruitment] Client ready")
