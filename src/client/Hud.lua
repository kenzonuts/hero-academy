--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RaidConfig = require(Shared:WaitForChild("RaidConfig"))
local Types = require(Shared:WaitForChild("Types"))
local RecruitmentBoard = require(script.Parent:WaitForChild("RecruitmentBoard"))

local Hud = {}

local ROW_HEIGHT = 28
local NAV_WIDTH = 400
local CURRENCY_WIDTH = 0.28
local CURRENCY_HEIGHT = 0.28
local CURRENCY_POS_X = 0.008
local CURRENCY_POS_Y = 0.995
local CURRENCY_TEXT_MIN = 16
local CURRENCY_TEXT_MAX = 28
local CURRENCY_ICON_SCALE = 2.55
-- Negative = teks nempel/nnumpuk di sisi kanan icon. Lebih negatif = lebih ke kiri.
local CURRENCY_TEXT_GAP = -0.58
local TAB_IDLE = Color3.fromRGB(40, 44, 58)
local TAB_ON = Color3.fromRGB(50, 105, 180)
local DISABLED = Color3.fromRGB(70, 70, 80)
local STROKE = Color3.fromRGB(70, 78, 100)

type TabId = "heroes" | "facilities" | "raid"

local function fmtInt(value: number): string
	local n = math.floor(value + 0.5)
	local sign = ""
	if n < 0 then
		sign = "-"
		n = -n
	end
	local raw = tostring(n)
	local withCommas = raw:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return sign .. withCommas
end

local function fmtCompact(value: number): string
	local n = math.floor(value + 0.5)
	local sign = ""
	if n < 0 then
		sign = "-"
		n = -n
	end
	if n < 1000 then
		return sign .. tostring(n)
	end
	local units = {
		{ 1e12, "T" },
		{ 1e9, "B" },
		{ 1e6, "M" },
		{ 1e3, "K" },
	}
	for _, unit in units do
		local size = unit[1]
		local suffix = unit[2]
		if n >= size then
			local scaled = n / size
			if scaled >= 100 then
				return sign .. tostring(math.floor(scaled + 0.5)) .. suffix
			end
			local tenths = math.floor(scaled * 10 + 0.5) / 10
			if tenths == math.floor(tenths) then
				return sign .. tostring(math.floor(tenths)) .. suffix
			end
			return sign .. string.format("%.1f", tenths) .. suffix
		end
	end
	return sign .. tostring(n)
end

local function addCorner(inst: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = inst
end

local function addStroke(inst: Instance, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = inst
end

local function makeLabel(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = ""
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = UDim2.fromOffset(120, 36)
	button.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 16
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 6)
	return button
end

local function makeCurrencyRow(
	parent: Instance,
	name: string,
	image: string,
	textColor: Color3,
	strokeColor: Color3,
	order: number
): TextLabel
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0.24, 0)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.ClipsDescendants = false
	row.Parent = parent

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(0, 0.5)
	icon.Size = UDim2.fromScale(CURRENCY_ICON_SCALE, CURRENCY_ICON_SCALE)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Image = image
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 2
	icon.Parent = row

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.AnchorPoint = Vector2.new(0, 0.5)
	amount.BackgroundTransparency = 1
	amount.Font = Enum.Font.GothamBlack
	amount.Text = "0"
	amount.TextColor3 = textColor
	amount.TextScaled = true
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextYAlignment = Enum.TextYAlignment.Center
	amount.ZIndex = 3
	amount.Parent = row
	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 3.5
	stroke.Parent = amount
	local textSize = Instance.new("UITextSizeConstraint")
	textSize.MinTextSize = CURRENCY_TEXT_MIN
	textSize.MaxTextSize = CURRENCY_TEXT_MAX
	textSize.Parent = amount

	local function placeText()
		local iconWidth = icon.AbsoluteSize.X
		local textX = math.floor(iconWidth * (1 + CURRENCY_TEXT_GAP))
		if textX < 0 then
			textX = 0
		end
		amount.Position = UDim2.new(0, textX, 0.5, 0)
		amount.Size = UDim2.new(1, -textX, 0.9, 0)
	end
	icon:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeText)
	task.defer(placeText)

	return amount
end

