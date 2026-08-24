--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DisplayConfig = require(Shared:WaitForChild("DisplayConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local Collection = {}

function Collection.CloneHero(hero: Types.Hero): Types.Hero
	return {
		HeroID = hero.HeroID,
		HeroType = hero.HeroType,
		Tier = hero.Tier,
		Power = hero.Power,
		Production = hero.Production,
		AcceptCost = hero.AcceptCost,
		Purchased = hero.Purchased,
		Status = hero.Status,
		DisplaySlot = hero.DisplaySlot,
		CreatedAt = hero.CreatedAt,
	}
end

function Collection.CloneHeroes(heroes: { Types.Hero }): { Types.Hero }
	local copy: { Types.Hero } = {}
	for _, hero in heroes do
		table.insert(copy, Collection.CloneHero(hero))
	end
	return copy
end

function Collection.MaxOwned(): number
	return DisplayConfig.MaxOwnedHeroes()
end

function Collection.IsRosterFull(heroes: { Types.Hero }): boolean
	return #heroes >= Collection.MaxOwned()
end

function Collection.CountByStatus(heroes: { Types.Hero }, status: Types.HeroStatus): number
	local count = 0
	for _, hero in heroes do
		if hero.Status == status then
			count += 1
		end
	end
	return count
end

function Collection.IsProducing(hero: Types.Hero): boolean
	return hero.Status == "ACTIVE" or hero.Status == "BAGGED"
end

function Collection.SumActiveProduction(heroes: { Types.Hero }): number
	local total = 0
	for _, hero in heroes do
		if Collection.IsProducing(hero) then
			total += hero.Production
		end
	end
	return total
end

function Collection.FindHero(heroes: { Types.Hero }, heroId: string): (number?, Types.Hero?)
	for index, hero in heroes do
		if hero.HeroID == heroId then
			return index, hero
		end
	end
	return nil, nil
end

function Collection.UsedDisplaySlots(heroes: { Types.Hero }): { [number]: boolean }
	local used: { [number]: boolean } = {}
	for _, hero in heroes do
		local slot = hero.DisplaySlot
		if hero.Status == "ACTIVE" and typeof(slot) == "number" then
			used[slot] = true
		end
	end
	return used
end

function Collection.FirstEmptySlot(heroes: { Types.Hero }): number?
	local used = Collection.UsedDisplaySlots(heroes)
	local maxSlots = DisplayConfig.MaxSlots()
	for slot = 1, maxSlots do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

function Collection.PlaceOnDisplay(hero: Types.Hero, heroes: { Types.Hero }): boolean
	local slot = Collection.FirstEmptySlot(heroes)
	if not slot then
		hero.Status = "BAGGED"
		hero.DisplaySlot = nil
		return false
	end
	hero.Status = "ACTIVE"
	hero.DisplaySlot = slot
	return true
end

function Collection.ReturnRaidParty(heroes: { Types.Hero }, raid: Types.Raid)
	local byId: { [string]: Types.Hero } = {}
	for _, hero in heroes do
		byId[hero.HeroID] = hero
	end

	local used = Collection.UsedDisplaySlots(heroes)
	for index, heroId in raid.HeroIDs do
		local hero = byId[heroId]
		local home = raid.HeroHomes[index]
		if hero and home and home.Status ~= "BAGGED" then
			local slot = home.DisplaySlot
			if typeof(slot) == "number" and not used[slot] then
				hero.Status = "ACTIVE"
				hero.DisplaySlot = slot
				used[slot] = true
			end
		end
	end

	for index, heroId in raid.HeroIDs do
		local hero = byId[heroId]
		local home = raid.HeroHomes[index]
		if hero and hero.Status == "RAIDING" then
			if home and home.Status == "BAGGED" then
				hero.Status = "BAGGED"
				hero.DisplaySlot = nil
			else
				Collection.PlaceOnDisplay(hero, heroes)
			end
		end
	end
end

function Collection.EnsureDisplaySlots(heroes: { Types.Hero })
	for _, hero in heroes do
		if hero.Status == "ACTIVE" and hero.DisplaySlot == nil then
			Collection.PlaceOnDisplay(hero, heroes)
		elseif hero.Status ~= "ACTIVE" then
			hero.DisplaySlot = nil
		end
	end
end

function Collection.CanSell(hero: Types.Hero): boolean
	local sell = GameConfig.Sell
	local allowSeed = sell and sell.AllowSeedHeroSell == true
	if not allowSeed and not hero.Purchased then
		return false
	end
	local blockRaid = if sell then sell.BlockIfRaiding ~= false else true
	if blockRaid and hero.Status == "RAIDING" then
		return false
	end
	return true
end

function Collection.GetSellRefund(hero: Types.Hero): number?
	if not Collection.CanSell(hero) then
		return nil
	end

	local percent = (GameConfig.Sell and GameConfig.Sell.RefundPercent) or 0.25
	return math.floor(hero.AcceptCost * percent)
end

return Collection
