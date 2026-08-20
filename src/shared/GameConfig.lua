--!strict
--[[
	Example balancing from GAME_LOGIC.md.
	Tune numbers here. Do not change the 1:1 conversion ratio or raid party size.
]]

local GameConfig = {
	Conversion = {
		MagicStoneToGold = 1,
	},

	PendingCandidate = {
		MaxActive = 1,
		Expires = false,
	},

	Recruitment = {
		RecruitFeeGold = 100,
		StartingLevel = 1,
		HeroTypes = { "Knight", "Archer", "Mage" },
		AcceptFeeByTier = {
			B1 = 100,
			B2 = 250,
			B3 = 600,
			B4 = 1500,
			B5 = 4000,
			B6 = 10000,
			B7 = 25000,
		},
		StatRanges = {
			B1 = { Power = { 10, 30 }, Production = { 3, 8 } },
			B2 = { Power = { 35, 55 }, Production = { 10, 20 } },
			B3 = { Power = { 60, 90 }, Production = { 20, 35 } },
			B4 = { Power = { 90, 140 }, Production = { 35, 60 } },
			B5 = { Power = { 150, 250 }, Production = { 60, 150 } },
			B6 = { Power = { 250, 400 }, Production = { 120, 220 } },
			B7 = { Power = { 400, 600 }, Production = { 180, 320 } },
		},
		-- Weights per recruitment level. Unlisted levels should be added during balancing.
		TierWeights = {
			[1] = { B1 = 70, B2 = 30 },
			[2] = { B1 = 50, B2 = 40, B3 = 10 },
			[3] = { B1 = 35, B2 = 40, B3 = 20, B4 = 5 },
			[5] = { B1 = 15, B2 = 30, B3 = 30, B4 = 20, B5 = 5 },
		},
		EliteTicketMinimumTier = "B3",
	},

	Converter = {
		SpeedByLevel = {
			[1] = 10,
			[2] = 25,
			[3] = 50,
			[4] = 100,
			[5] = 200,
		},
	},

	Storage = {
		DefaultCapacity = 10000,
	},

	Phase1 = {
		StartingGold = 1000,
		SeedHeroes = {
			{ HeroType = "Knight", Tier = "B1", Power = 20, Production = 10 },
			{ HeroType = "Mage", Tier = "B2", Power = 48, Production = 25 },
		},
	},

	Raid = {
		MinHeroes = 1,
		MaxHeroes = 5,
		SuccessByMinRatio = {
			{ MinRatio = 1.50, Chance = 1.00 },
			{ MinRatio = 1.25, Chance = 0.95 },
			{ MinRatio = 1.00, Chance = 0.85 },
			{ MinRatio = 0.75, Chance = 0.60 },
			{ MinRatio = 0.50, Chance = 0.35 },
			{ MinRatio = 0.25, Chance = 0.10 },
			{ MinRatio = 0.00, Chance = 0.05 },
		},
		BonusLoot = {
			{ Id = "Gold", Weight = 70 },
			{ Id = "MagicStone", Weight = 20 },
			{ Id = "RecruitTicket", Weight = 9 },
			{ Id = "EliteRecruitTicket", Weight = 1 },
		},
		ProductionBonus = {
			Multiplier = 1.20,
			DurationSeconds = 600,
		},
		Maps = {
			{
				Id = "WhisperingForest",
				DisplayName = "Whispering Forest",
				RecommendedPower = 500,
				DurationSeconds = 180,
				BaseGoldReward = 50000,
			},
			{
				Id = "DesertRuins",
				DisplayName = "Desert Ruins",
				RecommendedPower = 2000,
				DurationSeconds = 300,
				BaseGoldReward = 250000,
			},
			{
				Id = "VolcanoFortress",
				DisplayName = "Volcano Fortress",
				RecommendedPower = 7500,
				DurationSeconds = 420,
				BaseGoldReward = 1000000,
			},
			{
				Id = "FrozenCitadel",
				DisplayName = "Frozen Citadel",
				RecommendedPower = 20000,
				DurationSeconds = 600,
				BaseGoldReward = 3000000,
			},
			{
				Id = "VoidFortress",
				DisplayName = "Void Fortress",
				RecommendedPower = 50000,
				DurationSeconds = 900,
				BaseGoldReward = 5000000,
				GuaranteesEliteTicket = true,
			},
		},
	},
}

return GameConfig