local function makePanel(parent: Instance, name: string, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	addCorner(frame, 8)
	addStroke(frame, STROKE)
	return frame
end

function Hud.Start(remotes: {
	StateUpdated: RemoteEvent,
	Recruit: RemoteFunction,
	Accept: RemoteFunction,
	Reject: RemoteFunction,
	GetSnapshot: RemoteFunction,
	Sell: RemoteFunction,
	UpgradeRecruitment: RemoteFunction,
	UpgradeConverter: RemoteFunction,
	StartRaid: RemoteFunction,
}, onSnapshot: ((Types.PlayerSnapshot) -> ())?)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "HeroRecruitmentHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 20
	gui.Parent = player:WaitForChild("PlayerGui")

	local currencyBar = Instance.new("Frame")
	currencyBar.Name = "CurrencyBar"
	currencyBar.AnchorPoint = Vector2.new(0, 1)
	currencyBar.Position = UDim2.new(CURRENCY_POS_X, 0, CURRENCY_POS_Y, 0)
	currencyBar.Size = UDim2.new(CURRENCY_WIDTH, 0, CURRENCY_HEIGHT, 0)
	currencyBar.BackgroundTransparency = 1
	currencyBar.ClipsDescendants = false
	currencyBar.ZIndex = 30
	currencyBar.Parent = gui

	local currencyLayout = Instance.new("UIListLayout")
	currencyLayout.FillDirection = Enum.FillDirection.Vertical
	currencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	currencyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	currencyLayout.Padding = UDim.new(0.02, 0)
	currencyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	currencyLayout.Parent = currencyBar

	local blackAmount = makeCurrencyRow(
		currencyBar,
		"BlackCrystal",
		DisplayConfig.BlackCrystalImage(),
		Color3.fromRGB(235, 235, 240),
		Color3.fromRGB(12, 12, 16),
		1
	)
	local stoneAmount = makeCurrencyRow(
		currencyBar,
		"MagicStone",
		DisplayConfig.MagicStoneImage(),
		Color3.fromRGB(220, 90, 210),
		Color3.fromRGB(255, 245, 255),
		2
	)
	local goldAmount = makeCurrencyRow(
		currencyBar,
		"Gold",
		DisplayConfig.GoldImage(),
		Color3.fromRGB(255, 215, 55),
		Color3.fromRGB(20, 35, 80),
		3
	)

	local blackRow = blackAmount.Parent :: Frame
	local stoneRow = stoneAmount.Parent :: Frame
	local goldRow = goldAmount.Parent :: Frame

	local function applyRowIconScale(row: Frame, scale: number)
		local icon = row:FindFirstChild("Icon")
		if icon and icon:IsA("ImageLabel") then
			icon.Size = UDim2.fromScale(scale, scale)
		end
	end

	local function setCurrencyDocked(onBoard: boolean)
		if onBoard then
			currencyBar.AnchorPoint = Vector2.new(0, 0)
			currencyBar.Position = UDim2.new(0.02, 0, 0.012, 0)
			currencyBar.Size = UDim2.new(0.22, 0, 0.085, 0)
			currencyLayout.FillDirection = Enum.FillDirection.Horizontal
			currencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			currencyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			currencyLayout.Padding = UDim.new(0, 0)
			stoneRow.Visible = false
			blackRow.Visible = false
			goldRow.Visible = true
			goldRow.LayoutOrder = 1
			goldRow.Size = UDim2.new(1, 0, 1, 0)
			applyRowIconScale(goldRow, 1.7)
		else
			currencyBar.AnchorPoint = Vector2.new(0, 1)
			currencyBar.Position = UDim2.new(CURRENCY_POS_X, 0, CURRENCY_POS_Y, 0)
			currencyBar.Size = UDim2.new(CURRENCY_WIDTH, 0, CURRENCY_HEIGHT, 0)
			currencyLayout.FillDirection = Enum.FillDirection.Vertical
			currencyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			currencyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			currencyLayout.Padding = UDim.new(0.02, 0)
			blackRow.Visible = true
			stoneRow.Visible = true
			goldRow.Visible = true
			blackRow.LayoutOrder = 1
			stoneRow.LayoutOrder = 2
			goldRow.LayoutOrder = 3
			for _, row in { blackRow, stoneRow, goldRow } do
				row.Size = UDim2.new(1, 0, 0.24, 0)
				applyRowIconScale(row, CURRENCY_ICON_SCALE)
			end
		end
	end

	local shell = Instance.new("Frame")
	shell.Name = "HudShell"
	shell.AnchorPoint = Vector2.new(1, 0)
	shell.Position = UDim2.new(1, -16, 0, 12)
	shell.Size = UDim2.fromOffset(NAV_WIDTH, 0)
	shell.AutomaticSize = Enum.AutomaticSize.Y
	shell.BackgroundTransparency = 1
	shell.ZIndex = 21
	shell.Parent = gui

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, 8)
	stack.Parent = shell

	local navBar = Instance.new("Frame")
	navBar.Name = "NavBar"
	navBar.LayoutOrder = 1
	navBar.Size = UDim2.fromOffset(NAV_WIDTH, 86)
	navBar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	navBar.BackgroundTransparency = 0.08
	navBar.BorderSizePixel = 0
	navBar.Parent = shell
	addCorner(navBar, 8)
	addStroke(navBar, STROKE)

	local heroesTab = makeButton(navBar, "TabHeroes", "Heroes", UDim2.fromOffset(16, 8))
	heroesTab.Size = UDim2.fromOffset(118, 32)
	local facilitiesTab = makeButton(navBar, "TabFacilities", "Upgrade", UDim2.fromOffset(142, 8))
	facilitiesTab.Size = UDim2.fromOffset(118, 32)
	local raidTab = makeButton(navBar, "TabRaid", "Raid", UDim2.fromOffset(268, 8))
	raidTab.Size = UDim2.fromOffset(118, 32)

	local status = makeLabel(navBar, "Status", UDim2.fromOffset(14, 46), UDim2.new(1, -28, 0, 32))
	status.TextSize = 13
	status.TextColor3 = Color3.fromRGB(180, 220, 160)
	status.TextYAlignment = Enum.TextYAlignment.Center
	status.Text = "Click a tab to open. Recruit at the summon pad."

	local collectionPanel = makePanel(shell, "CollectionPanel", UDim2.fromOffset(NAV_WIDTH, 400))
	collectionPanel.LayoutOrder = 2

	local collectionTitle = makeLabel(collectionPanel, "Title", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 48))
	collectionTitle.Font = Enum.Font.GothamBold
	collectionTitle.TextSize = 18
	collectionTitle.Text = "MY HEROES"

	local lastHeroKey = ""

	local function heroKey(heroes: { Types.Hero }): string
		local parts = {}
		for _, hero in heroes do
			table.insert(parts, hero.HeroID .. ":" .. hero.Status .. ":" .. tostring(hero.Production))
		end
		return table.concat(parts, "|")
	end

	local list = Instance.new("ScrollingFrame")
	list.Name = "HeroList"
	list.Position = UDim2.fromOffset(12, 64)
	list.Size = UDim2.new(1, -24, 1, -118)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = collectionPanel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	local selectedHeroId: string? = nil
	local latestHeroes: { Types.Hero } = {}
	local openTab: TabId? = nil
	local paintTabs: () -> () = function() end
	local board: RecruitmentBoard.BoardHandle? = nil

	local sellButton = makeButton(collectionPanel, "Sell", "Sell", UDim2.fromOffset(16, 352))
	sellButton.Size = UDim2.new(1, -32, 0, 36)
	sellButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)

	local facilitiesPanel = makePanel(shell, "FacilitiesPanel", UDim2.fromOffset(NAV_WIDTH, 132))
	facilitiesPanel.LayoutOrder = 4

	local facilitiesTitle = makeLabel(facilitiesPanel, "Title", UDim2.fromOffset(16, 8), UDim2.new(1, -32, 0, 22))
	facilitiesTitle.Font = Enum.Font.GothamBold
	facilitiesTitle.TextSize = 16
	facilitiesTitle.Text = "FACILITIES"

	local recruitUpgradeButton = makeButton(facilitiesPanel, "UpgradeRecruitment", "Upgrade Recruitment", UDim2.fromOffset(16, 36))
	recruitUpgradeButton.Size = UDim2.new(1, -32, 0, 36)
	recruitUpgradeButton.BackgroundColor3 = Color3.fromRGB(40, 90, 160)

	local converterUpgradeButton = makeButton(facilitiesPanel, "UpgradeConverter", "Upgrade Converter", UDim2.fromOffset(16, 80))
	converterUpgradeButton.Size = UDim2.new(1, -32, 0, 36)
	converterUpgradeButton.BackgroundColor3 = Color3.fromRGB(40, 120, 110)

	local raidPanel = makePanel(shell, "RaidPanel", UDim2.fromOffset(NAV_WIDTH, 470))
	raidPanel.LayoutOrder = 5

	local raidTitle = makeLabel(raidPanel, "Title", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 22))
	raidTitle.Font = Enum.Font.GothamBold
	raidTitle.TextSize = 18
	raidTitle.Text = "RAID"

	local raidTimer = makeLabel(raidPanel, "Timer", UDim2.fromOffset(16, 36), UDim2.new(1, -32, 0, 42))
	raidTimer.Font = Enum.Font.GothamBold
	raidTimer.TextSize = 36
	raidTimer.TextXAlignment = Enum.TextXAlignment.Center
	raidTimer.TextYAlignment = Enum.TextYAlignment.Center
	raidTimer.TextColor3 = Color3.fromRGB(255, 210, 120)
	raidTimer.Visible = false

	local raidBarBack = Instance.new("Frame")
	raidBarBack.Name = "RaidBar"
	raidBarBack.Position = UDim2.fromOffset(16, 82)
	raidBarBack.Size = UDim2.new(1, -32, 0, 10)
	raidBarBack.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
	raidBarBack.BorderSizePixel = 0
	raidBarBack.Visible = false
	raidBarBack.Parent = raidPanel
	addCorner(raidBarBack, 4)
	local raidBarFill = Instance.new("Frame")
	raidBarFill.Name = "Fill"
	raidBarFill.Size = UDim2.fromScale(1, 1)
	raidBarFill.BackgroundColor3 = Color3.fromRGB(220, 160, 70)
	raidBarFill.BorderSizePixel = 0
	raidBarFill.Parent = raidBarBack
	addCorner(raidBarFill, 4)

	local raidMaps = Instance.new("Frame")
	raidMaps.Name = "Maps"
	raidMaps.BackgroundTransparency = 1
	raidMaps.Position = UDim2.fromOffset(12, 36)
	raidMaps.Size = UDim2.new(1, -24, 0, 140)
	raidMaps.Parent = raidPanel
	local mapLayout = Instance.new("UIListLayout")
	mapLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mapLayout.Padding = UDim.new(0, 4)
	mapLayout.Parent = raidMaps

	local raidInfo = makeLabel(raidPanel, "Info", UDim2.fromOffset(16, 180), UDim2.new(1, -32, 0, 72))
	raidInfo.TextSize = 14

	local raidHeroList = Instance.new("ScrollingFrame")
	raidHeroList.Name = "RaidHeroes"
	raidHeroList.Position = UDim2.fromOffset(12, 254)
	raidHeroList.Size = UDim2.new(1, -24, 0, 150)
	raidHeroList.BackgroundTransparency = 1
	raidHeroList.BorderSizePixel = 0
	raidHeroList.ScrollBarThickness = 6
	raidHeroList.CanvasSize = UDim2.fromOffset(0, 0)
	raidHeroList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	raidHeroList.Parent = raidPanel
	local raidHeroLayout = Instance.new("UIListLayout")
	raidHeroLayout.SortOrder = Enum.SortOrder.LayoutOrder
	raidHeroLayout.Padding = UDim.new(0, 4)
	raidHeroLayout.Parent = raidHeroList

	local startRaidButton = makeButton(raidPanel, "StartRaid", "START RAID", UDim2.fromOffset(16, 418))
	startRaidButton.Size = UDim2.new(1, -32, 0, 36)
	startRaidButton.BackgroundColor3 = Color3.fromRGB(160, 90, 40)

	local maps = RaidConfig.Maps()
	local selectedMapId = if maps[1] then maps[1].Id else "WhisperingForest"
	local raidPicked: { [string]: boolean } = {}
	local lastRaidNotice = ""
	local lastRaidHeroKey = ""
	local latestSnapshot: Types.PlayerSnapshot? = nil
	local hasRaid = false
	local wasRaiding = false
	local raidBarId = ""
	local raidBarTotal = 1

	local function formatTime(seconds: number): string
		local safe = math.max(0, math.floor(seconds))
		return string.format("%d:%02d", math.floor(safe / 60), safe % 60)
	end

	local function pickedCount(): number
		local count = 0
		for _ in raidPicked do
			count += 1
		end
		return count
	end

	local function pickedIds(): { string }
		local ids = {}
		for _, hero in latestHeroes do
			if raidPicked[hero.HeroID] then
				table.insert(ids, hero.HeroID)
			end
		end
		return ids
	end

	local function paintMapButtons()
		for _, child in raidMaps:GetChildren() do
			if child:IsA("TextButton") then
				local on = child.Name == selectedMapId
				child.BackgroundColor3 = if on then TAB_ON else Color3.fromRGB(32, 36, 48)
			end
		end
	end

	for index, map in maps do
		local row = Instance.new("TextButton")
		row.Name = map.Id
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BorderSizePixel = 0
		row.AutoButtonColor = true
		row.Font = Enum.Font.Gotham
		row.TextSize = 13
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Color3.new(1, 1, 1)
		row.Text = string.format(
			"  %s   Rec %d   %s   %d Gold",
			map.DisplayName or map.Id,
			map.RecommendedPower or 0,
			formatTime(RaidConfig.DurationSeconds(map)),
			map.BaseGoldReward or 0
		)
		row.Parent = raidMaps
		addCorner(row, 4)
		row.MouseButton1Click:Connect(function()
			selectedMapId = map.Id
			paintMapButtons()
			refreshRaidPreview()
		end)
	end
	paintMapButtons()

	paintTabs = function()
		heroesTab.BackgroundColor3 = if openTab == "heroes" then TAB_ON else TAB_IDLE
		facilitiesTab.BackgroundColor3 = if openTab == "facilities" then TAB_ON else TAB_IDLE
		raidTab.BackgroundColor3 = if openTab == "raid" then TAB_ON else TAB_IDLE
		raidTab.Text = if hasRaid then "Raid •" else "Raid"
		collectionPanel.Visible = openTab == "heroes"
		facilitiesPanel.Visible = openTab == "facilities"
		raidPanel.Visible = openTab == "raid"
	end

	local function setOpenTab(tab: TabId)
		if openTab == tab then
			openTab = nil
		else
			openTab = tab
		end
		paintTabs()
	end

	local function refreshRaidPreview()
		local map = RaidConfig.GetMap(selectedMapId)
		local raid = if latestSnapshot then latestSnapshot.ActiveRaid else nil
		if raid then
			raidMaps.Visible = false
			raidHeroList.Visible = false
			startRaidButton.Visible = false
			raidTimer.Visible = true
			raidBarBack.Visible = true
			raidTitle.Text = "RAID IN PROGRESS"
			if raid.RaidID ~= raidBarId then
				raidBarId = raid.RaidID
				raidBarTotal = math.max(raid.RemainingSeconds, 1)
			end
			local frac = math.clamp(raid.RemainingSeconds / raidBarTotal, 0, 1)
			raidBarFill.Size = UDim2.new(frac, 0, 1, 0)
			raidTimer.Text = formatTime(raid.RemainingSeconds)
			raidInfo.Position = UDim2.fromOffset(16, 100)
			raidInfo.Size = UDim2.new(1, -32, 0, 120)
			raidInfo.Text = string.format(
				"%s\nTeam Power %d   Rec %d   Chance %d%%\nHeroes deployed — production paused",
				raid.MapName,
				raid.TeamPower,
				raid.RecommendedPower,
				math.floor(raid.SuccessChance * 100 + 0.5)
			)
			return
		end

		raidBarId = ""
		raidTimer.Visible = false
		raidBarBack.Visible = false
		raidTitle.Text = "RAID"
		raidMaps.Visible = true
		raidHeroList.Visible = true
		startRaidButton.Visible = true
		raidInfo.Position = UDim2.fromOffset(16, 180)
		raidInfo.Size = UDim2.new(1, -32, 0, 72)

		local teamPower = 0
		local count = 0
		for _, hero in latestHeroes do
			if raidPicked[hero.HeroID] then
				if hero.Status == "RAIDING" then
					raidPicked[hero.HeroID] = nil
				else
					teamPower += hero.Power
					count += 1
				end
			end
		end

		local recommended = if map and typeof(map.RecommendedPower) == "number" then map.RecommendedPower else 0
		local chance = if map then RaidConfig.SuccessChance(teamPower, recommended) else 0.05
		local reward = if map and typeof(map.BaseGoldReward) == "number" then map.BaseGoldReward else 0
		local raidTime = if map then RaidConfig.DurationSeconds(map, teamPower) else 180
		local maxHeroes = RaidConfig.MaxHeroes()
		raidInfo.Text = string.format(
			"%s\nTeam %d/%d   Power %s / Rec %s   Chance %d%%\nTime %s   Reward %s Gold",
			if map then (map.DisplayName or map.Id) else "Pick a map",
			count,
			maxHeroes,
			fmtInt(teamPower),
			fmtInt(recommended),
			math.floor(chance * 100 + 0.5),
			formatTime(raidTime),
			fmtInt(reward)
		)
		if count < RaidConfig.MinHeroes() or count > maxHeroes then
			startRaidButton.BackgroundColor3 = DISABLED
		else
			startRaidButton.BackgroundColor3 = Color3.fromRGB(160, 90, 40)
		end
	end

	local function renderRaidHeroes(heroes: { Types.Hero })
		for _, child in raidHeroList:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local maxHeroes = RaidConfig.MaxHeroes()
		for index, hero in heroes do
			local row = Instance.new("TextButton")
			row.Name = hero.HeroID
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -8, 0, 24)
			row.AutoButtonColor = true
			row.BorderSizePixel = 0
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextXAlignment = Enum.TextXAlignment.Left
			local picked = raidPicked[hero.HeroID] == true
			local busy = hero.Status == "RAIDING"
			row.TextColor3 = if busy then Color3.fromRGB(160, 160, 170) else Color3.fromRGB(230, 230, 235)
			row.BackgroundColor3 = if picked then Color3.fromRGB(90, 70, 40) else Color3.fromRGB(32, 36, 48)
			row.Text = string.format(
				"  %s %s %s   PWR %d   %s",
				if picked then "✓" else " ",
				hero.Tier,
				hero.HeroType,
				hero.Power,
				if busy then "RAIDING" else (if hero.Status == "BAGGED" then "TAS" else "PAD")
			)
			row.BackgroundTransparency = 0.1
			row.Parent = raidHeroList
			addCorner(row, 4)
			row.MouseButton1Click:Connect(function()
				if hero.Status == "RAIDING" then
					return
				end
				if raidPicked[hero.HeroID] then
					raidPicked[hero.HeroID] = nil
				elseif pickedCount() < maxHeroes then
					raidPicked[hero.HeroID] = true
				end
				renderRaidHeroes(latestHeroes)
				refreshRaidPreview()
			end)
		end
	end


	local function sellRefund(hero: Types.Hero): number?
		if hero.Status == "RAIDING" then
			return nil
		end
		local allowSeed = GameConfig.Sell and GameConfig.Sell.AllowSeedHeroSell == true
		if not hero.Purchased and not allowSeed then
			return nil
		end
		local percent = (GameConfig.Sell and GameConfig.Sell.RefundPercent) or 0.25
		local cost = hero.AcceptCost
		if cost <= 0 then
			cost = GameConfig.CatalogAcceptCost(hero.Tier)
		end
		return math.floor(cost * percent)
	end

	local function selectedHero(): Types.Hero?
		if not selectedHeroId then
			return nil
		end
		for _, hero in latestHeroes do
			if hero.HeroID == selectedHeroId then
				return hero
			end
		end
		return nil
	end

	local function refreshSellButton()
		local hero = selectedHero()
		if not hero then
			sellButton.Text = "Sell (pick a Hero)"
			sellButton.BackgroundColor3 = DISABLED
			return
		end
		local refund = sellRefund(hero)
		if refund == nil then
			sellButton.Text = "Cannot sell (Raid)"
			sellButton.BackgroundColor3 = DISABLED
			return
		end
		sellButton.Text = string.format("Sell for %d Gold", refund)
		sellButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end

	local function renderHeroes(heroes: { Types.Hero })
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local stillExists = false
		for index, hero in heroes do
			if hero.HeroID == selectedHeroId then
				stillExists = true
			end
			local row = Instance.new("TextButton")
			row.Name = hero.HeroID
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
			row.AutoButtonColor = true
			row.BorderSizePixel = 0
			row.Font = Enum.Font.Gotham
			row.TextSize = 14
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextColor3 = if hero.Status == "RAIDING"
				then Color3.fromRGB(160, 160, 170)
				else Color3.fromRGB(230, 230, 235)
			row.BackgroundColor3 = if hero.HeroID == selectedHeroId
				then Color3.fromRGB(55, 85, 130)
				else Color3.fromRGB(32, 36, 48)
			row.BackgroundTransparency = 0.1
			local place = if hero.Status == "ACTIVE"
				then string.format("PAD %d", hero.DisplaySlot or 0)
				elseif hero.Status == "BAGGED" then "TAS"
				else "RAID"
			local income = if hero.Status == "RAIDING" then "PAUSED" else string.format("+%d/s", hero.Production)
			row.Text = string.format(
				"  %s %s   PWR %d   %s   %s",
				hero.Tier,
				hero.HeroType,
				hero.Power,
				income,
				place
			)
			row.BackgroundTransparency = 0.1
			row.Parent = list
			addCorner(row, 4)
			row.MouseButton1Click:Connect(function()
				selectedHeroId = hero.HeroID
				renderHeroes(latestHeroes)
				refreshSellButton()
			end)
		end
		if not stillExists then
			selectedHeroId = nil
		end
		refreshSellButton()
	end

	local function num(value: number?): number
		return value or 0
	end

	local function paintUpgrade(button: TextButton, enabled: boolean, enabledColor: Color3)
		button.BackgroundColor3 = if enabled then enabledColor else DISABLED
	end

	local function showStatus(message: string, ok: boolean)
		status.Text = message
		status.TextColor3 = if ok then Color3.fromRGB(180, 220, 160) else Color3.fromRGB(230, 150, 140)
	end

	board = RecruitmentBoard.Create(gui, remotes, showStatus, setCurrencyDocked)

	local function render(snapshot: Types.PlayerSnapshot)
		latestSnapshot = snapshot
		local heroes = snapshot.Heroes or {}
		latestHeroes = heroes
		local bagCount = num(snapshot.BagCount)
		local activeCount = num(snapshot.ActiveCount)
		local raidCount = num(snapshot.RaidingCount)
		local maxSlots = DisplayConfig.MaxSlots()
		local gold = num(snapshot.Gold)
		local recruitLevel = math.max(num(snapshot.RecruitmentLevel), 1)
		local converterLevel = math.max(num(snapshot.ConverterLevel), 1)

		goldAmount.Text = fmtCompact(gold)
		stoneAmount.Text = fmtCompact(num(snapshot.MagicStone))
		blackAmount.Text = fmtCompact(num(snapshot.BlackCrystal))

		local recruitCost = snapshot.RecruitmentUpgradeCost
		if recruitCost == nil then
			recruitUpgradeButton.Text = string.format("Recruitment MAX (Lv.%d)", recruitLevel)
			paintUpgrade(recruitUpgradeButton, false, Color3.fromRGB(40, 90, 160))
		else
			recruitUpgradeButton.Text = string.format(
				"Recruitment Lv.%d → %d   %s Gold",
				recruitLevel,
				recruitLevel + 1,
				fmtInt(recruitCost)
			)
			paintUpgrade(recruitUpgradeButton, gold >= recruitCost, Color3.fromRGB(40, 90, 160))
		end

		local converterCost = snapshot.ConverterUpgradeCost
		if converterCost == nil then
			converterUpgradeButton.Text = string.format(
				"Converter MAX (Lv.%d)   %d/s",
				converterLevel,
				num(snapshot.ConverterSpeed)
			)
			paintUpgrade(converterUpgradeButton, false, Color3.fromRGB(40, 120, 110))
		else
			converterUpgradeButton.Text = string.format(
				"Converter Lv.%d → %d   %s Gold   %s→%s/s",
				converterLevel,
				converterLevel + 1,
				fmtInt(converterCost),
				fmtInt(num(snapshot.ConverterSpeed)),
				fmtInt(num(snapshot.ConverterNextSpeed))
			)
			paintUpgrade(converterUpgradeButton, gold >= converterCost, Color3.fromRGB(40, 120, 110))
		end

		local maxOwned = num(snapshot.MaxOwnedHeroes)
		if maxOwned <= 0 then
			maxOwned = DisplayConfig.MaxOwnedHeroes()
		end
		local heroCount = num(snapshot.HeroCount)

		collectionTitle.Text = string.format(
			"MY HEROES\n%d/%d   Display %d/%d   Tas %d   Raid %d",
			heroCount,
			maxOwned,
			activeCount,
			maxSlots,
			bagCount,
			raidCount
		)
		local key = heroKey(heroes)
		if key ~= lastHeroKey then
			lastHeroKey = key
			renderHeroes(heroes)
		end

		if board then
			board.ApplySnapshot(snapshot)
		end

		hasRaid = snapshot.ActiveRaid ~= nil
		if hasRaid and not wasRaiding then
			openTab = "raid"
		end
		wasRaiding = hasRaid
		local raidKey = heroKey(heroes) .. ":" .. tostring(hasRaid)
		if raidKey ~= lastRaidHeroKey then
			lastRaidHeroKey = raidKey
			renderRaidHeroes(heroes)
		end
		refreshRaidPreview()

		local notice = snapshot.LastRaidMessage
		if typeof(notice) == "string" and notice ~= "" and notice ~= lastRaidNotice then
			lastRaidNotice = notice
			showStatus(notice, snapshot.LastRaidOk ~= false)
		end

		paintTabs()

		if onSnapshot then
			onSnapshot(snapshot)
		end
	end

	local function invoke(remote: RemoteFunction, a: any?, b: any?)
		local result: any
		if b ~= nil then
			result = remote:InvokeServer(a, b)
		elseif a ~= nil then
			result = remote:InvokeServer(a)
		else
			result = remote:InvokeServer()
		end
		if typeof(result) ~= "table" then
			showStatus("No response from server.", false)
			return false
		end

		local action = result :: Types.ActionResult
		showStatus(action.message or action.error or (if action.ok then "OK" else "Failed"), action.ok)
		return action.ok
	end

	heroesTab.MouseButton1Click:Connect(function()
		setOpenTab("heroes")
	end)
	facilitiesTab.MouseButton1Click:Connect(function()
		setOpenTab("facilities")
	end)
	raidTab.MouseButton1Click:Connect(function()
		setOpenTab("raid")
	end)

	recruitUpgradeButton.MouseButton1Click:Connect(function()
		invoke(remotes.UpgradeRecruitment)
	end)
	converterUpgradeButton.MouseButton1Click:Connect(function()
		invoke(remotes.UpgradeConverter)
	end)
	startRaidButton.MouseButton1Click:Connect(function()
		local ids = pickedIds()
		if #ids < RaidConfig.MinHeroes() then
			showStatus("Pick 1 to 5 Heroes for the Raid.", false)
			return
		end
		if invoke(remotes.StartRaid, selectedMapId, ids) then
			raidPicked = {}
		end
	end)
	sellButton.MouseButton1Click:Connect(function()
		local hero = selectedHero()
		if not hero or sellRefund(hero) == nil then
			showStatus("Pick a purchased Hero to sell.", false)
			return
		end
		local result = remotes.Sell:InvokeServer(hero.HeroID)
		if typeof(result) ~= "table" then
			showStatus("No response from server.", false)
			return
		end
		local action = result :: Types.ActionResult
		showStatus(action.message or action.error or (if action.ok then "OK" else "Failed"), action.ok)
		if action.ok then
			selectedHeroId = nil
		end
	end)

	paintTabs()

	remotes.StateUpdated.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) == "table" then
			render(snapshot :: Types.PlayerSnapshot)
		end
	end)

	local initial = remotes.GetSnapshot:InvokeServer()
	if typeof(initial) == "table" then
		render(initial :: Types.PlayerSnapshot)
	end
end

return Hud
