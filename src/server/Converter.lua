--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Converter = {}

function Converter.GetSpeed(level: number): number
	local speeds = GameConfig.Converter.SpeedByLevel
	local current = math.floor(level)
	while current >= 1 do
		local value = speeds[current]
		if typeof(value) == "number" then
			return value
		end
		current -= 1
	end
	return 10
end

function Converter.Tick(player: Player, dt: number)
	if dt <= 0 then
		return
	end

	local state = PlayerData.Get(player)
	if not state then
		return
	end

	local budget = Converter.GetSpeed(state.ConverterLevel) * dt
	if budget <= 0 then
		return
	end

	local fromBlack = Economy.RemoveBlackCrystal(player, budget)
	if fromBlack > 0 then
		local ratio = GameConfig.Conversion.BlackCrystalToGold
		if typeof(ratio) ~= "number" or ratio < 1 then
			ratio = 10
		end
		Economy.AddGold(player, fromBlack * ratio)
		budget -= fromBlack
	end
	if budget <= 0 then
		return
	end

	local fromStone = Economy.RemoveMagicStone(player, budget)
	if fromStone > 0 then
		Economy.AddGold(player, fromStone * GameConfig.Conversion.MagicStoneToGold)
	end
end

return Converter
