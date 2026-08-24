--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RaidConfig = require(Shared:WaitForChild("RaidConfig"))
local Types = require(Shared:WaitForChild("Types"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Raid = {}

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

local function parseHeroIds(heroIds: any): { string }?
	if typeof(heroIds) ~= "table" then
		return nil
	end
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, value in heroIds do
		if typeof(value) ~= "string" or value == "" then
			return nil
		end
		if seen[value] then
			return nil
		end
		seen[value] = true
		table.insert(ids, value)
	end
	return ids
end

local function grantProductionBonus(state: Types.PlayerState)
	local bonus = GameConfig.Raid and GameConfig.Raid.ProductionBonus
	local duration = if bonus and typeof(bonus.DurationSeconds) == "number" then bonus.DurationSeconds else 600
	if duration < 1 then
		return
	end
	state.ProductionBonusEndsAt = os.time() + math.floor(duration)
end

local function applyBonusLoot(player: Player, state: Types.PlayerState, map: any): string
	local lootId = RaidConfig.RollBonusLoot()
	local baseGold = if typeof(map.BaseGoldReward) == "number" then map.BaseGoldReward else 0
	local goldPercent = GameConfig.Raid.BonusGoldPercent
	if typeof(goldPercent) ~= "number" then
		goldPercent = 0.25
	end
	local stoneAmount = GameConfig.Raid.BonusMagicStone
	if typeof(stoneAmount) ~= "number" then
		stoneAmount = 2500
	end

	if lootId == "MagicStone" then
		local added = Economy.AddMagicStone(player, stoneAmount)
		return string.format("+%d Magic Stone", added)
	elseif lootId == "RecruitTicket" then
		state.RecruitTickets += 1
		return "Recruit Ticket x1"
	elseif lootId == "EliteRecruitTicket" then
		state.EliteTickets += 1
		return "Elite Recruit Ticket x1"
	end

	local extraGold = math.floor(baseGold * goldPercent)
	if extraGold > 0 then
		Economy.AddGold(player, extraGold)
	end
	return string.format("+%d bonus Gold", extraGold)
end

local function resolve(player: Player, state: Types.PlayerState)
	local raid = state.ActiveRaid
	if not raid or raid.Status ~= "ACTIVE" then
		return
	end

	local success = math.random() <= raid.SuccessChance
	Collection.ReturnRaidParty(state.Heroes, raid)

	if success then
		raid.Status = "SUCCESS"
		local map = RaidConfig.GetMap(raid.MapID)
		local baseGold = 0
		local parts = { "RAID SUCCESS" }
		if map then
			table.insert(parts, map.DisplayName or raid.MapName)
			baseGold = if typeof(map.BaseGoldReward) == "number" then map.BaseGoldReward else 0
			if baseGold > 0 then
				Economy.AddGold(player, baseGold)
				table.insert(parts, string.format("+%d Gold", baseGold))
			end
			if map.GuaranteesEliteTicket == true then
				state.EliteTickets += 1
				table.insert(parts, "Elite Ticket")
			end
			table.insert(parts, applyBonusLoot(player, state, map))
		end
		grantProductionBonus(state)
		table.insert(parts, "+20% production")
		state.LastRaidOk = true
		state.LastRaidMessage = table.concat(parts, " · ")
	else
		raid.Status = "FAILED"
		state.LastRaidOk = false
		state.LastRaidMessage = string.format("RAID FAILED · %s · no reward, Heroes safe", raid.MapName)
	end

	state.ActiveRaid = nil
end

function Raid.Tick(player: Player)
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	local raid = state.ActiveRaid
	if not raid or raid.Status ~= "ACTIVE" then
		return
	end
	if os.time() >= raid.EndTime then
		resolve(player, state)
	end
end

function Raid.Start(player: Player, mapId: any, heroIds: any): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	if state.ActiveRaid ~= nil then
		return fail("RAID_ACTIVE", "A Raid is already in progress.")
	end

	if typeof(mapId) ~= "string" or mapId == "" then
		return fail("BAD_MAP", "Pick a Raid map.")
	end

	local map = RaidConfig.GetMap(mapId)
	if not map then
		return fail("BAD_MAP", "Unknown Raid map.")
	end

	local ids = parseHeroIds(heroIds)
	if not ids then
		return fail("BAD_TEAM", "Pick 1 to 5 Heroes.")
	end

	local minHeroes = RaidConfig.MinHeroes()
	local maxHeroes = RaidConfig.MaxHeroes()
	if #ids < minHeroes or #ids > maxHeroes then
		return fail("BAD_TEAM", string.format("Raid team must be %d to %d Heroes.", minHeroes, maxHeroes))
	end

	local team: { Types.Hero } = {}
	local teamPower = 0
	for _, heroId in ids do
		local _, hero = Collection.FindHero(state.Heroes, heroId)
		if not hero then
			return fail("NO_HERO", "One of the selected Heroes was not found.")
		end
		if hero.Status == "RAIDING" then
			return fail("ALREADY_RAIDING", string.format("%s is already raiding.", hero.HeroType))
		end
		if hero.Status ~= "ACTIVE" and hero.Status ~= "BAGGED" then
			return fail("BAD_STATUS", "That Hero cannot raid.")
		end
		table.insert(team, hero)
		teamPower += hero.Power
	end

	local recommended = if typeof(map.RecommendedPower) == "number" then map.RecommendedPower else 1
	local chance = RaidConfig.SuccessChance(teamPower, recommended)
	local now = os.time()
	local duration = RaidConfig.DurationSeconds(map, teamPower)
	local homes: { Types.RaidHeroHome } = {}
	for _, hero in team do
		table.insert(homes, {
			Status = hero.Status,
			DisplaySlot = hero.DisplaySlot,
		})
		hero.Status = "RAIDING"
		hero.DisplaySlot = nil
	end

	state.ActiveRaid = {
		RaidID = HttpService:GenerateGUID(false),
		PlayerID = player.UserId,
		MapID = map.Id,
		MapName = map.DisplayName or map.Id,
		HeroIDs = ids,
		HeroHomes = homes,
		TeamPower = teamPower,
		RecommendedPower = recommended,
		SuccessChance = chance,
		StartTime = now,
		EndTime = now + duration,
		Status = "ACTIVE",
	}
	state.LastRaidMessage = nil
	state.LastRaidOk = nil

	return ok(string.format(
		"Raid started: %s · %d Heroes · %d%% chance · %ds",
		state.ActiveRaid.MapName,
		#ids,
		math.floor(chance * 100 + 0.5),
		duration
	))
end

return Raid
