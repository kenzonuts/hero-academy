--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

local Collection = require(script.Parent:WaitForChild("Collection"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Sell = {}

local function fail(errorCode: string, message: string): Types.ActionResult
	return {
		ok = false,
		error = errorCode,
		message = message,
	}
end

local function ok(message: string): Types.ActionResult
	return {
		ok = true,
		error = nil,
		message = message,
	}
end

function Sell.Hero(player: Player, heroId: any): Types.ActionResult
	if typeof(heroId) ~= "string" or heroId == "" then
		return fail("BAD_ID", "Pick a Hero first.")
	end

	local state = PlayerData.Get(player)
	if not state then
		return fail("NO_SESSION", "Player data not found.")
	end

	local index, hero = Collection.FindHero(state.Heroes, heroId)
	if not index or not hero then
		return fail("NO_HERO", "Hero not found.")
	end

	if not Collection.CanSell(hero) then
		if not hero.Purchased then
			return fail("SEED_HERO", "Starter Heroes cannot be sold.")
		end
		if hero.Status == "RAIDING" then
			return fail("RAIDING", "Cannot sell a Hero that is raiding.")
		end
		return fail("CANNOT_SELL", "This Hero cannot be sold.")
	end

	local refund = Collection.GetSellRefund(hero)
	if refund == nil then
		return fail("CANNOT_SELL", "This Hero cannot be sold.")
	end

	table.remove(state.Heroes, index)
	if refund > 0 then
		Economy.AddGold(player, refund)
	end

	return ok(string.format("Sold %s %s for %d Gold.", hero.Tier, hero.HeroType, refund))
end

return Sell
