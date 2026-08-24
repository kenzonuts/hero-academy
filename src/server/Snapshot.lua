--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))
local UpgradeConfig = require(Shared:WaitForChild("UpgradeConfig"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local Converter = require(script.Parent:WaitForChild("Converter"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Production = require(script.Parent:WaitForChild("Production"))

local Snapshot = {}

local function cloneCandidate(candidate: Types.Candidate): Types.Candidate
	return {
		CandidateID = candidate.CandidateID,
		HeroType = candidate.HeroType,
		Tier = candidate.Tier,
		Power = candidate.Power,
		Production = candidate.Production,
		AcceptCost = candidate.AcceptCost,
		CreatedAt = candidate.CreatedAt,
		Status = candidate.Status,
	}
end

local function pendingList(state: Types.PlayerState): { Types.Candidate }
	if state.PendingCandidates == nil then
		state.PendingCandidates = {}
		if state.PendingCandidate then
			table.insert(state.PendingCandidates, state.PendingCandidate)
		end
	end
	return state.PendingCandidates
end

function Snapshot.ForPlayer(player: Player): Types.PlayerSnapshot?
	local state = PlayerData.Get(player)
	if not state then
		return nil
	end

	Collection.EnsureDisplaySlots(state.Heroes)

	local converterUpgradeCost = UpgradeConfig.NextConverterCost(state.ConverterLevel)
	local converterNextSpeed: number? = nil
	if converterUpgradeCost then
		converterNextSpeed = Converter.GetSpeed(state.ConverterLevel + 1)
	end

	local bonusRemaining = 0
	local endsAt = state.ProductionBonusEndsAt
	if typeof(endsAt) == "number" then
		bonusRemaining = math.max(0, endsAt - os.time())
	end

	local activeRaid: Types.RaidSnapshot? = nil
	if state.ActiveRaid then
		local raid = state.ActiveRaid
		activeRaid = {
			RaidID = raid.RaidID,
			MapID = raid.MapID,
			MapName = raid.MapName,
			HeroIDs = raid.HeroIDs,
			TeamPower = raid.TeamPower,
			RecommendedPower = raid.RecommendedPower,
			SuccessChance = raid.SuccessChance,
			EndTime = raid.EndTime,
			RemainingSeconds = math.max(0, raid.EndTime - os.time()),
			Status = raid.Status,
		}
	end

	local pending = pendingList(state)
	local pendingClone: { Types.Candidate } = {}
	for _, candidate in pending do
		table.insert(pendingClone, cloneCandidate(candidate))
	end
	local maxPending = GameConfig.PendingCandidate.MaxActive
	if typeof(maxPending) ~= "number" or maxPending < 1 then
		maxPending = 10
	end
	local boardFull = #pending >= maxPending
	local rosterFull = #state.Heroes + #pending >= Collection.MaxOwned()

	return {
		Gold = state.Gold,
		MagicStone = state.MagicStone,
		MagicStoneCapacity = state.MagicStoneCapacity,
		ProductionPerSecond = Production.GetTotal(player),
		ConverterSpeed = Converter.GetSpeed(state.ConverterLevel),
		HeroCount = #state.Heroes,
		MaxOwnedHeroes = Collection.MaxOwned(),
		ActiveCount = Collection.CountByStatus(state.Heroes, "ACTIVE") or 0,
		BagCount = Collection.CountByStatus(state.Heroes, "BAGGED") or 0,
		RaidingCount = Collection.CountByStatus(state.Heroes, "RAIDING") or 0,
		Heroes = Collection.CloneHeroes(state.Heroes),
		RecruitmentLevel = state.RecruitmentLevel,
		RecruitmentUpgradeCost = UpgradeConfig.NextRecruitmentCost(state.RecruitmentLevel),
		ConverterLevel = state.ConverterLevel,
		ConverterUpgradeCost = converterUpgradeCost,
		ConverterNextSpeed = converterNextSpeed,
		RecruitFee = UpgradeConfig.RecruitFee(state.RecruitmentLevel),
		RecruitLocked = boardFull or rosterFull,
		PendingCandidate = pendingClone[1],
		PendingCandidates = pendingClone,
		RecruitTickets = state.RecruitTickets or 0,
		EliteTickets = state.EliteTickets or 0,
		ProductionBonusRemaining = bonusRemaining,
		ActiveRaid = activeRaid,
		LastRaidMessage = state.LastRaidMessage,
		LastRaidOk = state.LastRaidOk,
		AcademyName = if typeof(player:GetAttribute("AcademyName")) == "string"
			then player:GetAttribute("AcademyName") :: string
			else nil,
	}
end

return Snapshot
