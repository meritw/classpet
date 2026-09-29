-- Tunables for the solo MVP loop.
-- Locked design: solo; quizzes → night buffs; dog catch → next day; endless retry; phone win.
-- See docs/game-design.md (Project store) and comments citing locked decisions.

local GameConfig = {
	-- Solo story MVP: one player session drives the classroom clock.
	SoloMode = true,

	-- Player is the classroom hamster (not a human in a giant cage).
	-- Applied via Humanoid:ScaleTo on spawn; ~0.2 ≈ 1-stud-tall pet vs ~5-stud R15.
	HamsterScale = 0.2,
	-- ScaleTo also shrinks JumpHeight; restore a usable hamster hop after scaling.
	HamsterJumpHeight = 3.2,

	-- Desk-pet cage (human classroom studs). Comfortable pet enclosure for ScaleTo(0.2);
	-- classroom outside stays human-scale. Was 4×2.5×3 (too tight in playtest).
	CageSize = Vector3.new(7, 4, 5.5),
	-- Cage sits on a desk; center Y = desk top + half cage height (desk top ≈ 3).
	CageCenter = Vector3.new(-28, 5, 0),

	-- Day length before night arrives. Quizzes do NOT gate night (locked).
	DayDurationSeconds = 90,

	-- Brief pause after dog catch before day resumes (readable "Tomorrow…" beat).
	CatchToDayDelaySeconds = 2.5,

	-- Night has no hard timer; ends on phone win or dog catch → next day.
	-- Optional soft guidance only — not a fail state.
	NightSoftHintSeconds = 180,

	-- Cage / catch (offsets relative to the desk-pet cage).
	DayCatchCheckInterval = 0.25,
	-- Cage center is mid-volume; HRP should sit just above the tray floor inside.
	-- Y ≈ -(halfHeight - 0.5) so feet land on bedding for CageSize.Y = 4.
	CageRespawnOffset = Vector3.new(0, -1.5, 0),
	LatchEscapeOffset = Vector3.new(1.0, 0, 0), -- studs outside latch onto the desk

	-- Latch / lesson: reach while inside the pet cage (latch on +X face).
	LatchInteractDistance = 4,
	LessonInteractDistance = 3,

	-- Dog AI stub (classroom / human scale — hamster is tiny in a big room at night).
	DogPatrolSpeed = 8,
	DogChaseSpeed = 14,
	DogDetectRange = 28, -- QuietPaws shortens this at night
	DogCatchRange = 6,
	DogQuietPawsDetectMultiplier = 0.65,

	-- Phone (classroom scale — reach from hamster near the desk).
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
