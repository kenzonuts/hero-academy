--!strict
-- Clones Workspace["GATES LEVEL"].GATE1..GATE10 into each academy as ActiveGate.
-- Visual level follows RecruitmentLevel (capped at MaxGateLevel).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))

local Academy = require(script.Parent:WaitForChild("Academy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local GateDisplay = {}

local ATTR_LEVEL = "GateVisualLevel"

local function asGatePart(inst: Instance?): BasePart?
	if inst == nil then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function gatePartCFrame(inst: Instance?): CFrame?
	local part = asGatePart(inst)
	if part then
		return part.CFrame
	end
	return nil
end

local function findExitInside(root: Instance): Instance?
	local gateName = DisplayConfig.HeroExitGateName()
	return root:FindFirstChild(gateName, true)
end

local function hideLegacyExit(academy: Instance, legacy: Instance?)
	if legacy == nil or legacy.Parent == nil then
		return
	end
	if DisplayConfig.IsInsideGatesCatalog(legacy) then
		return
	end
	local active = academy:FindFirstChild(DisplayConfig.ActiveGateName())
	if active and (legacy == active or legacy:IsDescendantOf(active)) then
		return
	end
	local function hidePart(part: BasePart)
		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
	if legacy:IsA("BasePart") then
		hidePart(legacy)
	end
	for _, inst in legacy:GetDescendants() do
		if inst:IsA("BasePart") then
			hidePart(inst)
		end
	end
	legacy.Name = "_LegacyGateHidden"
end

local function resolveAnchorCF(academy: Instance): (CFrame?, Instance?)
	local activeName = DisplayConfig.ActiveGateName()
	local active = academy:FindFirstChild(activeName)
	if active then
		local cf = gatePartCFrame(findExitInside(active) or active)
		if cf then
			return cf, nil
		end
	end

	local anchor = academy:FindFirstChild(DisplayConfig.GateAnchorName(), true)
	if anchor and anchor:IsA("BasePart") and not DisplayConfig.IsInsideGatesCatalog(anchor) then
		return anchor.CFrame, nil
	end

	local legacy = academy:FindFirstChild(DisplayConfig.HeroExitGateName(), true)
	if legacy and not DisplayConfig.IsInsideGatesCatalog(legacy) then
		local underActive = active ~= nil and legacy:IsDescendantOf(active)
		if not underActive then
			local cf = gatePartCFrame(legacy)
			if cf then
				return cf, legacy
			end
		end
	end

	local summon = DisplayConfig.FindSummonInstance(academy.Name)
	if summon then
		local part = if summon:IsA("BasePart")
			then summon
			elseif summon:IsA("Model") then (summon.PrimaryPart or summon:FindFirstChildWhichIsA("BasePart", true))
			else nil
		if part and part:IsA("BasePart") then
			return part.CFrame, nil
		end
	end

	local anyPart = academy:FindFirstChildWhichIsA("BasePart", true)
	if anyPart and not DisplayConfig.IsInsideGatesCatalog(anyPart) then
		return anyPart.CFrame, nil
	end

	return nil, nil
end

local function toModel(source: Instance): Model
	if source:IsA("Model") then
		return source
	end
	local model = Instance.new("Model")
	model.Name = source.Name
	for _, child in source:GetChildren() do
		child.Parent = model
	end
	if source.Parent then
		source:Destroy()
	end
	return model
end

local function alignGateModel(model: Model, targetCF: CFrame)
	local exitInst = findExitInside(model) or model
	local part = asGatePart(exitInst)
	if part == nil then
		model:PivotTo(targetCF)
		return
	end
	local delta = targetCF * part.CFrame:Inverse()
	model:PivotTo(delta * model:GetPivot())
end

local function freezeDecor(model: Model)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
		elseif inst:IsA("BaseScript") then
			inst:Destroy()
		end
	end
end

function GateDisplay.Sync(player: Player)
	local state = PlayerData.Get(player)
	local academy = Academy.GetFolder(player)
	if state == nil or academy == nil then
		return
	end

	local gateLevel = DisplayConfig.GateLevelFromRecruitment(state.RecruitmentLevel)
	local activeName = DisplayConfig.ActiveGateName()
	local existing = academy:FindFirstChild(activeName)
	if existing and academy:GetAttribute(ATTR_LEVEL) == gateLevel then
		return
	end

	local template = DisplayConfig.FindGateTemplate(gateLevel)
	if template == nil then
		warn("[GateDisplay] missing template", DisplayConfig.GatePrefix() .. tostring(gateLevel))
		return
	end

	local anchorCF, legacyToHide = resolveAnchorCF(academy)
	if existing then
		existing:Destroy()
	end

	local raw = template:Clone()
	raw.Name = activeName
	local model = toModel(raw)
	model.Name = activeName
	freezeDecor(model)

	local exitPart = asGatePart(findExitInside(model))
	if exitPart and model.PrimaryPart == nil then
		model.PrimaryPart = exitPart
	end

	model.Parent = academy
	if anchorCF then
		alignGateModel(model, anchorCF)
	else
		warn("[GateDisplay] no GateAnchor/gate/summon in", academy.Name, "- ActiveGate left at default pivot")
	end
	hideLegacyExit(academy, legacyToHide)
	academy:SetAttribute(ATTR_LEVEL, gateLevel)
end

function GateDisplay.Clear(player: Player)
	local academy = Academy.GetFolder(player)
	if academy == nil then
		return
	end
	local active = academy:FindFirstChild(DisplayConfig.ActiveGateName())
	if active then
		active:Destroy()
	end
	academy:SetAttribute(ATTR_LEVEL, nil)
end

return GateDisplay
