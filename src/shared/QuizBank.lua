-- Simple grade-school spelling + math questions for day quizzes.
-- Server validates answers against this bank; client only presents choices.

local Types = require(script.Parent.Types)

local QuizBank: { Types.QuizQuestion } = {
	{
		id = "spell_friend",
		subject = "Spelling",
		prompt = "Which spelling is correct?",
		choices = { "freind", "friend", "frend", "friand" },
		correctIndex = 2,
		buffOnCorrect = "QuietPaws",
	},
	{
		id = "spell_because",
		subject = "Spelling",
		prompt = "Spell the word that means 'for the reason that':",
		choices = { "becuase", "becouse", "because", "becuz" },
		correctIndex = 3,
		buffOnCorrect = "QuietPaws",
	},
	{
		id = "math_add_7_5",
		subject = "Math",
		prompt = "7 + 5 = ?",
		choices = { "11", "12", "13", "10" },
		correctIndex = 2,
		buffOnCorrect = "SugarDash",
	},
	{
		id = "math_sub_20_8",
		subject = "Math",
		prompt = "20 − 8 = ?",
		choices = { "10", "11", "12", "18" },
		correctIndex = 3,
		buffOnCorrect = "SugarDash",
	},
	{
		id = "math_mul_3_4",
		subject = "Math",
		prompt = "3 × 4 = ?",
		choices = { "7", "9", "12", "14" },
		correctIndex = 3,
		buffOnCorrect = "SugarDash",
	},
}

local function getById(id: string): Types.QuizQuestion?
	for _, q in QuizBank do
		if q.id == id then
			return q
		end
	end
	return nil
end

local function pickRandom(rng: Random?, excludeId: string?): Types.QuizQuestion
	local r = rng or Random.new()
	if #QuizBank == 1 then
		return QuizBank[1]
	end
	local idx = r:NextInteger(1, #QuizBank)
	local chosen = QuizBank[idx]
	if excludeId and chosen.id == excludeId then
		idx = (idx % #QuizBank) + 1
		chosen = QuizBank[idx]
	end
	return chosen
end

return {
	All = QuizBank,
	GetById = getById,
	PickRandom = pickRandom,
}
