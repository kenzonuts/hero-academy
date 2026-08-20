--!strict

local Players = game:GetService("Players")

local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

local Hud = {}

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
	return button
end

function Hud.Start(remotes: {
	StateUpdated: RemoteEvent,
	Recruit: RemoteFunction,
	Accept: RemoteFunction,
	Reject: RemoteFunction,
	GetSnapshot: RemoteFunction,
})
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "HeroRecruitmentHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.Position = UDim2.fromOffset(16, 80)
	frame.Size = UDim2.fromOffset(420, 360)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = makeLabel(frame, "Title", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 24))
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Text = "Hero Recruitment — Phase 2"

	local stats = makeLabel(frame, "Stats", UDim2.fromOffset(16, 44), UDim2.new(1, -32, 0, 90))
	local candidate = makeLabel(frame, "Candidate", UDim2.fromOffset(16, 140), UDim2.new(1, -32, 0, 120))
	local status = makeLabel(frame, "Status", UDim2.fromOffset(16, 318), UDim2.new(1, -32, 0, 28))
	status.TextColor3 = Color3.fromRGB(180, 220, 160)

	local recruitButton = makeButton(frame, "Recruit", "Recruit", UDim2.fromOffset(16, 270))
	local acceptButton = makeButton(frame, "Accept", "Accept", UDim2.fromOffset(148, 270))
	acceptButton.BackgroundColor3 = Color3.fromRGB(40, 130, 80)
	local rejectButton = makeButton(frame, "Reject", "Reject", UDim2.fromOffset(280, 270))
	rejectButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)

	local function render(snapshot: Types.PlayerSnapshot)
		stats.Text = string.format(
			"Gold: %d\nMagic Stone: %d / %d\nProduction: %.0f/s   Converter: %d/s\nHeroes: %d   Recruit fee: %d",
			snapshot.Gold,
			snapshot.MagicStone,
			snapshot.MagicStoneCapacity,
			snapshot.ProductionPerSecond,
			snapshot.ConverterSpeed,
			snapshot.HeroCount,
			snapshot.RecruitFee
		)

		local pending = snapshot.PendingCandidate
		if pending then
			local canAccept = snapshot.Gold >= pending.AcceptCost
			candidate.Text = string.format(
				"PENDING CANDIDATE\n%s %s\nPower %d   Production %d/s\nAccept %d Gold%s",
				pending.Tier,
				pending.HeroType,
				pending.Power,
				pending.Production,
				pending.AcceptCost,
				if canAccept then "" else "\nNot enough Gold — candidate saved"
			)
			recruitButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		else
			candidate.Text = "No candidate.\nRecruit is unlocked."
			recruitButton.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
		end
	end

	local function invoke(remote: RemoteFunction)
		local result = remote:InvokeServer()
		if typeof(result) ~= "table" then
			status.Text = "No response from server."
			return
		end

		local action = result :: Types.ActionResult
		status.Text = action.message or action.error or (if action.ok then "OK" else "Failed")
		status.TextColor3 = if action.ok then Color3.fromRGB(180, 220, 160) else Color3.fromRGB(230, 150, 140)
	end

	recruitButton.MouseButton1Click:Connect(function()
		invoke(remotes.Recruit)
	end)
	acceptButton.MouseButton1Click:Connect(function()
		invoke(remotes.Accept)
	end)
	rejectButton.MouseButton1Click:Connect(function()
		invoke(remotes.Reject)
	end)

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
