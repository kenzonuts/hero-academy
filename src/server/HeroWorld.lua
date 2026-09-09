--!strict
-- Server clones on academy pads so every player can see every academy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local walkingByUser: { [number]: { [string]: boolean } } = {}
local walkQueueByUser: { [number]: { { heroId: string, display: Instance, pad: BasePart, summon: BasePart } } } = {}
local walkBusyByUser: { [number]: boolean } = {}
local walkConnections: { [string]: RBXScriptConnection } = {}
local walkRequestedByUser: { [number]: { [string]: boolean } } = {}
local animTracksByHero: { [string]: { idle: AnimationTrack?, walk: AnimationTrack? } } = {}

local function getTierColor(tier: string): Color3
	local colors = GameConfig.Display and GameConfig.Display.TierColors
	local rgb = { 160, 160, 165 }
	if colors and typeof(colors[tier]) == "table" then
		rgb = colors[tier]
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

local ATTR_DANCE = "HR_DanceAnimId"
local ATTR_IDLE = "HR_IdleAnimId"
local ATTR_WALK = "HR_WalkAnimId"

local function looksLikeAnimId(value: unknown): string?
	if typeof(value) == "number" then
		local n = value :: number
		if n > 10000 then
			return "rbxassetid://" .. tostring(math.floor(n))
		end
		return nil
	end
	if typeof(value) ~= "string" then
		return nil
	end
	local text = value :: string
	if text == "" then
		return nil
	end
	local digits = string.match(text, "(%d%d%d%d%d+)")
	if digits then
		return "rbxassetid://" .. digits
	end
	return nil
end

local function classifyAnimName(name: string): "dance" | "idle" | "walk" | "other"
	local n = string.lower(name)
	-- Pad "joget" = dance / emote clips first.
	if string.find(n, "joget", 1, true)
		or string.find(n, "dance", 1, true)
		or string.find(n, "emote", 1, true)
		or string.find(n, "party", 1, true)
		or string.find(n, "fun", 1, true)
		or string.find(n, "cheer", 1, true)
		or string.find(n, "wave", 1, true)
	then
		return "dance"
	end
	if string.find(n, "walk", 1, true)
		or string.find(n, "run", 1, true)
		or string.find(n, "move", 1, true)
		or string.find(n, "jog", 1, true)
	then
		return "walk"
	end
	if string.find(n, "idle", 1, true)
		or string.find(n, "stand", 1, true)
		or string.find(n, "afk", 1, true)
		or string.find(n, "breath", 1, true)
	then
		return "idle"
	end
	return "other"
end

-- Duck Animate scripts (often LocalScripts) do not run under Workspace clones.
-- Copy their Animation / StringValue asset ids onto the model before we strip scripts.
local function harvestAnimIds(model: Model)
	local danceId: string? = nil
	local idleId: string? = nil
	local walkId: string? = nil
	local anyId: string? = nil

	local function consider(name: string, parentName: string, raw: unknown)
		local id = looksLikeAnimId(raw)
		if id == nil then
			return
		end
		anyId = anyId or id
		local kind = classifyAnimName(name)
		if kind == "other" then
			kind = classifyAnimName(parentName)
		end
		if kind == "dance" then
			danceId = danceId or id
		elseif kind == "idle" then
			idleId = idleId or id
		elseif kind == "walk" then
			walkId = walkId or id
		end
	end

	for _, inst in model:GetDescendants() do
		local parentName = if inst.Parent then inst.Parent.Name else ""
		if inst:IsA("Animation") then
			consider(inst.Name, parentName, inst.AnimationId)
		elseif inst:IsA("StringValue") then
			consider(inst.Name, parentName, inst.Value)
		elseif inst:IsA("NumberValue") then
			consider(inst.Name, parentName, inst.Value)
		end
	end

	-- Prefer config overrides when set.
	local display = GameConfig.Display
	local config = display and display.HeroModels
	if typeof(config) == "table" then
		local cfgIdle = looksLikeAnimId(config.IdleAnimationId)
		local cfgWalk = looksLikeAnimId(config.WalkAnimationId)
		local cfgDance = looksLikeAnimId(config.DanceAnimationId)
		if cfgDance then
			danceId = cfgDance
		end
		if cfgIdle then
			idleId = cfgIdle
		end
		if cfgWalk then
			walkId = cfgWalk
		end
	end

	-- On pad we want joget: any single clip counts as dance if nothing labeled.
	if danceId == nil and idleId == nil and anyId ~= nil then
		danceId = anyId
	end

	if danceId then
		model:SetAttribute(ATTR_DANCE, danceId)
	end
	if idleId then
		model:SetAttribute(ATTR_IDLE, idleId)
	end
	if walkId then
		model:SetAttribute(ATTR_WALK, walkId)
	end
