--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local HeroDisplay = {}

local displays: { [string]: Instance } = {}
local lastKey = ""

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

local function collectSlots(academyName: string?): { BasePart }
	if academyName == nil or academyName == "" then
		return DisplayConfig.CollectPadParts(nil)
	end
	local folder = DisplayConfig.AcademyFolder(academyName)
	if folder == nil then
		return {}
	end
	return DisplayConfig.CollectPadParts(folder)
end

local function getFolder(): Folder
	local camera = Workspace.CurrentCamera
	local parent: Instance = camera or Workspace
	local existing = parent:FindFirstChild("HeroDisplay")
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "HeroDisplay"
	folder.Parent = parent
	return folder
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
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(150, 58)
	billboard.StudsOffset = Vector3.new(0, 1.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 16
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
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.55
	local slot = hero.DisplaySlot
	if typeof(slot) == "number" then
		label.Text = string.format("PAD %d\n%s %s\n+%d/s", slot, hero.Tier, hero.HeroType, hero.Production)
	else
		label.Text = string.format("%s %s\n+%d/s", hero.Tier, hero.HeroType, hero.Production)
	end
	label.Parent = bg
end

local function freezeClone(model: Model)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
			inst.Massless = true
		elseif inst:IsA("BaseScript") then
			inst:Destroy()
		end
	end
	if model.PrimaryPart == nil then
		local part = model:FindFirstChildWhichIsA("BasePart", true)
		if part then
			model.PrimaryPart = part
		end
	end
end

local function makeCylinder(hero: Types.Hero): BasePart
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
	marker.Parent = getFolder()
	return marker
end

local function cloneFromTemplate(hero: Types.Hero, template: Instance): Instance?
	local clone = template:Clone()
	clone.Name = hero.HeroID

	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = false
		clone.Parent = getFolder()
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
	model.Parent = getFolder()
	attachLabel(model, hero)
	return model
end

local function makeDisplay(hero: Types.Hero): Instance
	local template = DisplayConfig.HeroModelTemplate(hero.Tier, hero.HeroType)
	if template then
		local cloned = cloneFromTemplate(hero, template)
		if cloned then
			return cloned
		end
	end
	return makeCylinder(hero)
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

local function targetModelSize(): number
	local display = GameConfig.Display
	local config = display and display.HeroModels
	local value = config and config.TargetSize
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return 5
end

local function fitModelUniform(model: Model)
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
	local factor = targetModelSize() / longest
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

local function snapshotKey(heroes: { Types.Hero }, academyName: string?): string
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
				.. ":"
				.. tostring(hero.Production)
		)
	end
	table.sort(parts)
	return (academyName or "") .. "|" .. table.concat(parts, "|")
end

function HeroDisplay.Update(snapshot: Types.PlayerSnapshot)
	local heroes = snapshot.Heroes or {}
	local slots = collectSlots(snapshot.AcademyName)
	local key = snapshotKey(heroes, snapshot.AcademyName) .. "|pads=" .. tostring(#slots)

	local displayed: { Types.Hero } = {}
	local displayedIds: { [string]: boolean } = {}
	for _, hero in heroes do
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

	if key == lastKey and not missing then
		return
	end
	if #slots == 0 then
		lastKey = ""
		return
	end
	lastKey = key

	for heroId, display in displays do
		if not displayedIds[heroId] then
			display:Destroy()
			displays[heroId] = nil
		end
	end

	for _, hero in displayed do
		local existing = displays[hero.HeroID]
		if existing and existing:IsA("Part") and existing.Shape == Enum.PartType.Cylinder then
			if DisplayConfig.HeroModelTemplate(hero.Tier, hero.HeroType) then
				existing:Destroy()
				displays[hero.HeroID] = nil
			end
		end
		if not displays[hero.HeroID] then
			displays[hero.HeroID] = makeDisplay(hero)
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

return HeroDisplay
