--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Converter = {}

function Converter.GetSpeed(level: number): number
	local speeds = GameConfig.Converter.SpeedByLevel
	return speeds[level] or speeds[1] or 0
end

function Converter.Tick(player: Player, dt: number)
	if dt <= 0 then
		return
	end

	local state = PlayerData.Get(player)
	if not state then
		return
	end

	local processed = Economy.RemoveMagicStone(player, Converter.GetSpeed(state.ConverterLevel) * dt)
	if processed <= 0 then
		return
	end

	Economy.AddGold(player, processed * GameConfig.Conversion.MagicStoneToGold)
end

return Converter
