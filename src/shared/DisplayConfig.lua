--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local DisplayConfig = {}

function DisplayConfig.MaxSlots(): number
	local display = GameConfig.Display
	local configured = 40
	local value = display and display.MaxSlots
	if typeof(value) == "number" then
		configured = value
	end
	local names = DisplayConfig.AcademyNames()
	local template = DisplayConfig.AcademyFolder(names[1])
	local pads = DisplayConfig.CollectPadParts(template)
	if #pads == 0 then
		return configured
	end
	return math.min(configured, #pads)
end

function DisplayConfig.PadName(): string
	local display = GameConfig.Display
	local value = display and display.PadName
	if typeof(value) == "string" and value ~= "" then
		return string.lower(value)
	end
	return "hero"
end

function DisplayConfig.PadFolder(): string
	local display = GameConfig.Display
	local value = display and display.PadFolder
	if typeof(value) == "string" and value ~= "" then
		return value
	end
	return "hero"
end

function DisplayConfig.AcademyNames(): { string }
	local academy = GameConfig.Academy
	local prefix = "AKADEMI"
	local count = 6
	if academy then
		if typeof(academy.Prefix) == "string" and academy.Prefix ~= "" then
			prefix = academy.Prefix
		end
		if typeof(academy.Count) == "number" then
			count = math.max(1, math.floor(academy.Count))
		end
	end
	local names = {}
	for index = 1, count do
		table.insert(names, prefix .. tostring(index))
	end
	return names
end

function DisplayConfig.AcademyFolder(name: string?): Instance?
	if typeof(name) ~= "string" or name == "" then
		return nil
	end
	local Workspace = game:GetService("Workspace")
	return Workspace:FindFirstChild(name)
end

function DisplayConfig.MaxOwnedHeroes(): number
	local display = GameConfig.Display
	local value = display and display.MaxOwnedHeroes
	if typeof(value) == "number" then
		return math.max(1, math.floor(value))
	end
	return 40
end

local function asPad(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function nameMatches(inst: Instance): boolean
	local name = string.lower(inst.Name)
	local primary = DisplayConfig.PadName()
	return name == primary or name == "hero summon"
end

local function sameSpot(a: BasePart, b: BasePart): boolean
	local dx = a.Position.X - b.Position.X
	local dz = a.Position.Z - b.Position.Z
	return (dx * dx + dz * dz) < 2.25
end

function DisplayConfig.CollectPadParts(root: Instance?): { BasePart }
	local Workspace = game:GetService("Workspace")
	local found: { BasePart } = {}
	local roots: { Instance } = {}
	local searchRoot = root

	local function alreadyCovered(inst: Instance): boolean
		for _, chosen in roots do
			if inst == chosen or inst:IsDescendantOf(chosen) or chosen:IsDescendantOf(inst) then
				return true
			end
		end
		return false
	end

	local function addPad(inst: Instance)
		if alreadyCovered(inst) then
			return
		end
		local part = asPad(inst)
		if part == nil then
			return
		end
		for _, existing in found do
			if existing == part or sameSpot(existing, part) then
				return
			end
		end
		table.insert(roots, inst)
		table.insert(found, part)
	end

	local function addDirectChildren(folder: Instance?)
		if folder == nil then
			return
		end
		for _, child in folder:GetChildren() do
			addPad(child)
		end
	end

	if searchRoot == nil then
		local names = DisplayConfig.AcademyNames()
		searchRoot = DisplayConfig.AcademyFolder(names[1])
	end

	if searchRoot then
		addDirectChildren(searchRoot:FindFirstChild(DisplayConfig.PadFolder()))
		if #found == 0 then
			addDirectChildren(searchRoot:FindFirstChild("altar"))
		end
		if #found == 0 then
			for _, inst in searchRoot:GetDescendants() do
				if nameMatches(inst) then
					addPad(inst)
				end
			end
		end
	end

	if #found == 0 and root == nil then
		addDirectChildren(Workspace:FindFirstChild(DisplayConfig.PadFolder()))
		if #found == 0 then
			addDirectChildren(Workspace:FindFirstChild("altar"))
		end
	end

	table.sort(found, function(a, b)
		if a.Position.X ~= b.Position.X then
			return a.Position.X < b.Position.X
		end
		return a.Position.Z < b.Position.Z
	end)

	local configured = 40
	local display = GameConfig.Display
	if display and typeof(display.MaxSlots) == "number" then
		configured = display.MaxSlots
	end
	local slots: { BasePart } = {}
	for index = 1, math.min(configured, #found) do
		table.insert(slots, found[index])
	end
	return slots
end

function DisplayConfig.MarkerHeight(): number
	local display = GameConfig.Display
	local value = display and display.MarkerHeight
	if typeof(value) == "number" then
		return value
	end
	return 2.4
end

local function numericId(value: any, fallback: string): string
	if typeof(value) == "number" then
		return tostring(math.floor(value))
	end
	if typeof(value) == "string" and value ~= "" then
		local digits = string.match(value, "(%d+)")
		if digits then
			return digits
		end
	end
	return fallback
end

-- Thumbnail URL so ImageLabel can show an uploaded Image asset (rbxassetid often stays 0x0).
local function thumbImage(value: any, fallbackId: string): string
	local id = numericId(value, fallbackId)
	return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", id)
end

function DisplayConfig.GoldImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.GoldImage, "129136027133209")
end

function DisplayConfig.MagicStoneImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.MagicStoneImage, "116631277815450")
end

function DisplayConfig.BlackCrystalImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.BlackCrystalImage, "96330948981939")
end