end

local function prepareDisplayModel(model: Model)
	harvestAnimIds(model)

	if model.PrimaryPart == nil then
		local prefer = model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("RootPart")
			or model:FindFirstChildWhichIsA("BasePart", true)
		if prefer and prefer:IsA("BasePart") then
			model.PrimaryPart = prefer
		end
	end
	local root = model.PrimaryPart
	local junk: { Instance } = {}
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.CanCollide = false
			inst.Massless = true
			-- Keep root anchored for PivotTo; leave limbs free so Motor6D animations play.
			inst.Anchored = root ~= nil and inst == root
		elseif inst:IsA("BaseScript") then
			table.insert(junk, inst)
		elseif (inst:IsA("BillboardGui") or inst:IsA("SurfaceGui")) and inst.Name ~= "Label" then
			table.insert(junk, inst)
		end
	end
	for _, inst in junk do
		inst:Destroy()
	end
	local hasMotors = model:FindFirstChildWhichIsA("Motor6D", true) ~= nil
		or model:FindFirstChildWhichIsA("Bone", true) ~= nil
	if not hasMotors and root then
		for _, inst in model:GetDescendants() do
			if inst:IsA("BasePart") then
				inst.Anchored = true
			end
		end
	end
end

local function ensureAnimator(model: Model): Animator?
	-- Prefer AnimationController for display NPCs (Humanoid PlatformStand blocks clips).
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = false
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator == nil then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end
	local controller = model:FindFirstChildOfClass("AnimationController")
	if controller == nil then
		controller = Instance.new("AnimationController")
		controller.Parent = model
	end
	local animator = controller:FindFirstChildOfClass("Animator")
	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	return animator
end

local function makeAnimInstance(model: Model, name: string, id: string): Animation
	local existing = model:FindFirstChild(name)
	if existing and existing:IsA("Animation") then
		existing.AnimationId = id
		return existing
	end
	local anim = Instance.new("Animation")
	anim.Name = name
	anim.AnimationId = id
	anim.Parent = model
	return anim
end

local function resolveAnimation(model: Model, kind: "idle" | "walk"): Animation?
	if kind == "idle" then
		-- Pad pose: dance / joget first, then idle, then any harvested id.
		local danceId = model:GetAttribute(ATTR_DANCE)
		local idleId = model:GetAttribute(ATTR_IDLE)
		local id = looksLikeAnimId(danceId) or looksLikeAnimId(idleId)
		if id then
			return makeAnimInstance(model, "HR_PadDance", id)
		end
	else
		local walkId = looksLikeAnimId(model:GetAttribute(ATTR_WALK))
		if walkId then
			return makeAnimInstance(model, "HR_Walk", walkId)
		end
	end

	-- Surviving Animation instances (not under destroyed scripts).
	local keywords = if kind == "walk"
		then { "walk", "run", "move", "jog" }
		else { "joget", "dance", "emote", "party", "fun", "idle", "stand", "afk" }
	for _, inst in model:GetDescendants() do
		if inst:IsA("Animation") then
			local name = string.lower(inst.Name)
			for _, key in keywords do
				if string.find(name, key, 1, true) and looksLikeAnimId(inst.AnimationId) then
					return inst
				end
			end
		end
	end
	if kind == "idle" then
		for _, inst in model:GetDescendants() do
			if inst:IsA("Animation") and looksLikeAnimId(inst.AnimationId) then
				return inst
			end
		end
	end
	return nil
end

local function stopHeroAnims(heroId: string)
	local bag = animTracksByHero[heroId]
	if bag == nil then
		return
	end
	if bag.idle then
		bag.idle:Stop(0.15)
	end
	if bag.walk then
		bag.walk:Stop(0.15)
	end
end

local function clearHeroAnims(heroId: string)
	stopHeroAnims(heroId)
	animTracksByHero[heroId] = nil
end

