--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local UpgradeConfig = require(Shared:WaitForChild("UpgradeConfig"))

local Converter = require(script.Parent:WaitForChild("Converter"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Upgrades = {}

local function fail(errorCode: string, message: string): Types.ActionResult
	return {
		ok = false,
		error = errorCode,
		message = message,
	}
end

local function ok(message: string): Types.ActionResult
	return {
		ok = true,
		error = nil,
		message = message,
	}
end

function Upgrades.Recruitment(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local nextLevel = state.RecruitmentLevel + 1
	local cost = UpgradeConfig.NextRecruitmentCost(state.RecruitmentLevel)
	if not cost then
		return fail("MAX_LEVEL", string.format("Recruitment is maxed at Lv.%d.", state.RecruitmentLevel))
	end

	if not Economy.TrySpendGold(player, cost) then
		return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to upgrade Recruitment.", cost))
	end

	state.RecruitmentLevel = nextLevel
	return ok(string.format("Recruitment upgraded to Lv.%d.", nextLevel))
end

function Upgrades.Converter(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local nextLevel = state.ConverterLevel + 1
	local cost = UpgradeConfig.NextConverterCost(state.ConverterLevel)
	if not cost then
		return fail("MAX_LEVEL", string.format("Converter is maxed at Lv.%d.", state.ConverterLevel))
	end

	if not Economy.TrySpendGold(player, cost) then
		return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to upgrade Converter.", cost))
	end

	state.ConverterLevel = nextLevel
	local speed = Converter.GetSpeed(nextLevel)
	return ok(string.format("Converter upgraded to Lv.%d (%d/s). Ratio still 1:1.", nextLevel, speed))
end

return Upgrades