function DisplayConfig.RecruitmentBoardImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentBoardImage, "99473344266235")
end

function DisplayConfig.RecruitmentBoardCloseImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentBoardCloseImage, "101015762977670")
end

function DisplayConfig.RecruitmentSlotEmptyImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentSlotEmptyImage, "118354964205016")
end

function DisplayConfig.RecruitmentSlotClosedImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentSlotClosedImage, "71614679116854")
end

function DisplayConfig.RecruitmentCardGlowImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentCardGlowImage, "76685873525509")
end

local CARD_TIER_KEY = {
	B1 = "B1",
	B2 = "B2",
	B3 = "B3",
	B4 = "B3",
	B5 = "B3",
	B6 = "B3",
	B7 = "B3",
}

function DisplayConfig.RecruitmentCardImage(tier: string, heroType: string): string?
	local display = GameConfig.Display
	local cards = display and display.RecruitmentCards
	if typeof(cards) ~= "table" then
		return nil
	end
	local tierKey = CARD_TIER_KEY[tier] or "B3"
	local byTier = cards[tierKey]
	if typeof(byTier) ~= "table" then
		return nil
	end
	local raw = byTier[heroType]
	local id = numericId(raw, "")
	if id == "" then
		return nil
	end
	return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", id)
end

function DisplayConfig.RecruitmentTakeAllImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentTakeAllImage, "81879706897992")
end

function DisplayConfig.RecruitmentTakeAllOffImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentTakeAllOffImage, "124096776237817")
end

function DisplayConfig.RecruitmentClearAllImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentClearAllImage, "82321373313572")
end

function DisplayConfig.RecruitmentClearAllOffImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentClearAllOffImage, "113494313258023")
end

function DisplayConfig.RecruitmentOpenAllImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentOpenAllImage, "131641419808933")
end

function DisplayConfig.RecruitmentOpenAllOffImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentOpenAllOffImage, "99197636965121")
end

function DisplayConfig.RecruitmentRecruitOnImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentRecruitOnImage, "118490906708775")
end

function DisplayConfig.RecruitmentRecruitOffImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentRecruitOffImage, "126413221049424")
end

function DisplayConfig.RecruitmentGoldImage(): string
	local display = GameConfig.Display
	return thumbImage(display and display.RecruitmentGoldImage, "84858883493617")
