--!strict
--[[
	Hero Recruitment — Studio-readable design freeze.

	Full document: GAME_LOGIC.md (project root).
	Numbers: GameConfig.lua.

	Studio Assistant should follow these rules when writing scripts.
]]

local GameRules = {
	Version = "1.0",
	Loop = "RECRUIT → JUDGE → SAVE/ACCEPT → COLLECT → PRODUCE → CONVERT → INVEST → RAID → REWARD",

	Currencies = {
		Gold = "Primary currency. Recruit, Accept, upgrades.",
		MagicStone = "Hero production only. Never a second main currency.",
	},

	HardRules = {
		"Heroes produce Magic Stone, never Gold.",
		"Converter ratio is always 1 Magic Stone = 1 Gold. Upgrade speed only.",
		"Recruit Fee and Accept Fee are two separate transactions.",
		"Recruit Fee is never refunded, even on Reject.",
		"Accept Fee is paid only when claiming the candidate as a Hero.",
		"Maximum 1 Pending Candidate. Recruit stays locked until Accept or Reject.",
		"Pending candidates do not expire, mutate, or reroll.",
		"Candidate stats are locked at generation.",
		"Heroes are ready immediately after Accept. No training.",
		"Raid team size is 1 to 5 heroes.",
		"Recommended Power is not a hard gate.",
		"Raid failure: no reward, no hero loss, no extra penalty.",
		"RAIDING heroes pause production and leave the display.",
		"ACTIVE heroes produce Magic Stone.",
		"No Combine, Fusion, Merge, Evolution, Hero Level, Hero Death, or extra currencies.",
	},

	Forbidden = {
		"Training",
		"AutoCombine",
		"ManualCombine",
		"Fusion",
		"Evolution",
		"HeroLevel",
		"HeroLoss",
		"HeroDeath",
		"MultipleMainCurrencies",
		"DirectHeroToGold",
	},
}

return GameRules
