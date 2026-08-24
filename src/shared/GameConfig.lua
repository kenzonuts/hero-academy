--!strict
--[[
	Example balancing from GAME_LOGIC.md.
	Tune numbers here. Do not change the 1:1 conversion ratio or raid party size.
]]

local GameConfig = {
	Conversion = {
		MagicStoneToGold = 1,
		-- Event currency. 1 Black Crystal = 10 Gold. Heroes never produce this.
		BlackCrystalToGold = 10,
	},

	PendingCandidate = {
		MaxActive = 10,
		Expires = false,
	},

	Sell = {
		RefundPercent = 0.25,
		RecruitFeeRefunded = false,
		AllowSeedHeroSell = true,
		BlockIfRaiding = true,
	},

	Recruitment = {
		RecruitFeeGold = 100,
		-- 1X cost at that Recruitment level. 5X / 10X multiply this. Accept stays free.
		RecruitFeeByLevel = {
			[1] = 100,
			[2] = 1_000,
			[3] = 8_000,
			[4] = 50_000,
			[5] = 400_000,
			[6] = 2_500_000,
			[7] = 15_000_000,
			[8] = 80_000_000,
			[9] = 400_000_000,
			[10] = 2_000_000_000,
			[11] = 8_000_000_000,
			[12] = 30_000_000_000,
			[13] = 100_000_000_000,
			[14] = 250_000_000_000,
			[15] = 500_000_000_000,
			[16] = 800_000_000_000,
			[17] = 1_000_000_000_000,
		},
		StartingLevel = 1,
		MaxLevel = 17,
		-- Cost to reach that level (pay this to go from n-1 → n).
		UpgradeCostGold = {
			[2] = 1_000_000,
			[3] = 8_000_000,
			[4] = 50_000_000,
			[5] = 400_000_000,
			[6] = 2_500_000_000,
			[7] = 15_000_000_000,
			[8] = 80_000_000_000,
			[9] = 400_000_000_000,
			[10] = 2_000_000_000_000,
			[11] = 8_000_000_000_000,
			[12] = 30_000_000_000_000,
			[13] = 100_000_000_000_000,
			[14] = 250_000_000_000_000,
			[15] = 500_000_000_000_000,
			[16] = 800_000_000_000_000,
			[17] = 1_000_000_000_000_000,
		},
		HeroTypes = { "Knight", "Archer", "Mage", "Hammer", "Shield" },
		ChargeAcceptFee = false,
		-- Catalog value by tier. Used for Sell refund, not charged on Accept.
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
		-- Weights per recruitment level. Higher level = better rolls; B7 stays rare.
		TierWeights = {
			[1] = { B1 = 9300, B2 = 700 },
			[2] = { B1 = 8500, B2 = 1400, B3 = 100 },
			[3] = { B1 = 8000, B2 = 1600, B3 = 300, B4 = 100 },
			[4] = { B1 = 7600, B2 = 2000, B3 = 300, B4 = 90, B5 = 10 },
			[5] = { B1 = 6800, B2 = 2300, B3 = 700, B4 = 180, B5 = 20 },
			[6] = { B1 = 6200, B2 = 2400, B3 = 1000, B4 = 320, B5 = 70, B6 = 10 },
			[7] = { B1 = 5600, B2 = 2500, B3 = 1300, B4 = 450, B5 = 120, B6 = 30 },
			[8] = { B1 = 5000, B2 = 2500, B3 = 1600, B4 = 600, B5 = 220, B6 = 70, B7 = 10 },
			[9] = { B1 = 4500, B2 = 2500, B3 = 1800, B4 = 750, B5 = 320, B6 = 110, B7 = 20 },
			[10] = { B1 = 4000, B2 = 2400, B3 = 2000, B4 = 900, B5 = 450, B6 = 200, B7 = 50 },
			[11] = { B1 = 3600, B2 = 2300, B3 = 2100, B4 = 1050, B5 = 580, B6 = 280, B7 = 90 },
			[12] = { B1 = 3200, B2 = 2200, B3 = 2150, B4 = 1200, B5 = 720, B6 = 380, B7 = 150 },
			[13] = { B1 = 2900, B2 = 2100, B3 = 2150, B4 = 1300, B5 = 850, B6 = 500, B7 = 200 },
			[14] = { B1 = 2600, B2 = 2000, B3 = 2150, B4 = 1400, B5 = 980, B6 = 620, B7 = 250 },
			[15] = { B1 = 2400, B2 = 1900, B3 = 2100, B4 = 1450, B5 = 1100, B6 = 750, B7 = 300 },
			[16] = { B1 = 2200, B2 = 1800, B3 = 2050, B4 = 1500, B5 = 1200, B6 = 850, B7 = 400 },
			[17] = { B1 = 2000, B2 = 1700, B3 = 2000, B4 = 1550, B5 = 1300, B6 = 950, B7 = 500 },
		},
		EliteTicketMinimumTier = "B3",
	},

	Converter = {
		MaxLevel = 17,
		-- Cost to reach that level. Ratio stays 1 Magic Stone = 1 Gold.
		UpgradeCostGold = {
			[2] = 800_000,
			[3] = 6_000_000,
			[4] = 40_000_000,
			[5] = 300_000_000,
			[6] = 2_000_000_000,
			[7] = 12_000_000_000,
			[8] = 60_000_000_000,
			[9] = 300_000_000_000,
			[10] = 1_500_000_000_000,
			[11] = 6_000_000_000_000,
			[12] = 22_000_000_000_000,
			[13] = 75_000_000_000_000,
			[14] = 180_000_000_000_000,
			[15] = 400_000_000_000_000,
			[16] = 650_000_000_000_000,
			[17] = 800_000_000_000_000,
		},
		SpeedByLevel = {
			[1] = 10,
			[2] = 18,
			[3] = 32,
			[4] = 55,
			[5] = 90,
			[6] = 150,
			[7] = 250,
			[8] = 400,
			[9] = 650,
			[10] = 1000,
			[11] = 1600,
			[12] = 2500,
			[13] = 4000,
			[14] = 6500,
			[15] = 10000,
			[16] = 16000,
			[17] = 25000,
		},
	},

	Storage = {
		DefaultCapacity = 10000,
	},

	Display = {
		MaxSlots = 40,
		MaxOwnedHeroes = 40,
		PadName = "hero",
		PadFolder = "hero",
		MarkerHeight = 2.4,
		GoldImage = "rbxassetid://129136027133209",
		MagicStoneImage = "rbxassetid://116631277815450",
		BlackCrystalImage = "rbxassetid://96330948981939",
		RecruitmentBoardImage = "rbxassetid://99473344266235",
		RecruitmentBoardCloseImage = "rbxassetid://101015762977670",
		RecruitmentSlotEmptyImage = "rbxassetid://118354964205016",
		RecruitmentSlotClosedImage = "rbxassetid://71614679116854",
		RecruitmentCardGlowImage = "rbxassetid://76685873525509",
		RecruitmentTakeAllImage = "rbxassetid://81879706897992",
		RecruitmentTakeAllOffImage = "rbxassetid://124096776237817",
		RecruitmentClearAllImage = "rbxassetid://82321373313572",
		RecruitmentClearAllOffImage = "rbxassetid://113494313258023",
		RecruitmentOpenAllImage = "rbxassetid://131641419808933",
		RecruitmentOpenAllOffImage = "rbxassetid://99197636965121",
		RecruitmentRecruitOnImage = "rbxassetid://118490906708775",
		RecruitmentRecruitOffImage = "rbxassetid://126413221049424",
		RecruitmentGoldImage = "rbxassetid://84858883493617",
		-- Common = B1, Uncommon = B2, Rare = B3. B4+ reuse Rare until those assets exist.
		RecruitmentCards = {
			B1 = {
				Hammer = "130809043630263",
				Archer = "140461997445844",
				Knight = "97592705223227",
				Mage = "126954993553801",
				Shield = "104561466655136",
			},
			B2 = {
				Hammer = "73036020177015",
				Archer = "128187837811649",
				Knight = "93720067000870",
				Mage = "97507957306573",
				Shield = "119805615910871",
			},
			B3 = {
				Hammer = "84223562637640",
				Archer = "76208226702913",
				Knight = "90563795731746",
				Mage = "131280301491407",
				Shield = "109461157152898",
			},
		},
		SummonName = "summon",
		SummonPartNames = { "summonplate", "summon" },
		HeroModels = {
			Folder = "HEROES",
			Tiers = {
				B1 = "COMMON",
				B2 = "UNCOMMON",
				B3 = "RARE",
				B4 = "RARE",
				B5 = "RARE",
				B6 = "RARE",
				B7 = "RARE",
			},
			Names = {
				Knight = "KNIGHT",
				Archer = "BOW",
				Mage = "STAFF",
				Hammer = "HAMMER",
				Shield = "SHIELD",
			},
			-- Longest bounding-box axis after clone (studs). Same for every role.
			TargetSize = 5,
			-- 0 = auto: half the distance to the nearest other academy, capped so text stays readable.
			LabelMaxDistance = 0,
			LabelRangeFactor = 0.5,
		},
		TierColors = {
			B1 = { 150, 150, 155 },
			B2 = { 80, 170, 90 },
			B3 = { 70, 130, 210 },
			B4 = { 150, 90, 210 },
			B5 = { 230, 180, 60 },
			B6 = { 230, 90, 70 },
			B7 = { 255, 240, 180 },
		},
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
		-- Ratio <= SpeedStartRatio: full map duration. Ratio >= SpeedMaxRatio: MinDurationPercent.
		DurationByPower = {
			SpeedStartRatio = 1.00,
			SpeedMaxRatio = 1.50,
			MinDurationPercent = 0.50,
		},
		BonusGoldPercent = 0.25,
		BonusMagicStone = 2500,
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
				BlackCrystalReward = 8,
			},
			{
				Id = "DesertRuins",
				DisplayName = "Desert Ruins",
				RecommendedPower = 2000,
				DurationSeconds = 300,
				BaseGoldReward = 250000,
				BlackCrystalReward = 15,
			},
			{
				Id = "VolcanoFortress",
				DisplayName = "Volcano Fortress",
				RecommendedPower = 7500,
				DurationSeconds = 420,
				BaseGoldReward = 1000000,
				BlackCrystalReward = 30,
			},
			{
				Id = "FrozenCitadel",
				DisplayName = "Frozen Citadel",
				RecommendedPower = 20000,
				DurationSeconds = 600,
				BaseGoldReward = 3000000,
				BlackCrystalReward = 50,
			},
			{
				Id = "VoidFortress",
				DisplayName = "Void Fortress",
				RecommendedPower = 50000,
				DurationSeconds = 900,
				BaseGoldReward = 5000000,
				GuaranteesEliteTicket = true,
				BlackCrystalReward = 80,
			},
		},
	},

	-- Toggle raid drops. Wallet still converts leftover Black Crystal after the event.
	Event = {
		BlackCrystalRaid = true,
	},

	Academy = {
		Count = 6,
		Prefix = "AKADEMI",
		AttributeName = "AcademyName",
		KickWhenFull = true,
		KickMessage = "Server penuh. Maksimal 6 player (1 akademi per orang).",
	},
}

function GameConfig.CatalogAcceptCost(tier: string): number
	local recruitment = GameConfig.Recruitment
	local fees = recruitment and recruitment.AcceptFeeByTier
	if typeof(fees) ~= "table" then
		return 0
	end
	local value = (fees :: any)[tier]
	if typeof(value) == "number" and value > 0 then
		return math.floor(value)
	end
	return 0
end

return GameConfig
