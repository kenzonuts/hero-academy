--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FALLBACK_MAPS = {
	{
		Id = "WhisperingForest",
		DisplayName = "Whispering Forest",
		RecommendedPower = 500,
		DurationSeconds = 180,
		BaseGoldReward = 50000,
	},
}

local RaidConfig = {}

function RaidConfig.MinHeroes(): number
	local raid = GameConfig.Raid
	local value = raid and raid.MinHeroes
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return 1
end

function RaidConfig.MaxHeroes(): number
	local raid = GameConfig.Raid
	local value = raid and raid.MaxHeroes
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return 5
end

function RaidConfig.Maps(): { any }
	local raid = GameConfig.Raid
	local maps = raid and raid.Maps
	if typeof(maps) == "table" and #maps > 0 then
		return maps
	end
	return FALLBACK_MAPS
end

function RaidConfig.GetMap(mapId: string): any?
	for _, map in RaidConfig.Maps() do
		if typeof(map) == "table" and map.Id == mapId then
			return map
		end
	end
	return nil
end

function RaidConfig.BaseDurationSeconds(map: any): number
	local seconds = if typeof(map) == "table" then map.DurationSeconds else nil
	if typeof(seconds) ~= "number" or seconds < 1 then
		seconds = 180
	end
	return math.max(1, math.floor(seconds))
end

function RaidConfig.DurationScale(teamPower: number, recommended: number): number
	local ratio = RaidConfig.PowerRatio(teamPower, recommended)
	local tuning = GameConfig.Raid and GameConfig.Raid.DurationByPower
	local startRatio = 1
	local maxRatio = 1.5
	local minPercent = 0.5
	if typeof(tuning) == "table" then
		if typeof(tuning.SpeedStartRatio) == "number" then
			startRatio = tuning.SpeedStartRatio
		end
		if typeof(tuning.SpeedMaxRatio) == "number" then
			maxRatio = tuning.SpeedMaxRatio
		end
		if typeof(tuning.MinDurationPercent) == "number" then
			minPercent = tuning.MinDurationPercent
		end
	end
	if maxRatio <= startRatio then
		return 1
	end
	if ratio <= startRatio then
		return 1
	end
	if ratio >= maxRatio then
		return minPercent
	end
	local t = (ratio - startRatio) / (maxRatio - startRatio)
	return 1 - t * (1 - minPercent)
end

function RaidConfig.DurationSeconds(map: any, teamPower: number?): number
	local base = RaidConfig.BaseDurationSeconds(map)
	if typeof(teamPower) ~= "number" then
		return base
	end
	local recommended = if typeof(map) == "table" and typeof(map.RecommendedPower) == "number" then map.RecommendedPower else 0
	local scale = RaidConfig.DurationScale(teamPower, recommended)
	return math.max(1, math.floor(base * scale))
end

function RaidConfig.PowerRatio(teamPower: number, recommended: number): number
	if recommended <= 0 then
		return 0
	end
	return teamPower / recommended
end

function RaidConfig.SuccessChance(teamPower: number, recommended: number): number
	local ratio = RaidConfig.PowerRatio(teamPower, recommended)
	local rows = GameConfig.Raid and GameConfig.Raid.SuccessByMinRatio
	if typeof(rows) == "table" then
		for _, row in rows do
			if typeof(row) == "table" and typeof(row.MinRatio) == "number" and typeof(row.Chance) == "number" then
				if ratio >= row.MinRatio then
					return row.Chance
				end
			end
		end
	end
	if ratio >= 1.5 then
		return 1
	elseif ratio >= 1.25 then
		return 0.95
	elseif ratio >= 1 then
		return 0.85
	elseif ratio >= 0.75 then
		return 0.6
	elseif ratio >= 0.5 then
		return 0.35
	elseif ratio >= 0.25 then
		return 0.1
	end
	return 0.05
end

function RaidConfig.RollBonusLoot(): string
	local entries = GameConfig.Raid and GameConfig.Raid.BonusLoot
	if typeof(entries) ~= "table" then
		return "Gold"
	end
	local total = 0
	for _, entry in entries do
		if typeof(entry) == "table" and typeof(entry.Weight) == "number" then
			total += entry.Weight
		end
	end
	if total <= 0 then
		return "Gold"
	end
	local roll = math.random() * total
	local acc = 0
	local fallback = "Gold"
	for _, entry in entries do
		if typeof(entry) == "table" and typeof(entry.Weight) == "number" and typeof(entry.Id) == "string" then
			acc += entry.Weight
			fallback = entry.Id
			if roll <= acc then
				return entry.Id
			end
		end
	end
	return fallback
end

function RaidConfig.BlackCrystalEventActive(): boolean
	local event = GameConfig.Event
	return event ~= nil and event.BlackCrystalRaid == true
end

function RaidConfig.BlackCrystalReward(map: any): number
	if not RaidConfig.BlackCrystalEventActive() then
		return 0
	end
	if typeof(map) == "table" and typeof(map.BlackCrystalReward) == "number" then
		return math.max(0, math.floor(map.BlackCrystalReward))
	end
	return 0
end

return RaidConfig
