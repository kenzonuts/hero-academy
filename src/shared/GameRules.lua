--!strict
--[[
	Hero Recruitment — Studio-readable design freeze.

	Full document: GAME_LOGIC.md (project root).
	Numbers: GameConfig.lua.
	Work order: PHASES.md.

	Studio Assistant should follow these rules when writing scripts.
]]

local GameRules = {
	Version = "1.5",
	Loop = "RECRUIT → JUDGE → SAVE/ACCEPT → COLLECT → PRODUCE → CONVERT → INVEST → RAID → REWARD",

	Currencies = {
		Gold = "Primary currency. Recruit, upgrades. Small refund from selling purchased Heroes.",
		MagicStone = "Hero production only. Never a second main currency.",
	},

	HardRules = {
		"Heroes produce Magic Stone, never Gold.",
		"Converter ratio is always 1 Magic Stone = 1 Gold. Upgrade speed only.",
		"Recruit Fee is the Gold cost to roll a candidate. It scales with Recruitment level. 5X / 10X multiply the 1X fee. Accept is free.",
		"Recruit Fee is never refunded, even on Reject or Sell.",
		"High-tier Heroes are rare. Rarity is the cost of a free Accept.",
		"Sell refund is floor(AcceptCost * 0.25) of the tier catalog value locked at Accept. This is a maximum.",
		"Seed / starter Heroes can be sold. Refund uses the tier catalog locked as AcceptCost. RAIDING Heroes cannot be sold.",
		"Maximum 10 pending cards on the Recruitment Board. Recruit 1X / 5X / 10X fill empty slots. TAKE ALL accepts, CLEAR ALL rejects.",
		"Pending candidates do not expire, mutate, or reroll.",
		"Candidate stats are locked at generation.",
		"Heroes are ready immediately after Accept. No training.",
		"Facility upgrades cost Gold. Converter upgrade changes speed only, never the 1:1 ratio.",
		"Raid team size is 1 to 5 heroes. One Raid at a time.",
		"Recommended Power is not a hard gate. Power at or above Recommended can shorten Raid time, down to 50% duration.",
		"Raid failure: no reward, no hero loss, no extra penalty. Opportunity cost is paused production.",
		"RAIDING Heroes leave their pad empty. On return they take the same pad if still free, else the next empty pad or Bag.",
		"Maximum 40 Heroes owned. Recruit and Accept stop at 40 until a Hero is sold.",
		"Display uses Workspace pads named hero inside the player's academy (AKADEMI1–AKADEMI6). Maximum 40 displayed Heroes.",
		"Each player is assigned one academy. A 7th player is kicked while all academies are taken.",
		"Each displayed Hero keeps a sticky pad. Selling leaves that pad empty; other Heroes do not slide over.",
		"Bagged Heroes do not auto-promote onto empty pads. A new Accept may take the first empty pad.",
		"If display is full, a newly accepted Hero goes to the Bag (BAGGED).",
		"ACTIVE and BAGGED Heroes produce Magic Stone. RAIDING Heroes do not.",
		"Progress is saved on leave and periodically while playing.",
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
