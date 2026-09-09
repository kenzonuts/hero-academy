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

local function asLookPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	end
	if target:IsA("Model") then
		local part = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
		return target:GetPivot().Position
	end
	return nil
end

local function flatLookAt(fromPos: Vector3, lookPos: Vector3): CFrame
	local flat = Vector3.new(lookPos.X - fromPos.X, 0, lookPos.Z - fromPos.Z)
	if flat.Magnitude < 0.05 then
		return CFrame.new(fromPos)
	end
	return CFrame.lookAt(fromPos, fromPos + flat)
end

function Academy.FindNamedInstance(name: string): Instance?
	if typeof(name) ~= "string" or name == "" then
		return nil
	end
	return Workspace:FindFirstChild(name, true)
end

function Academy.MoveToPart(player: Player, part: BasePart, character: Model?, faceTarget: Instance?): boolean
	local model = character or player.Character
	if model == nil then
		return false
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		root = model:WaitForChild("HumanoidRootPart", 8)
	end
	if root == nil or not root:IsA("BasePart") then
		return false
	end

	local destPos = part.Position + Vector3.new(0, part.Size.Y * 0.5 + 4, 0)
	local lookPos = if faceTarget then asLookPosition(faceTarget) else nil
	if lookPos then
		model:PivotTo(flatLookAt(destPos, lookPos))
	else
		model:PivotTo(part.CFrame + Vector3.new(0, part.Size.Y * 0.5 + 4, 0))
	end
	return true
end

function Academy.MoveToSpawn(player: Player, character: Model?)
	local academy = Academy.GetFolder(player)
	if academy == nil then
		return
	end

	local spawnPart = findSpawnPart(academy)
	if spawnPart == nil then
		return
	end

	Academy.MoveToPart(player, spawnPart, character, nil)
end

function Academy.FindTeleportPart(folderName: string?, partName: string): BasePart?
	if typeof(partName) ~= "string" or partName == "" then
		return nil
	end
	if typeof(folderName) == "string" and folderName ~= "" then
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			local child = folder:FindFirstChild(partName)
			if child and child:IsA("BasePart") then
				return child
			end
			local nested = folder:FindFirstChild(partName, true)
			if nested and nested:IsA("BasePart") then
				return nested
			end
		end
	end
	local found = Workspace:FindFirstChild(partName, true)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

function Academy.MoveToGuild(player: Player, character: Model?): boolean
	local display = GameConfig.Display
	local folderName = if display and typeof(display.GuildTeleportFolder) == "string"
		then display.GuildTeleportFolder
		else "GUILD"
	local partName = if display and typeof(display.GuildTeleportPart) == "string"
		then display.GuildTeleportPart
		else "GUILDTP"
	local part = Academy.FindTeleportPart(folderName, partName)
	if part == nil then
		part = Academy.FindTeleportPart(nil, partName)
	end
	if part == nil then
		return false
	end
	local faceName = if display and typeof(display.GuildFaceTarget) == "string"
		then display.GuildFaceTarget
		else "NPC_GuildMaster"
	local face = Academy.FindNamedInstance(faceName)
	return Academy.MoveToPart(player, part, character, face)
end

function Academy.MoveToStore(player: Player, character: Model?): boolean
	local display = GameConfig.Display
	local folderName = if display and typeof(display.StoreTeleportFolder) == "string"
		then display.StoreTeleportFolder
		else "STORE"
	local partName = if display and typeof(display.StoreTeleportPart) == "string"
		then display.StoreTeleportPart
		else "STORETP"
	local part = Academy.FindTeleportPart(folderName, partName)
	if part == nil then
		part = Academy.FindTeleportPart(nil, partName)
	end
	if part == nil then
		return false
	end
	local faceName = if display and typeof(display.StoreFaceTarget) == "string"
		then display.StoreFaceTarget
		else "NPC_Shopkeeper"
	local face = Academy.FindNamedInstance(faceName)
	return Academy.MoveToPart(player, part, character, face)
end

function Academy.BindCharacter(player: Player)
	local function placeCharacter(character: Model)
		-- Wait for root so PivotTo sticks (esp. right after spawn).
		if character:WaitForChild("HumanoidRootPart", 8) == nil then
			return
		end
		Academy.MoveToSpawn(player, character)
	end

	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			placeCharacter(character)
		end)
	end)
	if player.Character then
		task.defer(function()
			placeCharacter(player.Character :: Model)
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
