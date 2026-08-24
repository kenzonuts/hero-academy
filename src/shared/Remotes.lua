--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local REMOTE_FUNCTIONS = {
	"Recruit",
	"Accept",
	"Reject",
	"GetSnapshot",
	"Sell",
	"UpgradeRecruitment",
	"UpgradeConverter",
	"StartRaid",
}

local function ensureInstance(folder: Folder, name: string, className: string): Instance
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = folder
	return created
end

local function ensureFolder(): Folder
	if RunService:IsClient() then
		local folder = ReplicatedStorage:WaitForChild("Remotes", 30)
		if folder == nil or not folder:IsA("Folder") then
			error("[HeroRecruitment] Remotes missing. Server script did not start. Stop Play, Plugins → Rojo → Connect, then Play.")
		end
		return folder
	end

	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not (folder and folder:IsA("Folder")) then
		local created = Instance.new("Folder")
		created.Name = "Remotes"
		created.Parent = ReplicatedStorage
		folder = created
	end

	ensureInstance(folder, "StateUpdated", "RemoteEvent")
	for _, name in REMOTE_FUNCTIONS do
		ensureInstance(folder, name, "RemoteFunction")
	end

	return folder
end

export type ServerRemotes = {
	StateUpdated: RemoteEvent,
	Recruit: RemoteFunction,
	Accept: RemoteFunction,
	Reject: RemoteFunction,
	GetSnapshot: RemoteFunction,
	Sell: RemoteFunction,
	UpgradeRecruitment: RemoteFunction,
	UpgradeConverter: RemoteFunction,
	StartRaid: RemoteFunction,
}

function Remotes.Get(): ServerRemotes
	local folder = ensureFolder()
	return {
		StateUpdated = folder:WaitForChild("StateUpdated") :: RemoteEvent,
		Recruit = folder:WaitForChild("Recruit") :: RemoteFunction,
		Accept = folder:WaitForChild("Accept") :: RemoteFunction,
		Reject = folder:WaitForChild("Reject") :: RemoteFunction,
		GetSnapshot = folder:WaitForChild("GetSnapshot") :: RemoteFunction,
		Sell = folder:WaitForChild("Sell") :: RemoteFunction,
		UpgradeRecruitment = folder:WaitForChild("UpgradeRecruitment") :: RemoteFunction,
		UpgradeConverter = folder:WaitForChild("UpgradeConverter") :: RemoteFunction,
		StartRaid = folder:WaitForChild("StartRaid") :: RemoteFunction,
	}
end

return Remotes
