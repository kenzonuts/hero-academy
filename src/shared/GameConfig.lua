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
		HeroTypes = { "warrior", "archer", "mage", "support", "tank" },
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
			B8 = 60000,
			B9 = 150000,
		},
		StatRanges = {
			B1 = { Power = { 10, 30 }, Production = { 3, 8 } },
			B2 = { Power = { 35, 55 }, Production = { 10, 20 } },
			B3 = { Power = { 60, 90 }, Production = { 20, 35 } },
			B4 = { Power = { 90, 140 }, Production = { 35, 60 } },
			B5 = { Power = { 150, 250 }, Production = { 60, 150 } },
			B6 = { Power = { 250, 400 }, Production = { 120, 220 } },
			B7 = { Power = { 400, 600 }, Production = { 180, 320 } },
			B8 = { Power = { 600, 900 }, Production = { 280, 450 } },
			B9 = { Power = { 900, 1300 }, Production = { 400, 650 } },
		},
		-- Weights per recruitment level. Higher level = better rolls; top tier stays rare.
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
			[12] = { B1 = 3200, B2 = 2200, B3 = 2150, B4 = 1200, B5 = 720, B6 = 380, B7 = 140, B8 = 10 },
			[13] = { B1 = 2900, B2 = 2100, B3 = 2150, B4 = 1300, B5 = 850, B6 = 480, B7 = 180, B8 = 20 },
			[14] = { B1 = 2600, B2 = 2000, B3 = 2150, B4 = 1400, B5 = 960, B6 = 580, B7 = 220, B8 = 30 },
			[15] = { B1 = 2400, B2 = 1900, B3 = 2100, B4 = 1450, B5 = 1080, B6 = 700, B7 = 260, B8 = 40, B9 = 10 },
			[16] = { B1 = 2200, B2 = 1800, B3 = 2050, B4 = 1500, B5 = 1160, B6 = 790, B7 = 320, B8 = 60, B9 = 20 },
			[17] = { B1 = 2000, B2 = 1700, B3 = 2000, B4 = 1550, B5 = 1240, B6 = 860, B7 = 370, B8 = 90, B9 = 40 },
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
		RecruitmentBoardImage = "rbxassetid://116290958290679",
		RecruitmentBoardTitleImage = "rbxassetid://119061321199856",
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
		RecruitmentGoldImage = "rbxassetid://129136027133209",
		NavHomeImage = "rbxassetid://97332745177623",
		NavGuildImage = "rbxassetid://81693683674496",
		NavStoreImage = "rbxassetid://93199682618910",
		-- Common = B1, Uncommon = B2, Rare = B3. B4+ reuse Rare until those assets exist.
		RecruitmentCards = {
			B1 = {
				warrior = "130809043630263",
				archer = "140461997445844",
				tank = "97592705223227",
				mage = "126954993553801",
				support = "104561466655136",
			},
			B2 = {
				warrior = "73036020177015",
				archer = "128187837811649",
				tank = "93720067000870",
				mage = "97507957306573",
				support = "119805615910871",
			},
			B3 = {
				warrior = "84223562637640",
				archer = "76208226702913",
				tank = "90563795731746",
				mage = "131280301491407",
				support = "109461157152898",
			},
		},
		SummonName = "summon",
		SummonPartNames = { "summonplate", "summon" },
		GuildTeleportFolder = "GUILD",
		GuildTeleportPart = "GUILDTP",
		GuildFaceTarget = "NPC_GuildMaster",
		StoreTeleportFolder = "STORE",
		StoreTeleportPart = "STORETP",
		StoreFaceTarget = "NPC_Shopkeeper",
		HeroModels = {
			Folder = "DUCKHERO",
			-- Only map tiers that already have duck folders. More ranks later.
			Tiers = {
				B1 = "ROOKIE",
				B2 = "VETERAN",
				B3 = "ELITE",
				B4 = "CHAMPION",
				B5 = "LEGEND",
				B6 = "MYTHIC",
				B7 = "TITAN",
				B8 = "CONQUEROR",
				B9 = "APEX",
			},
			-- Model: duck_{role}_{tierLower} e.g. duck_warrior_rookie … duck_tank_apex
			Roles = {
				warrior = "warrior",
				archer = "archer",
				mage = "mage",
				support = "support",
				tank = "tank",
				-- Legacy saves
				Knight = "warrior",
				Archer = "archer",
				Mage = "mage",
				Hammer = "support",
				Shield = "tank",
			},
			FallbackTier = "ROOKIE",
			-- Longest bounding-box axis after clone (studs). 0 = keep original asset size.
			TargetSize = 0,
			-- Studs above hero for PAD / power text. Lower = closer to the model.
			LabelStudsOffsetY = 1.4,
			-- Only show label when camera/player is this close (studs). Keep low so corner pads hide from spawn.
			LabelMaxDistance = 16,
			LabelRangeFactor = 0.25,
		},
		TierColors = {
			B1 = { 150, 150, 155 },
			B2 = { 80, 170, 90 },
			B3 = { 70, 130, 210 },
			B4 = { 150, 90, 210 },
			B5 = { 230, 180, 60 },
			B6 = { 230, 90, 70 },
			B7 = { 255, 240, 180 },
			B8 = { 200, 60, 60 },
			B9 = { 40, 220, 230 },
		},
	},

	Phase1 = {
		StartingGold = 1000,
		SeedHeroes = {
			{ HeroType = "warrior", Tier = "B1", Power = 20, Production = 10 },
			{ HeroType = "mage", Tier = "B2", Power = 48, Production = 25 },
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
