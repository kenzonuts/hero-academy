--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local function ensureFolder(): Folder
	if RunService:IsClient() then
		return ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end

	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "Remotes"

	local stateUpdated = Instance.new("RemoteEvent")
	stateUpdated.Name = "StateUpdated"
	stateUpdated.Parent = folder

	for _, name in { "Recruit", "Accept", "Reject", "GetSnapshot" } do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end

	folder.Parent = ReplicatedStorage
	return folder
end

export type ServerRemotes = {
	StateUpdated: RemoteEvent,
	Recruit: RemoteFunction,
	Accept: RemoteFunction,
	Reject: RemoteFunction,
	GetSnapshot: RemoteFunction,
}

function Remotes.Get(): ServerRemotes
	local folder = ensureFolder()
	return {
		StateUpdated = folder:WaitForChild("StateUpdated") :: RemoteEvent,
		Recruit = folder:WaitForChild("Recruit") :: RemoteFunction,
		Accept = folder:WaitForChild("Accept") :: RemoteFunction,
		Reject = folder:WaitForChild("Reject") :: RemoteFunction,
		GetSnapshot = folder:WaitForChild("GetSnapshot") :: RemoteFunction,
	}
end

return Remotes
