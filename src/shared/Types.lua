--!strict

export type CandidateStatus = "PENDING" | "ACCEPTED" | "REJECTED"
export type HeroStatus = "ACTIVE" | "RAIDING"
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
	Status: HeroStatus,
	CreatedAt: number,
}

export type PlayerState = {
	Gold: number,
	MagicStone: number,
	MagicStoneCapacity: number,
	ConverterLevel: number,
	RecruitmentLevel: number,
	PendingCandidate: Candidate?,
	Heroes: { Hero },
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
	RecruitmentLevel: number,
	RecruitFee: number,
	RecruitLocked: boolean,
	PendingCandidate: Candidate?,
}

export type Raid = {
	RaidID: string,
	PlayerID: number,
	MapID: string,
	HeroIDs: { string },
	TeamPower: number,
	RecommendedPower: number,
	SuccessChance: number,
	StartTime: number,
	EndTime: number,
	Status: RaidStatus,
}

return {}
