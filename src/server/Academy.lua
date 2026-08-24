--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Academy = {}

local claimed: { [string]: number } = {}
local byUser: { [number]: string } = {}

local function attributeName(): string
	local academy = GameConfig.Academy
	local name = academy and academy.AttributeName
	if typeof(name) == "string" and name ~= "" then
		return name
	end
	return "AcademyName"
end

function Academy.GetName(player: Player): string?
	return byUser[player.UserId]
end

function Academy.GetFolder(player: Player): Instance?
	local name = Academy.GetName(player)
	if name == nil then
		return nil
	end
	return DisplayConfig.AcademyFolder(name)
end

function Academy.Assign(player: Player): string?
	local existing = byUser[player.UserId]
	if existing then
		player:SetAttribute(attributeName(), existing)
		return existing
	end

	local present: { string } = {}
	for _, name in DisplayConfig.AcademyNames() do
		if DisplayConfig.AcademyFolder(name) ~= nil then
			table.insert(present, name)
		end
	end

	if #present == 0 then
		return ""
	end

	for _, name in present do
		if claimed[name] == nil then
			claimed[name] = player.UserId
			byUser[player.UserId] = name
			player:SetAttribute(attributeName(), name)
			print(string.format("[Academy] %s -> %s", player.Name, name))
			return name
		end
	end

	return nil
end

function Academy.Release(player: Player)
	local name = byUser[player.UserId]
	if name and claimed[name] == player.UserId then
		claimed[name] = nil
	end
	byUser[player.UserId] = nil
	player:SetAttribute(attributeName(), nil)
end

local function findSpawnPart(academy: Instance): BasePart?
	for _, inst in academy:GetDescendants() do
		if inst:IsA("SpawnLocation") then
			return inst
		end
	end

	local wanted = {
		spawn = true,
		playerspawn = true,
		spawnpoint = true,
		spawnpart = true,
	}
	for _, inst in academy:GetDescendants() do
		local key = string.lower(inst.Name)
		if wanted[key] then
			if inst:IsA("BasePart") then
				return inst
			end
			if inst:IsA("Model") then
				local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
				if part then
					return part
				end
			end
		end
	end

	local pads = DisplayConfig.CollectPadParts(academy)
	return pads[1]
end

function Academy.MoveToSpawn(player: Player, character: Model?)
	local academy = Academy.GetFolder(player)
	if academy == nil then
		return
	end

	local model = character or player.Character
	if model == nil then
		return
	end

	local spawnPart = findSpawnPart(academy)
	if spawnPart == nil then
		return
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		root = model:WaitForChild("HumanoidRootPart", 8)
	end
	if root == nil or not root:IsA("BasePart") then
		return
	end

	local dest = spawnPart.CFrame + Vector3.new(0, spawnPart.Size.Y * 0.5 + 4, 0)
	model:PivotTo(dest)
end

function Academy.BindCharacter(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			Academy.MoveToSpawn(player, character)
		end)
	end)
	if player.Character then
		task.defer(function()
			Academy.MoveToSpawn(player, player.Character)
		end)
	end
end

function Academy.KickIfFull(player: Player): boolean
	local academy = GameConfig.Academy
	local kick = if academy then academy.KickWhenFull ~= false else true
	if not kick then
		return false
	end
	local message = if academy and typeof(academy.KickMessage) == "string"
		then academy.KickMessage
		else "Server penuh. Maksimal 6 player."
	player:Kick(message)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	Academy.Release(player)
end)

return Academy
