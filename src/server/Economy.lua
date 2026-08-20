--!strict

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Economy = {}

function Economy.GetGold(player: Player): number
	local state = PlayerData.Get(player)
	if not state then
		return 0
	end
	return state.Gold
end

function Economy.GetMagicStone(player: Player): number
	local state = PlayerData.Get(player)
	if not state then
		return 0
	end
	return state.MagicStone
end

function Economy.AddGold(player: Player, amount: number)
	if amount <= 0 then
		return
	end

	local state = PlayerData.Get(player)
	if not state then
		return
	end

	state.Gold += amount
end

function Economy.TrySpendGold(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end

	local state = PlayerData.Get(player)
	if not state or state.Gold < amount then
		return false
	end

	state.Gold -= amount
	return true
end

function Economy.AddMagicStone(player: Player, amount: number): number
	if amount <= 0 then
		return 0
	end

	local state = PlayerData.Get(player)
	if not state then
		return 0
	end

	local space = state.MagicStoneCapacity - state.MagicStone
	if space <= 0 then
		return 0
	end

	local added = math.min(amount, space)
	state.MagicStone += added
	return added
end

function Economy.RemoveMagicStone(player: Player, amount: number): number
	if amount <= 0 then
		return 0
	end

	local state = PlayerData.Get(player)
	if not state then
		return 0
	end

	local removed = math.min(amount, state.MagicStone)
	state.MagicStone -= removed
	return removed
end

return Economy
