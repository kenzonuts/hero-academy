--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FALLBACK_RECRUIT_COST = {
	[2] = 500,
	[3] = 2500,
	[4] = 10000,
	[5] = 40000,
}

local FALLBACK_CONVERTER_COST = {
	[2] = 400,
	[3] = 1500,
	[4] = 6000,
	[5] = 20000,
}

local UpgradeConfig = {}

local function tableMaxKey(values: any, fallback: number): number
	if typeof(values) ~= "table" then
		return fallback
	end
	local highest = 0
	for key in values do
		if typeof(key) == "number" and key > highest then
			highest = key
		end
	end
	if highest > 0 then
		return highest
	end
	return fallback
end

local function costAt(costs: any, fallback: { [number]: number }, nextLevel: number): number?
	if typeof(costs) == "table" then
		local value = costs[nextLevel]
		if typeof(value) == "number" and value > 0 then
			return value
		end
	end
	local fb = fallback[nextLevel]
	if typeof(fb) == "number" and fb > 0 then
		return fb
	end
	return nil
end

function UpgradeConfig.RecruitmentMaxLevel(): number
	local recruitment = GameConfig.Recruitment
	local configured = recruitment and recruitment.MaxLevel
	if typeof(configured) == "number" and configured > 0 then
		return configured
	end
	return tableMaxKey(recruitment and recruitment.UpgradeCostGold, 5)
end

function UpgradeConfig.ConverterMaxLevel(): number
	local converter = GameConfig.Converter
	local configured = converter and converter.MaxLevel
	if typeof(configured) == "number" and configured > 0 then
		return configured
	end
	return tableMaxKey(converter and converter.SpeedByLevel, 5)
end

function UpgradeConfig.RecruitmentCostTo(nextLevel: number): number?
	local recruitment = GameConfig.Recruitment
	return costAt(recruitment and recruitment.UpgradeCostGold, FALLBACK_RECRUIT_COST, nextLevel)
end

function UpgradeConfig.ConverterCostTo(nextLevel: number): number?
	local converter = GameConfig.Converter
	return costAt(converter and converter.UpgradeCostGold, FALLBACK_CONVERTER_COST, nextLevel)
end

function UpgradeConfig.NextRecruitmentCost(currentLevel: number): number?
	local nextLevel = currentLevel + 1
	if nextLevel > UpgradeConfig.RecruitmentMaxLevel() then
		return nil
	end
	return UpgradeConfig.RecruitmentCostTo(nextLevel)
end

function UpgradeConfig.NextConverterCost(currentLevel: number): number?
	local nextLevel = currentLevel + 1
	if nextLevel > UpgradeConfig.ConverterMaxLevel() then
		return nil
	end
	return UpgradeConfig.ConverterCostTo(nextLevel)
end

function UpgradeConfig.RecruitFee(level: number): number
	local recruitment = GameConfig.Recruitment
	local fees = recruitment and recruitment.RecruitFeeByLevel
	local clamped = math.max(1, math.floor(level))
	if typeof(fees) == "table" then
		for lv = clamped, 1, -1 do
			local value = fees[lv]
			if typeof(value) == "number" and value > 0 then
				return value
			end
		end
	end
	local fallback = recruitment and recruitment.RecruitFeeGold
	if typeof(fallback) == "number" and fallback > 0 then
		return fallback
	end
	return 100
end

return UpgradeConfig
