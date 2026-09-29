-- Tunables for the solo MVP loop.
-- Locked design: solo; quizzes → night buffs; dog catch → next day; endless retry; phone win.
-- See docs/game-design.md (Project store) and comments citing locked decisions.

local GameConfig = {
	-- Solo story MVP: one player session drives the classroom clock.
	SoloMode = true,

	-- Day length before night arrives. Quizzes do NOT gate night (locked).
	DayDurationSeconds = 90,

	-- Brief pause after dog catch before day resumes (readable "Tomorrow…" beat).
	CatchToDayDelaySeconds = 2.5,

	-- Night has no hard timer; ends on phone win or dog catch → next day.
	-- Optional soft guidance only — not a fail state.
	NightSoftHintSeconds = 180,

	-- Cage / catch
	DayCatchCheckInterval = 0.25,
	CageRespawnOffset = Vector3.new(0, 2, 0),

	-- Latch: only usable during Night and only if not already caught this night.
	LatchInteractDistance = 12,

	-- Dog AI stub
	DogPatrolSpeed = 8,
	DogChaseSpeed = 14,
	DogDetectRange = 28, -- QuietPaws shortens this at night
	DogCatchRange = 6,
	DogQuietPawsDetectMultiplier = 0.65,

	-- Phone
	PhoneInteractDistance = 10,
	PhoneCallDurationSeconds = 2,

	-- Quizzes
	QuizCooldownSeconds = 3,
	MaxBuffChargesPerDay = 3,

	-- CollectionService tags for level authorship (no hardcoded Instance paths).
	Tags = {
		CageVolume = "CageVolume",
		Latch = "Latch",
		Phone = "Phone",
		DogSpawn = "DogSpawn",
		LessonSpot = "LessonSpot",
		HideSpot = "HideSpot",
	},
}

return GameConfig
