--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local Converter = require(script.Parent:WaitForChild("Converter"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Production = require(script.Parent:WaitForChild("Production"))

local Snapshot = {}

function Snapshot.ForPlayer(player: Player): Types.PlayerSnapshot?
	local state = PlayerData.Get(player)
	if not state then
		return nil
	end

	return {
		Gold = state.Gold,
		MagicStone = state.MagicStone,
		MagicStoneCapacity = state.MagicStoneCapacity,
		ProductionPerSecond = Production.GetTotal(player),
		ConverterSpeed = Converter.GetSpeed(state.ConverterLevel),
		HeroCount = #state.Heroes,
		RecruitmentLevel = state.RecruitmentLevel,
		RecruitFee = GameConfig.Recruitment.RecruitFeeGold,
		RecruitLocked = state.PendingCandidate ~= nil,
		PendingCandidate = state.PendingCandidate,
	}
end

return Snapshot
