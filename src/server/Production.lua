--!strict

local Economy = require(script.Parent:WaitForChild("Economy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Production = {}

function Production.GetTotal(player: Player): number
	local state = PlayerData.Get(player)
	if not state then
		return 0
	end

	local total = 0
	for _, hero in state.Heroes do
		if hero.Status == "ACTIVE" then
			total += hero.Production
		end
	end

	return total
end

function Production.Tick(player: Player, dt: number)
	if dt <= 0 then
		return
	end

	Economy.AddMagicStone(player, Production.GetTotal(player) * dt)
end

return Production
