--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local sessions: { [number]: Types.PlayerState } = {}

local PlayerData = {}

local function makeHero(seed: { HeroType: string, Tier: string, Power: number, Production: number }): Types.Hero
	return {
		HeroID = HttpService:GenerateGUID(false),
		HeroType = seed.HeroType,
		Tier = seed.Tier,
		Power = seed.Power,
		Production = seed.Production,
		Status = "ACTIVE",
		CreatedAt = os.time(),
	}
end

function PlayerData.Init(player: Player): Types.PlayerState
	local existing = sessions[player.UserId]
	if existing then
		return existing
	end

	local heroes: { Types.Hero } = {}
	for _, seed in GameConfig.Phase1.SeedHeroes do
		table.insert(heroes, makeHero(seed))
	end

	local state: Types.PlayerState = {
		Gold = GameConfig.Phase1.StartingGold,
		MagicStone = 0,
		MagicStoneCapacity = GameConfig.Storage.DefaultCapacity,
		ConverterLevel = 1,
		RecruitmentLevel = GameConfig.Recruitment.StartingLevel,
		PendingCandidate = nil,
		Heroes = heroes,
	}

	sessions[player.UserId] = state
	return state
end

function PlayerData.Get(player: Player): Types.PlayerState?
	return sessions[player.UserId]
end

function PlayerData.Remove(player: Player)
	sessions[player.UserId] = nil
end

return PlayerData
