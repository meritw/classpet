-- Night buff proposals from game-design.md.
-- Status: proposal until Bob finalizes the MVP buff set.
-- Quizzes grant night buffs (locked); these ids are the scaffold defaults.

local Types = require(script.Parent.Types)

export type BuffDef = {
	id: Types.BuffId,
	displayName: string,
	description: string,
	earnedFrom: Types.QuizSubject,
}

local BuffDefs: { [Types.BuffId]: BuffDef } = {
	QuietPaws = {
		id = "QuietPaws",
		displayName = "Quiet Paws",
		description = "Shorter dog detect range while sneaking.",
		earnedFrom = "Spelling",
	},
	SugarDash = {
		id = "SugarDash",
		displayName = "Sugar Dash",
		description = "Brief sprint burst (cooldown) for gaps between hide spots.",
		earnedFrom = "Math",
	},
	LessonLeftover = {
		id = "LessonLeftover",
		displayName = "Lesson Leftover",
		description = "One free near-catch grace per night (dog loses you once).",
		earnedFrom = "Spelling", -- also awarded after N correct answers in BuffService rules
	},
}

return BuffDefs
