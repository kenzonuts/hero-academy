--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))
local UpgradeConfig = require(Shared:WaitForChild("UpgradeConfig"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local SaveStore = require(script.Parent:WaitForChild("SaveStore"))

local SAVE_VERSION = 1
local MAX_HEROES = 200

local sessions: { [number]: Types.PlayerState } = {}

local PlayerData = {}

local function asNumber(value: any, fallback: number): number
	if typeof(value) == "number" and value == value and value > -math.huge and value < math.huge then
		return value
	end
	return fallback
end

local function asString(value: any, fallback: string): string
	if typeof(value) == "string" and value ~= "" then
		return value
	end
	return fallback
end

local function asBool(value: any, fallback: boolean): boolean
	if typeof(value) == "boolean" then
		return value
	end
	return fallback
end

local function clampInt(value: number, minValue: number, maxValue: number): number
	return math.clamp(math.floor(value), minValue, maxValue)
end

local function makeHero(seed: { HeroType: string, Tier: string, Power: number, Production: number }): Types.Hero
	return {
		HeroID = HttpService:GenerateGUID(false),
		HeroType = seed.HeroType,
		Tier = seed.Tier,
		Power = seed.Power,
		Production = seed.Production,
		AcceptCost = GameConfig.CatalogAcceptCost(seed.Tier),
		Purchased = false,
		Status = "ACTIVE",
		DisplaySlot = nil,
		CreatedAt = os.time(),
	}
end

local function newState(): Types.PlayerState
	local heroes: { Types.Hero } = {}
	for index, seed in GameConfig.Phase1.SeedHeroes do
		local hero = makeHero(seed)
		hero.DisplaySlot = index
		table.insert(heroes, hero)
	end

	return {
		Gold = GameConfig.Phase1.StartingGold,
		MagicStone = 0,
		BlackCrystal = 0,
		MagicStoneCapacity = GameConfig.Storage.DefaultCapacity,
		ConverterLevel = 1,
		RecruitmentLevel = GameConfig.Recruitment.StartingLevel,
		PendingCandidate = nil,
		PendingCandidates = {},
		Heroes = heroes,
		ActiveRaid = nil,
		RecruitTickets = 0,
		EliteTickets = 0,
		ProductionBonusEndsAt = 0,
		LastRaidMessage = nil,
		LastRaidOk = nil,
	}
end

local function decodeStatus(value: any): Types.HeroStatus
	if value == "ACTIVE" or value == "BAGGED" or value == "RAIDING" then
		return value
	end
	return "BAGGED"
end

local function decodeHero(raw: any): Types.Hero?
	if typeof(raw) ~= "table" then
		return nil
	end
	local slot = raw.DisplaySlot
	local displaySlot: number? = nil
	if typeof(slot) == "number" then
		displaySlot = math.floor(slot)
	end
	local hero: Types.Hero = {
		HeroID = asString(raw.HeroID, HttpService:GenerateGUID(false)),
		HeroType = asString(raw.HeroType, "Knight"),
		Tier = asString(raw.Tier, "B1"),
		Power = clampInt(asNumber(raw.Power, 10), 1, 1_000_000),
		Production = clampInt(asNumber(raw.Production, 1), 0, 1_000_000),
		AcceptCost = clampInt(asNumber(raw.AcceptCost, 0), 0, 1e12),
		Purchased = asBool(raw.Purchased, false),
		Status = decodeStatus(raw.Status),
		DisplaySlot = displaySlot,
		CreatedAt = clampInt(asNumber(raw.CreatedAt, os.time()), 0, 4e9),
	}
	if hero.AcceptCost <= 0 then
		hero.AcceptCost = GameConfig.CatalogAcceptCost(hero.Tier)
	end
	return hero
end

local function decodeCandidate(raw: any): Types.Candidate?
	if typeof(raw) ~= "table" then
		return nil
	end
	local status = raw.Status
	if status ~= "PENDING" then
		return nil
	end
	return {
		CandidateID = asString(raw.CandidateID, HttpService:GenerateGUID(false)),
		HeroType = asString(raw.HeroType, "Knight"),
		Tier = asString(raw.Tier, "B1"),
		Power = clampInt(asNumber(raw.Power, 10), 1, 1_000_000),
		Production = clampInt(asNumber(raw.Production, 1), 0, 1_000_000),
		AcceptCost = clampInt(asNumber(raw.AcceptCost, 0), 0, 1e12),
		CreatedAt = clampInt(asNumber(raw.CreatedAt, os.time()), 0, 4e9),
		Status = "PENDING",
	}
end

local function decodeRaid(raw: any, playerId: number): Types.Raid?
	if typeof(raw) ~= "table" then
		return nil
	end
	if raw.Status ~= "ACTIVE" then
		return nil
	end
	if typeof(raw.HeroIDs) ~= "table" or typeof(raw.HeroHomes) ~= "table" then
		return nil
	end
	local ids: { string } = {}
	local homes: { Types.RaidHeroHome } = {}
	for index, id in raw.HeroIDs do
		if typeof(id) == "string" and id ~= "" then
			table.insert(ids, id)
			local homeRaw = raw.HeroHomes[index]
			local slot: number? = nil
			local homeStatus: Types.HeroStatus = "ACTIVE"
			if typeof(homeRaw) == "table" then
				homeStatus = decodeStatus(homeRaw.Status)
				if homeStatus == "RAIDING" then
					homeStatus = "ACTIVE"
				end
				if typeof(homeRaw.DisplaySlot) == "number" then
					slot = math.floor(homeRaw.DisplaySlot)
				end
			end
			table.insert(homes, {
				Status = homeStatus,
				DisplaySlot = slot,
			})
		end
	end
	if #ids < 1 then
		return nil
	end
	return {
		RaidID = asString(raw.RaidID, HttpService:GenerateGUID(false)),
		PlayerID = playerId,
		MapID = asString(raw.MapID, "WhisperingForest"),
		MapName = asString(raw.MapName, "Whispering Forest"),
		HeroIDs = ids,
		HeroHomes = homes,
		TeamPower = clampInt(asNumber(raw.TeamPower, 0), 0, 1e9),
		RecommendedPower = clampInt(asNumber(raw.RecommendedPower, 1), 1, 1e9),
		SuccessChance = math.clamp(asNumber(raw.SuccessChance, 0.05), 0, 1),
		StartTime = clampInt(asNumber(raw.StartTime, os.time()), 0, 4e9),
		EndTime = clampInt(asNumber(raw.EndTime, os.time()), 0, 4e9),
		Status = "ACTIVE",
	}
end

local function decodeState(raw: any, playerId: number): Types.PlayerState?
	if typeof(raw) ~= "table" then
		return nil
	end
	if asNumber(raw.v, 0) < 1 then
		return nil
	end

	local heroes: { Types.Hero } = {}
	if typeof(raw.Heroes) == "table" then
		for _, item in raw.Heroes do
			if #heroes >= MAX_HEROES then
				break
			end
			local hero = decodeHero(item)
			if hero then
				table.insert(heroes, hero)
			end
		end
	end
	if #heroes == 0 then
		return nil
	end

	local maxRecruit = UpgradeConfig.RecruitmentMaxLevel()
	local maxConverter = UpgradeConfig.ConverterMaxLevel()
	local capacity = GameConfig.Storage and GameConfig.Storage.DefaultCapacity or 10000
	local maxPending = GameConfig.PendingCandidate.MaxActive
	if typeof(maxPending) ~= "number" or maxPending < 1 then
		maxPending = 10
	end

	local pendingList: { Types.Candidate } = {}
	if typeof(raw.PendingCandidates) == "table" then
		for _, item in raw.PendingCandidates do
			if #pendingList >= maxPending then
				break
			end
			local candidate = decodeCandidate(item)
			if candidate then
				table.insert(pendingList, candidate)
			end
		end
	else
		local candidate = decodeCandidate(raw.PendingCandidate)
		if candidate then
			table.insert(pendingList, candidate)
		end
	end

	local state: Types.PlayerState = {
		Gold = clampInt(asNumber(raw.Gold, 0), 0, 1e15),
		MagicStone = clampInt(asNumber(raw.MagicStone, 0), 0, 1e15),
		BlackCrystal = clampInt(asNumber(raw.BlackCrystal, 0), 0, 1e15),
		MagicStoneCapacity = clampInt(asNumber(raw.MagicStoneCapacity, capacity), 1, 1e15),
		ConverterLevel = clampInt(asNumber(raw.ConverterLevel, 1), 1, maxConverter),
		RecruitmentLevel = clampInt(asNumber(raw.RecruitmentLevel, 1), 1, maxRecruit),
		PendingCandidate = pendingList[1],
		PendingCandidates = pendingList,
		Heroes = heroes,
		ActiveRaid = decodeRaid(raw.ActiveRaid, playerId),
		RecruitTickets = clampInt(asNumber(raw.RecruitTickets, 0), 0, 9999),
		EliteTickets = clampInt(asNumber(raw.EliteTickets, 0), 0, 9999),
		ProductionBonusEndsAt = clampInt(asNumber(raw.ProductionBonusEndsAt, 0), 0, 4e9),
		LastRaidMessage = if typeof(raw.LastRaidMessage) == "string" then raw.LastRaidMessage else nil,
		LastRaidOk = if typeof(raw.LastRaidOk) == "boolean" then raw.LastRaidOk else nil,
	}

	if state.MagicStone > state.MagicStoneCapacity then
		state.MagicStone = state.MagicStoneCapacity
	end

	local raiding: { [string]: boolean } = {}
	if state.ActiveRaid then
		for _, id in state.ActiveRaid.HeroIDs do
			raiding[id] = true
		end
	end
	for _, hero in state.Heroes do
		if hero.Status == "RAIDING" and not raiding[hero.HeroID] then
			Collection.PlaceOnDisplay(hero, state.Heroes)
		elseif hero.Status ~= "ACTIVE" then
			hero.DisplaySlot = nil
		end
	end

	return state
end

function PlayerData.Serialize(state: Types.PlayerState): any
	local pending = state.PendingCandidates
	if pending == nil then
		pending = {}
		if state.PendingCandidate then
			table.insert(pending, state.PendingCandidate)
		end
		state.PendingCandidates = pending
	end
	return {
		v = SAVE_VERSION,
		Gold = state.Gold,
		MagicStone = state.MagicStone,
		BlackCrystal = state.BlackCrystal or 0,
		MagicStoneCapacity = state.MagicStoneCapacity,
		ConverterLevel = state.ConverterLevel,
		RecruitmentLevel = state.RecruitmentLevel,
		PendingCandidate = pending[1],
		PendingCandidates = pending,
		Heroes = Collection.CloneHeroes(state.Heroes),
		ActiveRaid = state.ActiveRaid,
		RecruitTickets = state.RecruitTickets or 0,
		EliteTickets = state.EliteTickets or 0,
		ProductionBonusEndsAt = state.ProductionBonusEndsAt or 0,
		LastRaidMessage = state.LastRaidMessage,
		LastRaidOk = state.LastRaidOk,
	}
end

function PlayerData.Init(player: Player): Types.PlayerState
	local existing = sessions[player.UserId]
	if existing then
		return existing
	end

	local loaded = SaveStore.Load(player.UserId)
	local state = decodeState(loaded, player.UserId)
	if state then
		print(string.format("[Save] Loaded %s | Gold=%d | Heroes=%d", player.Name, state.Gold, #state.Heroes))
	else
		state = newState()
		print(string.format("[Save] New profile %s", player.Name))
	end

	sessions[player.UserId] = state
	return state
end

function PlayerData.Get(player: Player): Types.PlayerState?
	local state = sessions[player.UserId]
	if not state then
		return nil
	end
	if state.RecruitTickets == nil then
		state.RecruitTickets = 0
	end
	if state.EliteTickets == nil then
		state.EliteTickets = 0
	end
	if state.ProductionBonusEndsAt == nil then
		state.ProductionBonusEndsAt = 0
	end
	if state.PendingCandidates == nil then
		state.PendingCandidates = {}
		if state.PendingCandidate then
			table.insert(state.PendingCandidates, state.PendingCandidate)
		end
	end
	if state.PendingCandidate == nil and #state.PendingCandidates > 0 then
		state.PendingCandidate = state.PendingCandidates[1]
	end
	return state
end

function PlayerData.Save(player: Player): boolean
	local state = sessions[player.UserId]
	if not state then
		return false
	end
	return SaveStore.Save(player.UserId, PlayerData.Serialize(state))
end

function PlayerData.SaveAll()
	for userId, state in sessions do
		SaveStore.Save(userId, PlayerData.Serialize(state))
	end
end

function PlayerData.Remove(player: Player)
	PlayerData.Save(player)
	sessions[player.UserId] = nil
end

return PlayerData
