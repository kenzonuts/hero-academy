--!strict

print("[HeroRecruitment] Server script starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 15)
if sharedFolder == nil then
	warn("[HeroRecruitment] ReplicatedStorage.Shared missing. Connect Rojo to this place, then Stop and Play.")
	return
end

local Shared = sharedFolder
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local GameRules = require(Shared:WaitForChild("GameRules"))
local UpgradeConfig = require(Shared:WaitForChild("UpgradeConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local remotes = Remotes.Get()

local modules = script.Parent
local Converter = require(modules:WaitForChild("Converter"))
local Academy = require(modules:WaitForChild("Academy"))
local PlayerData = require(modules:WaitForChild("PlayerData"))
local Production = require(modules:WaitForChild("Production"))
local Raid = require(modules:WaitForChild("Raid"))
local Recruitment = require(modules:WaitForChild("Recruitment"))
local Sell = require(modules:WaitForChild("Sell"))
local Snapshot = require(modules:WaitForChild("Snapshot"))
local Upgrades = require(modules:WaitForChild("Upgrades"))
local HeroWorld = require(modules:WaitForChild("HeroWorld"))

local TICK_SECONDS = 1
local AUTOSAVE_SECONDS = 60

print(string.format(
	"[HeroRecruitment] Server ready | %s | MS:Gold=%d | Raid max=%d",
	GameRules.Version,
	GameConfig.Conversion.MagicStoneToGold,
	GameConfig.Raid.MaxHeroes
))

local function pushState(player: Player)
	HeroWorld.Sync(player)
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

remotes.Recruit.OnServerInvoke = function(player: Player, mode: any)
	return withResult(player, Recruitment.Recruit(player, mode))
end

remotes.Accept.OnServerInvoke = function(player: Player, candidateId: any)
	return withResult(player, Recruitment.Accept(player, candidateId))
end

remotes.Reject.OnServerInvoke = function(player: Player)
	return withResult(player, Recruitment.Reject(player))
end

remotes.Sell.OnServerInvoke = function(player: Player, heroId: any)
	return withResult(player, Sell.Hero(player, heroId))
end

remotes.UpgradeRecruitment.OnServerInvoke = function(player: Player)
	return withResult(player, Upgrades.Recruitment(player))
end

remotes.UpgradeConverter.OnServerInvoke = function(player: Player)
	return withResult(player, Upgrades.Converter(player))
end

remotes.StartRaid.OnServerInvoke = function(player: Player, mapId: any, heroIds: any)
	return withResult(player, Raid.Start(player, mapId, heroIds))
end

remotes.TeleportHome.OnServerInvoke = function(player: Player)
	if Academy.GetFolder(player) == nil then
		return { ok = false, error = "No academy assigned." }
	end
	Academy.MoveToSpawn(player)
	return { ok = true, message = "Returned to base." }
end

local function onPlayerAdded(player: Player)
	local academyName = Academy.Assign(player)
	if academyName == nil then
		Academy.KickIfFull(player)
		return
	end
	Academy.BindCharacter(player)

	local state = PlayerData.Init(player)
	Raid.Tick(player)
	print(string.format(
		"[P2] %s joined | %s | Gold=%d | Heroes=%d | RecruitFee=%d",
		player.Name,
		academyName,
		state.Gold,
		#state.Heroes,
		UpgradeConfig.RecruitFee(state.RecruitmentLevel)
	))
	pushState(player)
end

local function onPlayerRemoving(player: Player)
	HeroWorld.Clear(player)
	Academy.Release(player)
	PlayerData.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	local elapsed = 0
	while true do
		task.wait(TICK_SECONDS)
		elapsed += TICK_SECONDS

		for _, player in Players:GetPlayers() do
			Raid.Tick(player)
			Production.Tick(player, TICK_SECONDS)
			Converter.Tick(player, TICK_SECONDS)
			pushState(player)
		end

		if elapsed >= AUTOSAVE_SECONDS then
			elapsed = 0
			PlayerData.SaveAll()
		end
	end
end)

game:BindToClose(function()
	PlayerData.SaveAll()
	if RunService:IsStudio() then
		task.wait(1)
	else
		task.wait(2)
	end
end)
