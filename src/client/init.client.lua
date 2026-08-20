--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Hud = require(script:WaitForChild("Hud"))

Hud.Start(Remotes.Get())
print("[HeroRecruitment] Client ready")