end

function DisplayConfig.SummonName(): string
	local display = GameConfig.Display
	local value = display and display.SummonName
	if typeof(value) == "string" and value ~= "" then
		return string.lower(value)
	end
	return "summon"
end

function DisplayConfig.IsSummonInstance(inst: Instance): boolean
	local name = string.lower(inst.Name)
	if name == "summonplate" or name == "summon" then
		return true
	end
	if string.sub(name, 1, 6) == "summon" then
		return true
	end
	local display = GameConfig.Display
	local names = display and display.SummonPartNames
	if typeof(names) == "table" then
		for _, allowed in names do
			if typeof(allowed) == "string" and name == string.lower(allowed) then
				return true
			end
		end
	end
	return name == DisplayConfig.SummonName()
end

function DisplayConfig.FindSummonInstance(academyName: string?): Instance?
	local folder = DisplayConfig.AcademyFolder(academyName)
	if folder == nil then
		return nil
	end

	local preferred: Instance? = nil
	local fallback: Instance? = nil
	local function consider(inst: Instance)
		if not DisplayConfig.IsSummonInstance(inst) then
			return
		end
		if string.lower(inst.Name) == "summonplate" and inst:IsA("BasePart") then
			preferred = inst
			return
		end
		if fallback == nil then
			fallback = inst
		end
	end

	local altar = folder:FindFirstChild("altar")
	if altar then
		for _, child in altar:GetChildren() do
			consider(child)
			for _, nested in child:GetDescendants() do
				consider(nested)
			end
		end
	end
	if preferred then
		return preferred
	end
	if fallback then
		return fallback
	end

	for _, inst in folder:GetDescendants() do
		consider(inst)
	end
	return preferred or fallback
end

function DisplayConfig.CollectSummonParts(academyName: string?): { BasePart }
	local folder = DisplayConfig.AcademyFolder(academyName)
	local found: { BasePart } = {}
	if folder == nil then
		return found
	end

	local function add(part: BasePart)
		for _, existing in found do
			if existing == part then
				return
			end
		end
		table.insert(found, part)
	end

	for _, inst in folder:GetDescendants() do
		if DisplayConfig.IsSummonInstance(inst) then
			if inst:IsA("BasePart") then
				add(inst)
			elseif inst:IsA("Model") then
				local part = asPad(inst)
				if part then
					add(part)
				end
				for _, nested in inst:GetDescendants() do
					if nested:IsA("BasePart") then
						add(nested)
					end
				end
			end
		end
	end

	return found
end

function DisplayConfig.FindSummonPart(academyName: string?): BasePart?
	local inst = DisplayConfig.FindSummonInstance(academyName)
	if inst == nil then
		return nil
	end
	return asPad(inst)
end

function DisplayConfig.HeroModelTemplate(tier: string, heroType: string): Instance?
	local Workspace = game:GetService("Workspace")
	local display = GameConfig.Display
	local config = display and display.HeroModels
	if typeof(config) ~= "table" then
		return nil
	end
	local folderName = config.Folder
	if typeof(folderName) ~= "string" or folderName == "" then
		folderName = "HEROES"
	end
	local root = Workspace:FindFirstChild(folderName)
	if root == nil then
		return nil
	end
	local tiers = config.Tiers
	local tierFolderName = "COMMON"
	if typeof(tiers) == "table" and typeof(tiers[tier]) == "string" then
		tierFolderName = tiers[tier]
	elseif tier ~= "B1" then
		return nil
	end
	local tierFolder = root:FindFirstChild(tierFolderName)
	if tierFolder == nil then
		return nil
	end
	local names = config.Names
	local suffix = heroType
	if typeof(names) == "table" and typeof(names[heroType]) == "string" then
		suffix = names[heroType]
	end
	local modelName = tierFolderName .. " " .. suffix
	return tierFolder:FindFirstChild(modelName)
end

return DisplayConfig