local function playHeroAnim(model: Model, heroId: string, kind: "idle" | "walk")
	local animator = ensureAnimator(model)
	if animator == nil then
		return
	end
	local bag = animTracksByHero[heroId]
	if bag == nil then
		bag = { idle = nil, walk = nil }
		animTracksByHero[heroId] = bag
	end
	if kind == "idle" then
		if bag.walk and bag.walk.IsPlaying then
			bag.walk:Stop(0.15)
		end
		if bag.idle and bag.idle.IsPlaying then
			return
		end
		local anim = resolveAnimation(model, "idle")
		if anim == nil then
			warn("[HeroWorld] no pad dance/idle animation for", model:GetFullName())
			return
		end
		local okLoad, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not okLoad or typeof(track) ~= "Instance" then
			warn("[HeroWorld] LoadAnimation failed for", model.Name, anim.AnimationId, track)
			return
		end
		local idleTrack = track :: AnimationTrack
		idleTrack.Looped = true
		-- Action so dance beats a quiet Idle default pose.
		idleTrack.Priority = Enum.AnimationPriority.Action
		bag.idle = idleTrack
		idleTrack:Play(0.2)
	else
		if bag.idle and bag.idle.IsPlaying then
			bag.idle:Stop(0.15)
		end
		if bag.walk and bag.walk.IsPlaying then
			return
		end
		local anim = resolveAnimation(model, "walk")
		if anim == nil then
			playHeroAnim(model, heroId, "idle")
			return
		end
		local okLoad, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not okLoad or typeof(track) ~= "Instance" then
			playHeroAnim(model, heroId, "idle")
			return
		end
		local walkTrack = track :: AnimationTrack
		walkTrack.Looped = true
		walkTrack.Priority = Enum.AnimationPriority.Movement
		bag.walk = walkTrack
		walkTrack:Play(0.15)
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

	prepareDisplayModel(model)
	model.Parent = parent
	attachLabel(model, hero)
	task.defer(function()
		if model.Parent then
			playHeroAnim(model, hero.HeroID, "idle")
		end
	end)
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

local function walkSpeed(): number
	local display = GameConfig.Display
	local config = display and display.HeroModels
	local value = config and config.WalkSpeed
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return 16
end

local function modelStandCFrame(model: Model, ground: BasePart): CFrame
	if model:GetAttribute("Fitted") ~= true then
		fitModelUniform(model)
		model:SetAttribute("Fitted", true)
	end
	local boxCF, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local offset = pivot.Position - boxCF.Position
	local topY = worldTopY(ground)
	local targetCenter = Vector3.new(ground.Position.X, topY + boxSize.Y / 2, ground.Position.Z)
	return CFrame.new(targetCenter + offset) * (pivot - pivot.Position)
end

local function stopWalk(heroId: string)
	local conn = walkConnections[heroId]
	if conn then
		conn:Disconnect()
		walkConnections[heroId] = nil
	end
end

local startWalkJob: (number, string, Instance, BasePart, BasePart) -> ()

local function finishWalk(userId: number, heroId: string, display: Instance, pad: BasePart)
	stopWalk(heroId)
	local walking = walkingByUser[userId]
	if walking then
		walking[heroId] = nil
	end
	if display.Parent then
		placeOnPad(display, pad)
		display:SetAttribute("WalkedIn", true)
		if display:IsA("Model") then
			playHeroAnim(display, heroId, "idle")
		end
	end
	walkBusyByUser[userId] = false
	local queue = walkQueueByUser[userId]
	if queue and #queue > 0 then
		local nextJob = table.remove(queue, 1)
		if nextJob then
			startWalkJob(userId, nextJob.heroId, nextJob.display, nextJob.pad, nextJob.summon)
		end
	end
end

startWalkJob = function(userId: number, heroId: string, display: Instance, pad: BasePart, summon: BasePart)
	if not display:IsA("Model") then
		placeOnPad(display, pad)
		display:SetAttribute("WalkedIn", true)
		walkBusyByUser[userId] = false
		local queue = walkQueueByUser[userId]
		if queue and #queue > 0 then
			local nextJob = table.remove(queue, 1)
			if nextJob then
				startWalkJob(userId, nextJob.heroId, nextJob.display, nextJob.pad, nextJob.summon)
			end
		end
		return
	end

	local model = display :: Model
	local walking = walkingByUser[userId]
	if walking == nil then
		walking = {}
		walkingByUser[userId] = walking
	end
	walking[heroId] = true
	walkBusyByUser[userId] = true
	stopWalk(heroId)
	playHeroAnim(model, heroId, "walk")

	local startCF = modelStandCFrame(model, summon)
	local endCF = modelStandCFrame(model, pad)
	model:PivotTo(startCF)

	local flat = Vector3.new(endCF.Position.X - startCF.Position.X, 0, endCF.Position.Z - startCF.Position.Z)
	local distance = flat.Magnitude
	local speed = walkSpeed()
	local duration = if distance < 0.5 then 0.05 else math.clamp(distance / speed, 0.35, 12)
	local t0 = os.clock()

	walkConnections[heroId] = RunService.Heartbeat:Connect(function()
		if model.Parent == nil then
			finishWalk(userId, heroId, model, pad)
			return
		end
		local alpha = math.clamp((os.clock() - t0) / duration, 0, 1)
		local pos = startCF.Position:Lerp(endCF.Position, alpha)
		local look = flat
		if look.Magnitude < 0.05 then
			model:PivotTo(CFrame.new(pos) * (endCF - endCF.Position))
		else
			local facing = CFrame.lookAt(pos, pos + look.Unit)
			model:PivotTo(facing)
		end
		if alpha >= 1 then
			finishWalk(userId, heroId, model, pad)
		end
	end)
