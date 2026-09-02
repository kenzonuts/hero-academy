--!strict
-- Phase 8A–8E: board chrome, 10 slots, Recruit 1X / 5X / 10X, Open / Take / Clear.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Types = require(Shared:WaitForChild("Types"))
local RecruitmentBoard = {}

-- Layout tunables (scale of the board image).
local BOARD_WIDTH = 0.82
local BOARD_HEIGHT = 0.82
local CONTENT_POS = UDim2.new(0.5, 0, 0.56, 0)
local CONTENT_SIZE = UDim2.new(0.9, 0, 0.7, 0)
local SLOT_COLUMNS = 5
local SLOT_COUNT = 10
local SLOT_CELL = UDim2.new(0.176, 0, 0.47, 0)
local SLOT_PAD = UDim2.fromOffset(9, 10)
local CLOSE_SIZE = 40
local CLOSE_POS = UDim2.new(1, 8, 0, 38)
local TITLE_POS = UDim2.new(0.5, 0, 0.02, 0)
local TITLE_SIZE = UDim2.new(0.48, 0, 0.12, 0)
local FLIP_HALF = 0.12
local GLOW_SIZE = 1.35
local GLOW_SPIN_SECONDS = 10

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

export type BoardHandle = {
	SetOpen: (open: boolean) -> (),
	IsOpen: () -> boolean,
	Dismiss: () -> (),
	ApplySnapshot: (snapshot: Types.PlayerSnapshot) -> (),
	Host: Frame,
}

local function academyAttribute(): string
	local academy = GameConfig.Academy
	if academy and typeof(academy.AttributeName) == "string" and academy.AttributeName ~= "" then
		return academy.AttributeName
	end
	return "AcademyName"
end

local function wireHoverSwap(button: ImageButton, offImage: string, onImage: string)
	button.Image = offImage
	button.AutoButtonColor = false
	local hovering = false
	button.MouseEnter:Connect(function()
		hovering = true
		button.Image = onImage
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		button.Image = offImage
	end)
	button.MouseButton1Down:Connect(function()
		button.Image = onImage
	end)
	button.MouseButton1Up:Connect(function()
		button.Image = if hovering then onImage else offImage
	end)
end

local function makeBottomButton(parent: Instance, name: string, offImage: string, onImage: string, order: number): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = name
	button.LayoutOrder = order
	button.Size = UDim2.new(0.27, 0, 0.92, 0)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = offImage
	button.ScaleType = Enum.ScaleType.Fit
	button.ZIndex = 11
	button.Parent = parent
	wireHoverSwap(button, offImage, onImage)
	return button
end

local function makeRecruitButton(parent: Instance, name: string, title: string, cost: number, order: number, onImage: string): ImageButton
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0.24, 0)
	row.BackgroundTransparency = 1
	row.ZIndex = 11
	row.Parent = parent

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromScale(0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0.36, 0)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.ZIndex = 12
	titleLabel.Parent = row
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 1.5
	titleStroke.Color = Color3.new(0, 0, 0)
	titleStroke.Parent = titleLabel

	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.Position = UDim2.new(0, 0, 0.38, 0)
	button.Size = UDim2.new(1, 0, 0.62, 0)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = onImage
	button.ScaleType = Enum.ScaleType.Fit
	button.ZIndex = 11
	button.Parent = row

	local costRow = Instance.new("Frame")
	costRow.Name = "Cost"
	costRow.BackgroundTransparency = 1
	costRow.Position = UDim2.new(0.12, 0, 0.16, 0)
	costRow.Size = UDim2.new(0.76, 0, 0.68, 0)
	costRow.ZIndex = 12
	costRow.Parent = button
	local costPad = Instance.new("UIPadding")
	costPad.PaddingLeft = UDim.new(0.04, 0)
	costPad.PaddingRight = UDim.new(0.04, 0)
	costPad.PaddingTop = UDim.new(0.08, 0)
	costPad.PaddingBottom = UDim.new(0.08, 0)
	costPad.Parent = costRow

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = costRow

	local coin = Instance.new("ImageLabel")
	coin.Name = "Coin"
	coin.LayoutOrder = 1
	coin.BackgroundTransparency = 1
	coin.Size = UDim2.fromScale(0.85, 0.85)
	coin.SizeConstraint = Enum.SizeConstraint.RelativeYY
	coin.Image = DisplayConfig.GoldImage()
	coin.ScaleType = Enum.ScaleType.Fit
	coin.ZIndex = 12
	coin.Parent = costRow

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.LayoutOrder = 2
	amount.BackgroundTransparency = 1
	amount.Size = UDim2.new(0.62, 0, 0.9, 0)
	amount.Font = Enum.Font.GothamBold
	amount.Text = fmtCompact(cost)
	amount.TextColor3 = Color3.new(1, 1, 1)
	amount.TextScaled = true
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.ZIndex = 12
	amount.Parent = costRow
	local amountSize = Instance.new("UITextSizeConstraint")
	amountSize.MinTextSize = 10
	amountSize.MaxTextSize = 22
	amountSize.Parent = amount

	return button
