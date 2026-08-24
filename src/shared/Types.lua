--!strict

export type CandidateStatus = "PENDING" | "ACCEPTED" | "REJECTED"
export type HeroStatus = "ACTIVE" | "BAGGED" | "RAIDING"
export type RaidStatus = "ACTIVE" | "SUCCESS" | "FAILED"

export type Candidate = {
	CandidateID: string,
	HeroType: string,
	Tier: string,
	Power: number,
	Production: number,
	AcceptCost: number,
	CreatedAt: number,
	Status: CandidateStatus,
}

export type Hero = {
	HeroID: string,
	HeroType: string,
	Tier: string,
	Power: number,
	Production: number,
	AcceptCost: number,
	Purchased: boolean,
	Status: HeroStatus,
	DisplaySlot: number?,
	CreatedAt: number,
}

export type RaidHeroHome = {
	Status: HeroStatus,
	DisplaySlot: number?,
}

export type Raid = {
	RaidID: string,
	PlayerID: number,
	MapID: string,
	MapName: string,
	HeroIDs: { string },
	HeroHomes: { RaidHeroHome },
	TeamPower: number,
	RecommendedPower: number,
	SuccessChance: number,
	StartTime: number,
	EndTime: number,
	Status: RaidStatus,
}

export type RaidSnapshot = {
	RaidID: string,
	MapID: string,
	MapName: string,
	HeroIDs: { string },
	TeamPower: number,
	RecommendedPower: number,
	SuccessChance: number,
	EndTime: number,
	RemainingSeconds: number,
	Status: RaidStatus,
}

export type PlayerState = {
	Gold: number,
	MagicStone: number,
	MagicStoneCapacity: number,
	ConverterLevel: number,
	RecruitmentLevel: number,
	PendingCandidate: Candidate?,
	PendingCandidates: { Candidate },
	Heroes: { Hero },
	ActiveRaid: Raid?,
	RecruitTickets: number,
	EliteTickets: number,
	ProductionBonusEndsAt: number,
	LastRaidMessage: string?,
	LastRaidOk: boolean?,
}

export type ActionResult = {
	ok: boolean,
	error: string?,
	message: string?,
}

export type PlayerSnapshot = {
	Gold: number,
	MagicStone: number,
	MagicStoneCapacity: number,
	ProductionPerSecond: number,
	ConverterSpeed: number,
	HeroCount: number,
	MaxOwnedHeroes: number,
	ActiveCount: number,
	BagCount: number,
	RaidingCount: number,
	Heroes: { Hero },
	RecruitmentLevel: number,
	RecruitmentUpgradeCost: number?,
	ConverterLevel: number,
	ConverterUpgradeCost: number?,
	ConverterNextSpeed: number?,
	RecruitFee: number,
	RecruitLocked: boolean,
	PendingCandidate: Candidate?,
	PendingCandidates: { Candidate },
	RecruitTickets: number,
	EliteTickets: number,
	ProductionBonusRemaining: number,
	ActiveRaid: RaidSnapshot?,
	LastRaidMessage: string?,
	LastRaidOk: boolean?,
	AcademyName: string?,
}

return {}