end

local function enqueueWalk(userId: number, heroId: string, display: Instance, pad: BasePart, summon: BasePart)
	if display:GetAttribute("WalkedIn") == true then
		placeOnPad(display, pad)
		return
	end
	local walking = walkingByUser[userId]
	if walking and walking[heroId] then
		return
	end
	if not walkBusyByUser[userId] then
		startWalkJob(userId, heroId, display, pad, summon)
		return
	end
	local queue = walkQueueByUser[userId]
	if queue == nil then
		queue = {}
		walkQueueByUser[userId] = queue
	end
	for _, job in queue do
		if job.heroId == heroId then
			return
		end
	end
	table.insert(queue, {
		heroId = heroId,
		display = display,
		pad = pad,
		summon = summon,
	})
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

function HeroWorld.RequestWalk(player: Player, heroId: string)
	if typeof(heroId) ~= "string" or heroId == "" then
		return
	end
	local userId = player.UserId
	local requested = walkRequestedByUser[userId]
	if requested == nil then
		requested = {}
		walkRequestedByUser[userId] = requested
	end
	requested[heroId] = true
end

function HeroWorld.Clear(player: Player)
	local userId = player.UserId
	local displays = displaysByUser[userId]
	if displays then
		for heroId, display in displays do
			stopWalk(heroId)
			clearHeroAnims(heroId)
			display:Destroy()
		end
	end
	displaysByUser[userId] = nil
	lastKeyByUser[userId] = nil
	walkingByUser[userId] = nil
	walkQueueByUser[userId] = nil
	walkBusyByUser[userId] = nil
	walkRequestedByUser[userId] = nil

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
			stopWalk(heroId)
			clearHeroAnims(heroId)
			display:Destroy()
			displays[heroId] = nil
			local walking = walkingByUser[userId]
			if walking then
				walking[heroId] = nil
			end
		end
	end

	local parent = academyFolder(academyName)
	local exitGate = DisplayConfig.FindHeroExitGate(academyName)
	local newlyCreated: { [string]: boolean } = {}
	for _, hero in displayed do
		local existing = displays[hero.HeroID]
		if existing and existing:IsA("Part") and existing.Shape == Enum.PartType.Cylinder then
			if DisplayConfig.HeroModelTemplate(hero.Tier, hero.HeroType) then
				stopWalk(hero.HeroID)
				existing:Destroy()
				displays[hero.HeroID] = nil
			end
		end
		if not displays[hero.HeroID] then
			displays[hero.HeroID] = makeDisplay(hero, parent)
			newlyCreated[hero.HeroID] = true
		end
	end

	for _, hero in displayed do
		local display = displays[hero.HeroID]
		local slotIndex = hero.DisplaySlot
		local pad = if typeof(slotIndex) == "number" then slots[slotIndex] else nil
		if display and pad then
			local walking = walkingByUser[userId]
			if walking and walking[hero.HeroID] then
				continue
			end
			if newlyCreated[hero.HeroID] and exitGate then
				local requested = walkRequestedByUser[userId]
				if requested and requested[hero.HeroID] then
					requested[hero.HeroID] = nil
					enqueueWalk(userId, hero.HeroID, display, pad, exitGate)
				else
					placeOnPad(display, pad)
					display:SetAttribute("WalkedIn", true)
					if display:IsA("Model") then
						playHeroAnim(display, hero.HeroID, "idle")
					end
				end
			else
				placeOnPad(display, pad)
				display:SetAttribute("WalkedIn", true)
				if display:IsA("Model") then
					playHeroAnim(display, hero.HeroID, "idle")
				end
			end
		end
	end
end

return HeroWorld
