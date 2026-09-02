--!strict
-- Server clones on academy pads so every player can see every academy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local Academy = require(script.Parent:WaitForChild("Academy"))
local Collection = require(script.Parent:WaitForChild("Collection"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local HeroWorld = {}

local displaysByUser: { [number]: { [string]: Instance } } = {}
local lastKeyByUser: { [number]: string } = {}

local function getTierColor(tier: string): Color3
	local colors = GameConfig.Display and GameConfig.Display.TierColors
	local rgb = { 160, 160, 165 }
	if colors then
		rgb = if tier == "B1"
			then colors.B1
			elseif tier == "B2" then colors.B2
			elseif tier == "B3" then colors.B3
			elseif tier == "B4" then colors.B4
			elseif tier == "B5" then colors.B5
			elseif tier == "B6" then colors.B6
			elseif tier == "B7" then colors.B7
			else rgb
	end
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function worldRoot(): Folder
	local existing = Workspace:FindFirstChild("HeroWorld")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "HeroWorld"
	folder.Parent = Workspace
	return folder
end

local function academyFolder(academyName: string): Folder
	local root = worldRoot()
	local existing = root:FindFirstChild(academyName)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = academyName
	folder.Parent = root
	return folder
end

local cachedLabelDistance: number? = nil

local function academyAnchor(folder: Instance): Vector3?
	for _, inst in folder:GetDescendants() do
		if inst:IsA("SpawnLocation") then
			return inst.Position
		end
	end
	local wanted = {
		spawn = true,
		playerspawn = true,
		spawnpoint = true,
		spawnpart = true,
	}
	for _, inst in folder:GetDescendants() do
		local key = string.lower(inst.Name)
		if wanted[key] then
			if inst:IsA("BasePart") then
				return inst.Position
			end
			if inst:IsA("Model") then
				local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
				if part then
					return part.Position
				end
			end
		end
	end
	if folder:IsA("Model") then
		return folder:GetPivot().Position
	end
	local part = folder:FindFirstChildWhichIsA("BasePart", true)
	if part then
		return part.Position
	end
	return nil
end

local function autoLabelDistance(): number
	local points: { Vector3 } = {}
	for _, name in DisplayConfig.AcademyNames() do
		local folder = DisplayConfig.AcademyFolder(name)
		if folder then
			local pos = academyAnchor(folder)
			if pos then
				table.insert(points, pos)
			end
		end
	end
	local nearest = math.huge
	for i = 1, #points do
		for j = i + 1, #points do
			local gap = (points[i] - points[j]).Magnitude
			if gap < nearest then
				nearest = gap
			end
		end
	end
	local factor = 0.5
	local display = GameConfig.Display
	local config = display and display.HeroModels
	if config and typeof(config.LabelRangeFactor) == "number" and config.LabelRangeFactor > 0 then
		factor = config.LabelRangeFactor
	end
	if nearest < math.huge and nearest > 20 then
		-- Cap so labels hide before they shrink into unreadable specks.
		return math.clamp(nearest * factor, 14, 20)
	end
	return 16
end

local function labelMaxDistance(): number
	local display = GameConfig.Display
	local config = display and display.HeroModels
	local value = config and config.LabelMaxDistance
	if typeof(value) == "number" and value > 0 then
		return value
	end
	if cachedLabelDistance == nil then
		cachedLabelDistance = autoLabelDistance()
	end
	return cachedLabelDistance
end

local function labelStudsOffset(): Vector3
	local y = 1.4
	local display = GameConfig.Display
	local config = display and display.HeroModels
	if config and typeof(config.LabelStudsOffsetY) == "number" then
		y = config.LabelStudsOffsetY
	end
	return Vector3.new(0, y, 0)
end

local function styleBillboard(gui: BillboardGui)
	gui.AlwaysOnTop = true
	gui.MaxDistance = labelMaxDistance()
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(200, 72)
	gui.StudsOffset = labelStudsOffset()
	local card = gui:FindFirstChild("Card")
	if card and card:IsA("GuiObject") then
		card.BackgroundTransparency = 1
	end
	local text = gui:FindFirstChildWhichIsA("TextLabel", true)
	if text then
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.TextSize = 18
		text.TextStrokeTransparency = 0.25
		if text:FindFirstChildOfClass("UITextSizeConstraint") == nil then
			local sizeLimit = Instance.new("UITextSizeConstraint")
			sizeLimit.MinTextSize = 16
			sizeLimit.MaxTextSize = 22
			sizeLimit.Parent = text
		end
	end
end

local function stripOtherGuis(host: Instance)
	local junk: { Instance } = {}
	for _, inst in host:GetDescendants() do
		if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
			if inst.Name ~= "Label" then
				table.insert(junk, inst)
			end
		end
	end
	for _, inst in junk do
		inst:Destroy()
	end
end

local function hideLabelBackground(host: Instance)
	stripOtherGuis(host)
	for _, inst in host:GetDescendants() do
		if inst:IsA("BillboardGui") and inst.Name == "Label" then
			styleBillboard(inst)
		end
	end
end

local function attachLabel(host: Instance, hero: Types.Hero)
	local part: BasePart? = nil
	if host:IsA("BasePart") then
		part = host
	elseif host:IsA("Model") then
		part = host.PrimaryPart or host:FindFirstChildWhichIsA("BasePart", true)
	end
	if part == nil then
		return
	end
	if part:FindFirstChild("Label") then
		hideLabelBackground(part)
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(200, 72)
	billboard.StudsOffset = labelStudsOffset()
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = labelMaxDistance()
	billboard.LightInfluence = 0
	billboard.Parent = part

	local bg = Instance.new("Frame")
	bg.Name = "Card"
	bg.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = billboard
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = bg

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextSize = 18
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MinTextSize = 16
	sizeLimit.MaxTextSize = 22
	sizeLimit.Parent = label
	local slot = hero.DisplaySlot
	if typeof(slot) == "number" then
		label.Text = string.format("PAD %d\n%s %s\n+%d/s", slot, hero.Tier, hero.HeroType, hero.Production)
	else
		label.Text = string.format("%s %s\n+%d/s", hero.Tier, hero.HeroType, hero.Production)
	end
	label.Parent = bg
end

local function freezeClone(model: Model)
	local junk: { Instance } = {}
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
			inst.Massless = true
		elseif inst:IsA("BaseScript") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
			table.insert(junk, inst)
		end
	end
	for _, inst in junk do
		inst:Destroy()
	end
	if model.PrimaryPart == nil then
		local part = model:FindFirstChildWhichIsA("BasePart", true)
		if part then
			model.PrimaryPart = part
		end
	end
end

local function makeCylinder(hero: Types.Hero, parent: Folder): BasePart
	local marker = Instance.new("Part")
	marker.Name = hero.HeroID
	marker.Shape = Enum.PartType.Cylinder
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = getTierColor(hero.Tier)
	marker.Size = Vector3.new(DisplayConfig.MarkerHeight(), 1.2, 1.2)

	local light = Instance.new("PointLight")
	light.Color = getTierColor(hero.Tier)
	light.Brightness = 0.55
	light.Range = 7
	light.Parent = marker

	attachLabel(marker, hero)
	marker.Parent = parent
	return marker
end

local function cloneFromTemplate(hero: Types.Hero, template: Instance, parent: Folder): Instance?
	local clone = template:Clone()
	clone.Name = hero.HeroID

	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = false
		clone.Parent = parent
		attachLabel(clone, hero)
		return clone
	end

	local model: Model
	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		model.Name = hero.HeroID
		for _, child in clone:GetChildren() do
			child.Parent = model
		end
		clone:Destroy()
	end

	freezeClone(model)
	model.Parent = parent
	attachLabel(model, hero)
	return model
end

local function makeDisplay(hero: Types.Hero, parent: Folder): Instance
	local template = DisplayConfig.HeroModelTemplate(hero.Tier, hero.HeroType)
	if template then
		local cloned = cloneFromTemplate(hero, template, parent)
		if cloned then
			return cloned
		end
	end
	return makeCylinder(hero, parent)
end

local function worldTopY(part: BasePart): number
	local cf = part.CFrame
	local half = part.Size * 0.5
	local maxY = -math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local world = cf:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
				if world.Y > maxY then
					maxY = world.Y
				end
			end
		end
	end
	return maxY
end

local function circleDiameter(part: BasePart): number
	local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
	local largest = math.max(x, y, z)
	local smallest = math.min(x, y, z)
	local mid = x + y + z - largest - smallest
	return math.max(mid, largest * 0.5)
end

local function targetModelSize(): number?
	local display = GameConfig.Display
	local config = display and display.HeroModels
	local value = config and config.TargetSize
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return nil
end

local function fitModelUniform(model: Model)
	local target = targetModelSize()
	if target == nil then
		return
	end
	local ok, boxSize = pcall(function()
		local _, size = model:GetBoundingBox()
		return size
	end)
	if not ok or typeof(boxSize) ~= "Vector3" then
		return
	end
	local longest = math.max(boxSize.X, boxSize.Y, boxSize.Z)
	if longest < 0.05 then
		return
	end
	local factor = target / longest
	if math.abs(factor - 1) < 0.02 then
		return
	end
	pcall(function()
		model:ScaleTo(model:GetScale() * factor)
	end)
end

local function placeModelOnPad(model: Model, pad: BasePart)
	if model:GetAttribute("Fitted") ~= true then
		fitModelUniform(model)
		model:SetAttribute("Fitted", true)
	end
	local boxCF, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local offset = pivot.Position - boxCF.Position
	local topY = worldTopY(pad)
	local targetCenter = Vector3.new(pad.Position.X, topY + boxSize.Y / 2, pad.Position.Z)
	model:PivotTo(CFrame.new(targetCenter + offset) * (pivot - pivot.Position))
end

local function placePartOnPad(marker: BasePart, pad: BasePart)
	local diameter = circleDiameter(pad)
	local width = math.clamp(diameter * 0.32, 1.1, 4.5)
	local height = DisplayConfig.MarkerHeight()
	marker.Size = Vector3.new(height, width, width)
	local topY = worldTopY(pad)
	marker.CFrame = CFrame.new(pad.Position.X, topY + height / 2, pad.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
end

local function placeOnPad(display: Instance, pad: BasePart)
	if display:IsA("Model") then
		placeModelOnPad(display, pad)
	elseif display:IsA("BasePart") then
		placePartOnPad(display, pad)
	end
end

local function snapshotKey(heroes: { Types.Hero }, academyName: string, padCount: number): string
	local parts = {}
	for _, hero in heroes do
		table.insert(
			parts,
			hero.HeroID
				.. ":"
				.. hero.Status
				.. ":"
				.. tostring(hero.DisplaySlot)
				.. ":"
				.. hero.HeroType
				.. ":"
				.. hero.Tier
		)
	end
	table.sort(parts)
	return academyName .. "|" .. table.concat(parts, "|") .. "|pads=" .. tostring(padCount)
end

function HeroWorld.Clear(player: Player)
	local userId = player.UserId
	local displays = displaysByUser[userId]
	if displays then
		for _, display in displays do
			display:Destroy()
		end
	end
	displaysByUser[userId] = nil
	lastKeyByUser[userId] = nil

	local academyName = Academy.GetName(player)
	if academyName then
		local folder = worldRoot():FindFirstChild(academyName)
		if folder then
			folder:Destroy()
		end
	end
end

function HeroWorld.Sync(player: Player)
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	Collection.EnsureDisplaySlots(state.Heroes)

	local academyName = Academy.GetName(player)
	if academyName == nil or academyName == "" then
		return
	end

	local academy = DisplayConfig.AcademyFolder(academyName)
	local slots = DisplayConfig.CollectPadParts(academy)
	local key = snapshotKey(state.Heroes, academyName, #slots)
	local userId = player.UserId
	local displays = displaysByUser[userId]
	if displays == nil then
		displays = {}
		displaysByUser[userId] = displays
	end
	for _, display in displays do
		hideLabelBackground(display)
	end

	local displayed: { Types.Hero } = {}
	local displayedIds: { [string]: boolean } = {}
	for _, hero in state.Heroes do
		if hero.Status == "ACTIVE" then
			table.insert(displayed, hero)
			displayedIds[hero.HeroID] = true
		end
	end

	local missing = false
	for _, hero in displayed do
		if displays[hero.HeroID] == nil then
			missing = true
			break
		end
	end

	if key == lastKeyByUser[userId] and not missing then
		return
	end
	if #slots == 0 then
		lastKeyByUser[userId] = nil
		return
	end
	lastKeyByUser[userId] = key

	for heroId, display in displays do
		if not displayedIds[heroId] then
			display:Destroy()
			displays[heroId] = nil
		end
	end

	local parent = academyFolder(academyName)
	for _, hero in displayed do
		local existing = displays[hero.HeroID]
		if existing and existing:IsA("Part") and existing.Shape == Enum.PartType.Cylinder then
			if DisplayConfig.HeroModelTemplate(hero.Tier, hero.HeroType) then
				existing:Destroy()
				displays[hero.HeroID] = nil
			end
		end
		if not displays[hero.HeroID] then
			displays[hero.HeroID] = makeDisplay(hero, parent)
		end
	end

	for _, hero in displayed do
		local display = displays[hero.HeroID]
		local slotIndex = hero.DisplaySlot
		local pad = if typeof(slotIndex) == "number" then slots[slotIndex] else nil
		if display and pad then
			placeOnPad(display, pad)
		end
	end
end

return HeroWorld
