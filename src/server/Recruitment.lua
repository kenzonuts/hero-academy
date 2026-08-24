--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))
local UpgradeConfig = require(Shared:WaitForChild("UpgradeConfig"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local TIER_ORDER = { "B1", "B2", "B3", "B4", "B5", "B6", "B7" }

local Recruitment = {}

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

local function getAcceptFee(tier: string): number?
	local fees = GameConfig.Recruitment.AcceptFeeByTier
	if tier == "B1" then
		return fees.B1
	elseif tier == "B2" then
		return fees.B2
	elseif tier == "B3" then
		return fees.B3
	elseif tier == "B4" then
		return fees.B4
	elseif tier == "B5" then
		return fees.B5
	elseif tier == "B6" then
		return fees.B6
	elseif tier == "B7" then
		return fees.B7
	end
	return nil
end

local function getStatRange(tier: string): { Power: { number }, Production: { number } }?
	local ranges = GameConfig.Recruitment.StatRanges
	if tier == "B1" then
		return ranges.B1
	elseif tier == "B2" then
		return ranges.B2
	elseif tier == "B3" then
		return ranges.B3
	elseif tier == "B4" then
		return ranges.B4
	elseif tier == "B5" then
		return ranges.B5
	elseif tier == "B6" then
		return ranges.B6
	elseif tier == "B7" then
		return ranges.B7
	end
	return nil
end

local function getTierWeight(weights: any, tier: string): number
	local value = weights[tier]
	if typeof(value) == "number" then
		return value
	end
	return 0
end

local function getTierWeights(level: number): any
	local allWeights = GameConfig.Recruitment.TierWeights
	for current = level, 1, -1 do
		local weights = allWeights[current]
		if weights ~= nil then
			return weights
		end
	end
	return allWeights[1]
end

local function tierIndex(tier: string): number
	for index, name in TIER_ORDER do
		if name == tier then
			return index
		end
	end
	return 1
end

local function rollTier(level: number, minTier: string?): string
	local weights = getTierWeights(level)
	local minIndex = if minTier then tierIndex(minTier) else 1
	local total = 0
	for index, tier in TIER_ORDER do
		if index >= minIndex then
			total += getTierWeight(weights, tier)
		end
	end

	if total <= 0 then
		return minTier or "B1"
	end

	local roll = math.random() * total
	local acc = 0
	local fallback = minTier or "B1"
	for index, tier in TIER_ORDER do
		if index >= minIndex then
			local weight = getTierWeight(weights, tier)
			if weight > 0 then
				acc += weight
				fallback = tier
				if roll <= acc then
					return tier
				end
			end
		end
	end

	return fallback
end

local function rollHeroType(): string
	local types = GameConfig.Recruitment.HeroTypes
	return types[math.random(1, #types)]
end

local function rollStat(range: { number }): number
	return math.random(range[1], range[2])
end

local function generateCandidate(level: number, minTier: string?): Types.Candidate?
	local tier = rollTier(level, minTier)
	local range = getStatRange(tier)
	local acceptCost = getAcceptFee(tier)
	if not range or not acceptCost then
		return nil
	end

	return {
		CandidateID = HttpService:GenerateGUID(false),
		HeroType = rollHeroType(),
		Tier = tier,
		Power = rollStat(range.Power),
		Production = rollStat(range.Production),
		AcceptCost = acceptCost,
		CreatedAt = os.time(),
		Status = "PENDING",
	}
end

local function candidateToHero(candidate: Types.Candidate): Types.Hero
	return {
		HeroID = HttpService:GenerateGUID(false),
		HeroType = candidate.HeroType,
		Tier = candidate.Tier,
		Power = candidate.Power,
		Production = candidate.Production,
		AcceptCost = candidate.AcceptCost,
		Purchased = true,
		Status = "ACTIVE",
		DisplaySlot = nil,
		CreatedAt = os.time(),
	}
end

local function boardSlots(): number
	local maxActive = GameConfig.PendingCandidate.MaxActive
	if typeof(maxActive) == "number" and maxActive > 0 then
		return math.floor(maxActive)
	end
	return 10
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

local function syncHead(state: Types.PlayerState)
	local list = pendingList(state)
	state.PendingCandidate = list[1]
end

local function parsePullCount(mode: any, useTicket: boolean): number
	if useTicket then
		return 1
	end
	if mode == 5 or mode == "5" or mode == "5X" or mode == "x5" then
		return 5
	end
	if mode == 10 or mode == "10" or mode == "10X" or mode == "x10" then
		return 10
	end
	return 1
end

function Recruitment.Recruit(player: Player, mode: any): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local useElite = mode == "ELITE"
	local useTicket = mode == "TICKET" or useElite
	local count = parsePullCount(mode, useTicket)
	local list = pendingList(state)
	local slotsLeft = boardSlots() - #list
	local rosterLeft = Collection.MaxOwned() - #state.Heroes - #list

	if count > slotsLeft then
		return fail(
			"BOARD_FULL",
			string.format("Need %d empty board slots. Take or clear cards first.", count)
		)
	end
	if count > rosterLeft then
		return fail(
			"ROSTER_FULL",
			string.format(
				"Not enough roster space (%d/%d owned, %d pending). Sell a Hero first.",
				#state.Heroes,
				Collection.MaxOwned(),
				#list
			)
		)
	end

	local minTier: string? = nil
	if useElite then
		if state.EliteTickets < 1 then
			return fail("NO_TICKET", "No Elite Recruit Ticket.")
		end
		minTier = GameConfig.Recruitment.EliteTicketMinimumTier or "B3"
	elseif useTicket then
		if state.RecruitTickets < 1 then
			return fail("NO_TICKET", "No Recruit Ticket.")
		end
	else
		local fee = UpgradeConfig.RecruitFee(state.RecruitmentLevel) * count
		if state.Gold < fee then
			return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to recruit.", fee))
		end
	end

	local rolled: { Types.Candidate } = {}
	for _ = 1, count do
		local candidate = generateCandidate(state.RecruitmentLevel, minTier)
		if not candidate then
			return fail("GENERATE_FAILED", "Failed to generate candidate.")
		end
		table.insert(rolled, candidate)
	end

	if useElite then
		state.EliteTickets -= 1
	elseif useTicket then
		state.RecruitTickets -= 1
	else
		local fee = UpgradeConfig.RecruitFee(state.RecruitmentLevel) * count
		if not Economy.TrySpendGold(player, fee) then
			return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to recruit.", fee))
		end
	end

	for _, candidate in rolled do
		table.insert(list, candidate)
	end
	syncHead(state)

	local first = rolled[1]
	if first == nil then
		return fail("GENERATE_FAILED", "Failed to generate candidate.")
	end
	if useElite then
		return ok(string.format("Elite recruit: %s %s. Accept is free.", first.Tier, first.HeroType))
	elseif useTicket then
		return ok(string.format("Free recruit: %s %s. Accept is free.", first.Tier, first.HeroType))
	elseif count == 1 then
		return ok(string.format("Candidate rolled: %s %s. Accept is free.", first.Tier, first.HeroType))
	end
	return ok(string.format("Rolled %d candidates. Open, take, or clear them.", count))
end

function Recruitment.Accept(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local list = pendingList(state)
	if #list == 0 then
		return fail("NO_CANDIDATE", "No pending candidate.")
	end

	if #state.Heroes + #list > Collection.MaxOwned() then
		return fail(
			"ROSTER_FULL",
			string.format("Roster is full (%d/%d). Sell a Hero to take these cards.", #state.Heroes, Collection.MaxOwned())
		)
	end

	local chargeAccept = GameConfig.Recruitment.ChargeAcceptFee == true
	if chargeAccept then
		local total = 0
		for _, candidate in list do
			total += candidate.AcceptCost
		end
		if not Economy.TrySpendGold(player, total) then
			return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to accept. Cards saved.", total))
		end
	end

	local bagged = 0
	local first = list[1]
	for _, candidate in list do
		local hero = candidateToHero(candidate)
		Collection.PlaceOnDisplay(hero, state.Heroes)
		table.insert(state.Heroes, hero)
		if hero.Status == "BAGGED" then
			bagged += 1
		end
	end

	local taken = #list
	state.PendingCandidates = {}
	state.PendingCandidate = nil

	if taken == 1 and first then
		if bagged > 0 then
			return ok(string.format("Accepted %s %s. Display full — sent to Bag.", first.Tier, first.HeroType))
		end
		local hero = state.Heroes[#state.Heroes]
		return ok(string.format("Accepted %s %s on pad %d.", first.Tier, first.HeroType, hero.DisplaySlot or 0))
	end
	if bagged > 0 then
		return ok(string.format("Accepted %d heroes. Display full — some went to Bag.", taken))
	end
	return ok(string.format("Accepted %d heroes.", taken))
end

function Recruitment.Reject(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local list = pendingList(state)
	if #list == 0 then
		return fail("NO_CANDIDATE", "No pending candidate.")
	end

	local first = list[1]
	local cleared = #list
	state.PendingCandidates = {}
	state.PendingCandidate = nil
	if cleared == 1 and first then
		return ok(string.format("Rejected %s %s. Recruit fee is gone.", first.Tier, first.HeroType))
	end
	return ok(string.format("Cleared %d cards. Recruit fees are gone.", cleared))
end

return Recruitment