end

function RecruitmentBoard.Create(
	parent: Instance,
	remotes: {
		Recruit: RemoteFunction,
		Accept: RemoteFunction,
		Reject: RemoteFunction,
	},
	onMessage: ((string, boolean) -> ())?,
	onOpen: ((boolean) -> ())?
): BoardHandle
	local player = Players.LocalPlayer

	local overlay = Instance.new("Frame")
	overlay.Name = "RecruitmentBoard"
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 8
	overlay.Visible = false
	overlay.Parent = parent

	local dimmer = Instance.new("TextButton")
	dimmer.Name = "Dimmer"
	dimmer.Text = ""
	dimmer.AutoButtonColor = false
	dimmer.BackgroundColor3 = Color3.new(0, 0, 0)
	dimmer.BackgroundTransparency = 0.45
	dimmer.BorderSizePixel = 0
	dimmer.Size = UDim2.fromScale(1, 1)
	dimmer.ZIndex = 8
	dimmer.Modal = false
	dimmer.Parent = overlay

	local host = Instance.new("Frame")
	host.Name = "BoardHost"
	host.AnchorPoint = Vector2.new(0.5, 0)
	host.Position = UDim2.new(0.5, 0, 0.08, 0)
	host.Size = UDim2.new(BOARD_WIDTH, 0, BOARD_HEIGHT, 0)
	host.BackgroundTransparency = 1
	host.Active = true
	host.ZIndex = 9
	host.Parent = overlay

	local board = Instance.new("ImageLabel")
	board.Name = "Board"
	board.BackgroundTransparency = 1
	board.BorderSizePixel = 0
	board.Position = UDim2.new(0, 0, 0.08, 0)
	board.Size = UDim2.new(1, 0, 0.86, 0)
	board.Image = DisplayConfig.RecruitmentBoardImage()
	board.ImageTransparency = 0
	board.ScaleType = Enum.ScaleType.Stretch
	board.Active = true
	board.ZIndex = 9
	board.Parent = host

	local title = Instance.new("ImageLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = TITLE_POS
	title.Size = TITLE_SIZE
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.Image = DisplayConfig.RecruitmentBoardTitleImage()
	title.ScaleType = Enum.ScaleType.Fit
	title.ZIndex = 10
	title.Parent = host

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.Position = CONTENT_POS
	content.Size = CONTENT_SIZE
	content.Active = true
	content.ZIndex = 10
	content.Parent = host

	local left = Instance.new("Frame")
	left.Name = "Main"
	left.BackgroundTransparency = 1
	left.Position = UDim2.fromScale(0, 0)
	left.Size = UDim2.new(0.74, 0, 1, 0)
	left.ZIndex = 10
	left.Parent = content

	local grid = Instance.new("Frame")
	grid.Name = "SlotGrid"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0, 0)
	grid.Size = UDim2.new(1, 0, 0.81, 0)
	grid.ZIndex = 10
	grid.Parent = left

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.FillDirectionMaxCells = SLOT_COLUMNS
	gridLayout.CellSize = SLOT_CELL
	gridLayout.CellPadding = SLOT_PAD
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	local emptyImage = DisplayConfig.RecruitmentSlotEmptyImage()
	local closedImage = DisplayConfig.RecruitmentSlotClosedImage()
	local glowImage = DisplayConfig.RecruitmentCardGlowImage()
	local slotButtons: { ImageButton } = {}
	local slotFaces: { TextLabel } = {}
	local slotGlows: { ImageLabel } = {}
	for index = 1, SLOT_COUNT do
		local cell = Instance.new("Frame")
		cell.Name = "Slot" .. tostring(index)
		cell.LayoutOrder = index
		cell.BackgroundTransparency = 1
		cell.BorderSizePixel = 0
		cell.ClipsDescendants = false
		cell.ZIndex = 10
		cell.Parent = grid

		local glow = Instance.new("ImageLabel")
		glow.Name = "Glow"
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromScale(0.5, 0.5)
		glow.Size = UDim2.fromScale(GLOW_SIZE, GLOW_SIZE)
		glow.BackgroundTransparency = 1
		glow.BorderSizePixel = 0
		glow.Image = glowImage
		glow.ScaleType = Enum.ScaleType.Fit
		glow.Visible = false
		glow.ZIndex = 9
		glow.Parent = cell
		local spin = TweenService:Create(
			glow,
			TweenInfo.new(GLOW_SPIN_SECONDS, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{ Rotation = 360 }
		)
		spin:Play()
		table.insert(slotGlows, glow)

		local slot = Instance.new("ImageButton")
		slot.Name = "Card"
		slot.AnchorPoint = Vector2.new(0.5, 0.5)
		slot.Position = UDim2.fromScale(0.5, 0.5)
		slot.Size = UDim2.fromScale(1, 1)
		slot.BackgroundTransparency = 1
		slot.BorderSizePixel = 0
		slot.AutoButtonColor = false
		slot.Image = emptyImage
		slot.ScaleType = Enum.ScaleType.Fit
		slot.ZIndex = 10
		slot.Parent = cell
		table.insert(slotButtons, slot)

		local face = Instance.new("TextLabel")
		face.Name = "Face"
		face.BackgroundTransparency = 1
		face.Size = UDim2.fromScale(1, 1)
		face.Font = Enum.Font.GothamBold
		face.Text = ""
		face.TextColor3 = Color3.new(1, 1, 1)
		face.TextScaled = true
		face.TextWrapped = true
		face.TextYAlignment = Enum.TextYAlignment.Bottom
		face.Visible = false
		face.ZIndex = 11
		face.Parent = slot
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = face
		local facePad = Instance.new("UIPadding")
		facePad.PaddingTop = UDim.new(0.08, 0)
		facePad.PaddingBottom = UDim.new(0.08, 0)
		facePad.PaddingLeft = UDim.new(0.06, 0)
		facePad.PaddingRight = UDim.new(0.06, 0)
		facePad.Parent = face
		table.insert(slotFaces, face)
	end

	local bottom = Instance.new("Frame")
	bottom.Name = "Actions"
	bottom.BackgroundTransparency = 1
	bottom.Position = UDim2.new(0, 0, 0.82, 0)
	bottom.Size = UDim2.new(1, 0, 0.15, 0)
	bottom.ZIndex = 11
	bottom.Parent = left

	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bottomLayout.Padding = UDim.new(0.025, 0)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Parent = bottom

	local takeAll = makeBottomButton(
		bottom,
		"TakeAll",
		DisplayConfig.RecruitmentTakeAllOffImage(),
		DisplayConfig.RecruitmentTakeAllImage(),
		1
	)
	local clearAll = makeBottomButton(
		bottom,
		"ClearAll",
		DisplayConfig.RecruitmentClearAllOffImage(),
		DisplayConfig.RecruitmentClearAllImage(),
		2
	)
	local openAll = makeBottomButton(
		bottom,
		"OpenAll",
		DisplayConfig.RecruitmentOpenAllOffImage(),
		DisplayConfig.RecruitmentOpenAllImage(),
		3
	)
	takeAll.Visible = false
	clearAll.Visible = false
	openAll.Visible = false

	local rail = Instance.new("Frame")
	rail.Name = "RecruitRail"
	rail.BackgroundTransparency = 1
	rail.Position = UDim2.new(0.76, 0, 0.0, 0)
	rail.Size = UDim2.new(0.24, 0, 0.82, 0)
	rail.ZIndex = 11
	rail.Parent = content

	local railLayout = Instance.new("UIListLayout")
	railLayout.FillDirection = Enum.FillDirection.Vertical
	railLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	railLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	railLayout.Padding = UDim.new(0.12, 0)
	railLayout.SortOrder = Enum.SortOrder.LayoutOrder
	railLayout.Parent = rail

	local recruitOnImage = DisplayConfig.RecruitmentRecruitOnImage()
	local recruitOffImage = DisplayConfig.RecruitmentRecruitOffImage()
	local fee = GameConfig.Recruitment.RecruitFeeGold
	local recruit1X = makeRecruitButton(rail, "Recruit1X", "RECRUIT 1X", fee, 1, recruitOnImage)
	local recruit5X = makeRecruitButton(rail, "Recruit5X", "RECRUIT 5X", fee * 5, 2, recruitOnImage)
	local recruit10X = makeRecruitButton(rail, "Recruit10X", "RECRUIT 10X", fee * 10, 3, recruitOnImage)

	local close = Instance.new("ImageButton")
	close.Name = "Close"
	close.BackgroundTransparency = 1
	close.AutoButtonColor = true
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = CLOSE_POS
	close.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	close.Image = DisplayConfig.RecruitmentBoardCloseImage()
	close.ScaleType = Enum.ScaleType.Fit
	close.ZIndex = 11
	close.Parent = host

	local open = false
	local dismissed = false
	local frozen = false
	local revealedIds: { [string]: boolean } = {}
	local flippingIds: { [string]: boolean } = {}
	local latestSnapshot: Types.PlayerSnapshot? = nil
	local savedWalk = 16
	local savedJump = 50
	local savedJumpHeight = 7.2
	local savedAutoRotate = true
	local controls: any = nil

	local function loadControls()
		if controls ~= nil then
			return controls
		end
		local scripts = player:FindFirstChild("PlayerScripts")
		if scripts == nil then
			return nil
		end
		local module = scripts:FindFirstChild("PlayerModule")
		if module == nil then
			return nil
		end
		local ok, playerModule = pcall(require, module)
		if not ok or playerModule == nil then
			return nil
		end
		local okControls, result = pcall(function()
			return (playerModule :: any):GetControls()
		end)
		if okControls then
			controls = result
		end
		return controls
	end

	local function freezeMovement()
		if frozen then
			return
		end
		frozen = true
		dimmer.Modal = true
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then
			savedWalk = humanoid.WalkSpeed
			savedJump = humanoid.JumpPower
			savedJumpHeight = humanoid.JumpHeight
			savedAutoRotate = humanoid.AutoRotate
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
			humanoid.AutoRotate = false
		end
		local move = loadControls()
		if move and typeof(move.Disable) == "function" then
			move:Disable()
		end
	end

	local function restoreMovement()
		if not frozen then
			return
		end
		frozen = false
		dimmer.Modal = false
		local move = loadControls()
		if move and typeof(move.Enable) == "function" then
			move:Enable()
		end
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then
			humanoid.WalkSpeed = savedWalk
			humanoid.JumpPower = savedJump
			humanoid.JumpHeight = savedJumpHeight
			humanoid.AutoRotate = savedAutoRotate
		end
	end

	local function tell(message: string, ok: boolean)
		if onMessage then
			onMessage(message, ok)
		end
	end

	local function invoke(remote: RemoteFunction, mode: any?): boolean
		local result: any
		if mode ~= nil then
			result = remote:InvokeServer(mode)
		else
			result = remote:InvokeServer()
		end
		if typeof(result) ~= "table" then
			tell("No response from server.", false)
			return false
		end
		local action = result :: Types.ActionResult
		tell(action.message or action.error or (if action.ok then "OK" else "Failed"), action.ok)
		return action.ok
	end

	local function pendingCards(): { Types.Candidate }
		if latestSnapshot == nil then
			return {}
		end
		local list = latestSnapshot.PendingCandidates
		if typeof(list) == "table" and #list > 0 then
			return list
		end
		if latestSnapshot.PendingCandidate then
			return { latestSnapshot.PendingCandidate }
		end
		return {}
	end

	local function setPullEnabled(button: ImageButton, enabled: boolean)
		button.Image = if enabled then recruitOnImage else recruitOffImage
		button.AutoButtonColor = false
	end

	local function setPullCost(button: ImageButton, cost: number)
		local costRow = button:FindFirstChild("Cost")
		if costRow == nil then
			return
		end
		local amount = costRow:FindFirstChild("Amount")
		if amount and amount:IsA("TextLabel") then
			amount.Text = fmtCompact(cost)
		end
	end

	local function setGlow(index: number, on: boolean)
		local glow = slotGlows[index]
		if glow then
			glow.Visible = on
		end
	end

	local function showEmpty(index: number)
		local slot = slotButtons[index]
		local face = slotFaces[index]
		slot.Size = UDim2.fromScale(1, 1)
		slot.Image = emptyImage
		slot.AutoButtonColor = false
		slot.Active = false
		face.Visible = false
		face.Text = ""
		setGlow(index, false)
	end

	local function showClosed(index: number)
		local slot = slotButtons[index]
		local face = slotFaces[index]
		slot.Size = UDim2.fromScale(1, 1)
		slot.Image = closedImage
		slot.AutoButtonColor = true
		slot.Active = true
		face.Visible = false
		face.Text = ""
		setGlow(index, false)
	end

	local function showRevealed(index: number, card: Types.Candidate)
		local slot = slotButtons[index]
		local face = slotFaces[index]
		local art = DisplayConfig.RecruitmentCardImage(card.Tier, card.HeroType)
		slot.Image = art or emptyImage
		slot.AutoButtonColor = true
		slot.Active = true
		face.Visible = true
		setGlow(index, true)
		if art then
			face.Text = string.format("%d PWR\n%d/s", card.Power, card.Production)
		else
			face.Text = string.format(
				"%s\n%s\nPWR %d\n%d/s",
				card.Tier,
				card.HeroType,
				card.Power,
				card.Production
			)
		end
	end

	local function paintActionButtons()
		local pending = pendingCards()
		local hasCards = #pending > 0
		local hasClosed = false
		for _, card in pending do
			if not revealedIds[card.CandidateID] then
				hasClosed = true
				break
			end
		end
		takeAll.Visible = hasCards
		clearAll.Visible = hasCards
		openAll.Visible = hasClosed
	end

	local function flipOpen(index: number, card: Types.Candidate)
		local id = card.CandidateID
		if revealedIds[id] or flippingIds[id] then
			return
		end
		flippingIds[id] = true
		local slot = slotButtons[index]
		slot.AutoButtonColor = false
		slot.Active = false

		local shrink = TweenService:Create(slot, TweenInfo.new(FLIP_HALF, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromScale(0, 1),
		})
		shrink:Play()
		shrink.Completed:Wait()

		local pending = pendingCards()
		if pending[index] == nil or pending[index].CandidateID ~= id then
			flippingIds[id] = nil
			if pending[index] then
				if revealedIds[pending[index].CandidateID] then
					showRevealed(index, pending[index])
				else
					showClosed(index)
				end
			else
				showEmpty(index)
			end
			paintActionButtons()
			return
		end

		revealedIds[id] = true
		showRevealed(index, card)
		slot.Size = UDim2.fromScale(0, 1)

		local grow = TweenService:Create(slot, TweenInfo.new(FLIP_HALF, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1, 1),
		})
		grow:Play()
		grow.Completed:Wait()
		slot.Size = UDim2.fromScale(1, 1)
		flippingIds[id] = nil
		paintActionButtons()
	end

	local function paintSlots()
		local pending = pendingCards()
		local live: { [string]: boolean } = {}
		for index = 1, SLOT_COUNT do
			local card = pending[index]
			if card then
				live[card.CandidateID] = true
				if flippingIds[card.CandidateID] then
					continue
				end
				if revealedIds[card.CandidateID] then
					showRevealed(index, card)
				else
					showClosed(index)
				end
			else
				showEmpty(index)
			end
		end
		for id, _ in revealedIds do
			if not live[id] then
				revealedIds[id] = nil
			end
		end
		for id, _ in flippingIds do
			if not live[id] then
				flippingIds[id] = nil
			end
		end

		paintActionButtons()

		local gold = if latestSnapshot then latestSnapshot.Gold else 0
		local heroes = if latestSnapshot then latestSnapshot.HeroCount else 0
		local maxOwned = if latestSnapshot then latestSnapshot.MaxOwnedHeroes else 40
		local remaining = SLOT_COUNT - #pending
		local rosterLeft = maxOwned - heroes - #pending
		local feeEach = if latestSnapshot and typeof(latestSnapshot.RecruitFee) == "number"
			then latestSnapshot.RecruitFee
			else GameConfig.Recruitment.RecruitFeeGold
		local tickets = if latestSnapshot then latestSnapshot.RecruitTickets else 0
		local function canPull(count: number): boolean
			if remaining < count or rosterLeft < count then
				return false
			end
			if count == 1 and typeof(tickets) == "number" and tickets > 0 then
				return true
			end
			return gold >= feeEach * count
		end
		setPullCost(recruit1X, feeEach)
		setPullCost(recruit5X, feeEach * 5)
		setPullCost(recruit10X, feeEach * 10)
		setPullEnabled(recruit1X, canPull(1))
		setPullEnabled(recruit5X, canPull(5))
		setPullEnabled(recruit10X, canPull(10))
	end

	local function applySnapshot(snapshot: Types.PlayerSnapshot)
		latestSnapshot = snapshot
		paintSlots()
	end

	local handle: BoardHandle
	handle = {
		SetOpen = function(visible: boolean)
			if open == visible then
				return
			end
			open = visible
			overlay.Visible = visible
			if visible then
				freezeMovement()
			else
				restoreMovement()
			end
			if onOpen then
				onOpen(visible)
			end
		end,
		IsOpen = function()
			return open
		end,
		Dismiss = function()
			dismissed = true
			handle.SetOpen(false)
		end,
		ApplySnapshot = applySnapshot,
		Host = content,
	}

	dimmer.MouseButton1Click:Connect(function()
		handle.Dismiss()
	end)
	close.MouseButton1Click:Connect(function()
		handle.Dismiss()
	end)

	for index = 1, SLOT_COUNT do
		slotButtons[index].MouseButton1Click:Connect(function()
			local pending = pendingCards()
			local card = pending[index]
			if card == nil then
				return
			end
			if flippingIds[card.CandidateID] then
				return
			end
			if revealedIds[card.CandidateID] then
				invoke(remotes.Accept, card.CandidateID)
				return
			end
			task.spawn(function()
				flipOpen(index, card)
			end)
		end)
	end

	local function tryRecruit(count: number)
		local pending = pendingCards()
		local remaining = SLOT_COUNT - #pending
		if remaining < count then
			tell(string.format("Need %d empty slots. Take or clear cards first.", count), false)
			return
		end
		if count == 1 then
			local tickets = if latestSnapshot then latestSnapshot.RecruitTickets else 0
			if typeof(tickets) == "number" and tickets > 0 then
				invoke(remotes.Recruit, "TICKET")
				return
			end
		end
		invoke(remotes.Recruit, count)
	end

	recruit1X.MouseButton1Click:Connect(function()
		tryRecruit(1)
	end)
	recruit5X.MouseButton1Click:Connect(function()
		tryRecruit(5)
	end)
	recruit10X.MouseButton1Click:Connect(function()
		tryRecruit(10)
	end)
	openAll.MouseButton1Click:Connect(function()
		local pending = pendingCards()
		if #pending == 0 then
			tell("No cards to open.", false)
			return
		end
		local opened = 0
		local delay = 0
		for index, card in pending do
			if not revealedIds[card.CandidateID] and not flippingIds[card.CandidateID] then
				opened += 1
				local slotIndex = index
				local target = card
				local waitFor = delay
				task.delay(waitFor, function()
					flipOpen(slotIndex, target)
				end)
				delay += 0.08
			end
		end
		if opened == 0 then
			tell("Cards already open.", true)
			return
		end
		tell("Opening cards.", true)
	end)
	takeAll.MouseButton1Click:Connect(function()
		invoke(remotes.Accept)
	end)
	clearAll.MouseButton1Click:Connect(function()
		invoke(remotes.Reject)
	end)

	player.CharacterRemoving:Connect(function()
		dismissed = false
		handle.SetOpen(false)
	end)

	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	local pad = Vector3.new(1, 2, 1)

	local function isStandingOnSummon(): boolean
		local character = player.Character
		if character == nil then
			return false
		end
		overlap.FilterDescendantsInstances = { character }

		local attrName = academyAttribute()
		local academyName = player:GetAttribute(attrName)
		local parts = if typeof(academyName) == "string"
			then DisplayConfig.CollectSummonParts(academyName)
			else {}
		if #parts == 0 then
			for _, name in DisplayConfig.AcademyNames() do
				for _, part in DisplayConfig.CollectSummonParts(name) do
					table.insert(parts, part)
				end
			end
		end

		for _, part in parts do
			if part.Parent then
				part.CanQuery = true
				local hits = Workspace:GetPartBoundsInBox(part.CFrame, part.Size + pad, overlap)
				if #hits > 0 then
					return true
				end
			end
		end
		return false
	end

	task.spawn(function()
		while overlay.Parent do
			local onPlate = isStandingOnSummon()
			if onPlate then
				if not open and not dismissed then
					handle.SetOpen(true)
				end
			else
				dismissed = false
			end
			task.wait(0.1)
		end
		restoreMovement()
	end)

	return handle
end

return RecruitmentBoard
