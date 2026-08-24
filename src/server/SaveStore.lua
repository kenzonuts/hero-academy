--!strict

local DataStoreService = game:GetService("DataStoreService")

local STORE_NAME = "HeroRecruitment_v1"
local KEY_PREFIX = "u_"
local MAX_RETRIES = 3

local SaveStore = {}

local store: DataStore? = nil

local function getStore(): DataStore?
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and result then
		store = result
		return store
	end
	warn("[Save] DataStore unavailable: ", result)
	return nil
end

local function keyFor(userId: number): string
	return KEY_PREFIX .. tostring(userId)
end

function SaveStore.Load(userId: number): any?
	local ds = getStore()
	if not ds then
		return nil
	end

	local lastError: any = nil
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			return ds:GetAsync(keyFor(userId))
		end)
		if ok then
			return result
		end
		lastError = result
		task.wait(attempt)
	end

	warn("[Save] Load failed for ", userId, lastError)
	return nil
end

function SaveStore.Save(userId: number, payload: any): boolean
	local ds = getStore()
	if not ds then
		return false
	end

	local lastError: any = nil
	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			ds:SetAsync(keyFor(userId), payload)
		end)
		if ok then
			return true
		end
		lastError = err
		task.wait(attempt)
	end

	warn("[Save] Save failed for ", userId, lastError)
	return false
end

return SaveStore
