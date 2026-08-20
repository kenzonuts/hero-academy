--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

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

local function rollTier(level: number): string
	local weights = GameConfig.Recruitment.TierWeights[level] or GameConfig.Recruitment.TierWeights[1]
	local total = 0
	for _, tier in TIER_ORDER do
		total += getTierWeight(weights, tier)
	end

	if total <= 0 then
		return "B1"
	end

	local roll = math.random() * total
	local acc = 0
	local fallback = "B1"
	for _, tier in TIER_ORDER do
		local weight = getTierWeight(weights, tier)
		if weight > 0 then
			acc += weight
			fallback = tier
			if roll <= acc then
				return tier
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

local function generateCandidate(level: number): Types.Candidate?
	local tier = rollTier(level)
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
		Status = "ACTIVE",
		CreatedAt = os.time(),
	}
end

function Recruitment.Recruit(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	if state.PendingCandidate ~= nil then
		return fail("PENDING_EXISTS", "Accept or reject the current candidate first.")
	end

	local fee = GameConfig.Recruitment.RecruitFeeGold
	if not Economy.TrySpendGold(player, fee) then
		return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to recruit.", fee))
	end

	local candidate = generateCandidate(state.RecruitmentLevel)
	if not candidate then
		Economy.AddGold(player, fee)
		return fail("GENERATE_FAILED", "Failed to generate candidate.")
	end

	state.PendingCandidate = candidate
	return ok(string.format("Candidate rolled: %s %s.", candidate.Tier, candidate.HeroType))
end

function Recruitment.Accept(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local candidate = state.PendingCandidate
	if not candidate or candidate.Status ~= "PENDING" then
		return fail("NO_CANDIDATE", "No pending candidate.")
	end

	if state.Gold < candidate.AcceptCost then
		return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to accept. Candidate saved.", candidate.AcceptCost))
	end

	if not Economy.TrySpendGold(player, candidate.AcceptCost) then
		return fail("NOT_ENOUGH_GOLD", string.format("Need %d Gold to accept. Candidate saved.", candidate.AcceptCost))
	end

	local hero = candidateToHero(candidate)
	table.insert(state.Heroes, hero)
	state.PendingCandidate = nil

	return ok(string.format("Accepted %s %s.", hero.Tier, hero.HeroType))
end

function Recruitment.Reject(player: Player): Types.ActionResult
	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local candidate = state.PendingCandidate
	if not candidate then
		return fail("NO_CANDIDATE", "No pending candidate.")
	end

	state.PendingCandidate = nil
	return ok(string.format("Rejected %s %s. Recruit fee is gone.", candidate.Tier, candidate.HeroType))
end

return Recruitment
