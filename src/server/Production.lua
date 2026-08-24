--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Production = {}

function Production.GetTotal(player: Player): number
	local state = PlayerData.Get(player)
	if not state then
		return 0
	end

	local total = Collection.SumActiveProduction(state.Heroes)
	local endsAt = state.ProductionBonusEndsAt
	if typeof(endsAt) == "number" and os.time() < endsAt then
		local bonus = GameConfig.Raid and GameConfig.Raid.ProductionBonus
		local multiplier = if bonus and typeof(bonus.Multiplier) == "number" then bonus.Multiplier else 1.2
		total *= multiplier
	end
	return total
end

function Production.Tick(player: Player, dt: number)
	if dt <= 0 then
		return
	end

	Economy.AddMagicStone(player, Production.GetTotal(player) * dt)
end

return Production
