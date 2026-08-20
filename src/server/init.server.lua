--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameRules = require(Shared:WaitForChild("GameRules"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local Converter = require(script:WaitForChild("Converter"))
local PlayerData = require(script:WaitForChild("PlayerData"))
local Production = require(script:WaitForChild("Production"))
local Recruitment = require(script:WaitForChild("Recruitment"))
local Snapshot = require(script:WaitForChild("Snapshot"))

local TICK_SECONDS = 1

local remotes = Remotes.Get()

print(string.format(
	"[HeroRecruitment] Server ready | %s | MS:Gold=%d | Raid max=%d",
	GameRules.Version,
	GameConfig.Conversion.MagicStoneToGold,
	GameConfig.Raid.MaxHeroes
))

local function pushState(player: Player)
	local snapshot = Snapshot.ForPlayer(player)
	if snapshot then
		remotes.StateUpdated:FireClient(player, snapshot)
	end
end

local function withResult(player: Player, result: Types.ActionResult): Types.ActionResult
	local tag = if result.ok then "OK" else "FAIL"
	print(string.format("[P2] %s %s %s", player.Name, tag, result.message or result.error or ""))
	pushState(player)
	return result
end

remotes.GetSnapshot.OnServerInvoke = function(player: Player)
	return Snapshot.ForPlayer(player)
end

remotes.Recruit.OnServerInvoke = function(player: Player)
	return withResult(player, Recruitment.Recruit(player))
end

remotes.Accept.OnServerInvoke = function(player: Player)
	return withResult(player, Recruitment.Accept(player))
end

remotes.Reject.OnServerInvoke = function(player: Player)
	return withResult(player, Recruitment.Reject(player))
end

local function onPlayerAdded(player: Player)
	local state = PlayerData.Init(player)
	print(string.format(
		"[P2] %s joined | Gold=%d | Heroes=%d | RecruitFee=%d",
		player.Name,
		state.Gold,
		#state.Heroes,
		GameConfig.Recruitment.RecruitFeeGold
	))
	pushState(player)
end

local function onPlayerRemoving(player: Player)
	PlayerData.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(TICK_SECONDS)

		for _, player in Players:GetPlayers() do
			Production.Tick(player, TICK_SECONDS)
			Converter.Tick(player, TICK_SECONDS)
			pushState(player)
		end
	end
end)
