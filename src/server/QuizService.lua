-- Day quizzes: present spelling/math questions; validate answers; grant night buffs.
-- Not a hard gate to night (locked).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local QuizBank = require(ReplicatedStorage.Shared.QuizBank)

local PhaseController = require(script.Parent.PhaseController)
local BuffService = require(script.Parent.BuffService)
local LevelSetup = require(script.Parent.LevelSetup)

local QuizService = {}

local remotes = nil :: any
local lastQuizAt: { [Player]: number } = {}
local activeQuestion: { [Player]: string } = {} -- questionId awaiting answer
local lastQuestionId: { [Player]: string } = {}

local function clientSafeQuestion(q: Types.QuizQuestion)
	return {
		id = q.id,
		subject = q.subject,
		prompt = q.prompt,
		choices = q.choices,
		-- correctIndex intentionally omitted
	}
end

function QuizService.BindRemotes(remoteApi)
	remotes = remoteApi
end

function QuizService.ClearPlayer(player: Player)
	lastQuizAt[player] = nil
	activeQuestion[player] = nil
	lastQuestionId[player] = nil
end

function QuizService.RequestQuiz(player: Player): (boolean, string?)
	if not PhaseController.IsDay() then
		return false, "Quizzes are for daytime lessons."
	end
	if PhaseController.HasWon() then
		return false, "Session already won."
	end

	local now = os.clock()
	local last = lastQuizAt[player] or 0
	if now - last < GameConfig.QuizCooldownSeconds then
		return false, "Wait a moment."
	end

	-- Soft proximity check to lesson spot when present.
	local lesson = LevelSetup.GetFirstTagged(GameConfig.Tags.LessonSpot)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if lesson and lesson:IsA("BasePart") and root then
		if (root.Position - lesson.Position).Magnitude > 14 then
			return false, "Get closer to the lesson."
		end
	end

	local q = QuizBank.PickRandom(nil, lastQuestionId[player])
	lastQuizAt[player] = now
	activeQuestion[player] = q.id
	lastQuestionId[player] = q.id

	if remotes then
		remotes.QuizPresented:FireClient(player, clientSafeQuestion(q))
	end
	return true, nil
end

function QuizService.SubmitAnswer(player: Player, questionId: unknown, choiceIndex: unknown): (boolean, Types.BuffId?)
	if typeof(questionId) ~= "string" then
		return false, nil
	end
	if typeof(choiceIndex) ~= "number" then
		return false, nil
	end
	local idx = choiceIndex :: number
	if idx ~= idx or math.abs(idx) == math.huge then
		return false, nil
	end
	idx = math.floor(idx)
	if idx < 1 or idx > 8 then
		return false, nil
	end

	if not PhaseController.IsDay() then
		return false, nil
	end
	if activeQuestion[player] ~= questionId then
		return false, nil
	end

	local q = QuizBank.GetById(questionId)
	if not q then
		return false, nil
	end

	activeQuestion[player] = nil
	local correct = idx == q.correctIndex
	if correct then
		BuffService.RecordCorrectAnswer(player, q.buffOnCorrect)
		if remotes then
			remotes.QuizResult:FireClient(player, { ok = true, buffId = q.buffOnCorrect })
		end
		return true, q.buffOnCorrect
	end

	if remotes then
		remotes.QuizResult:FireClient(player, { ok = false })
	end
	return false, nil
end

function QuizService.WireRemotes()
	assert(remotes, "QuizService remotes not bound")
	remotes.RequestQuiz.OnServerEvent:Connect(function(player: Player)
		QuizService.RequestQuiz(player)
	end)
	remotes.SubmitQuizAnswer.OnServerEvent:Connect(function(player: Player, questionId, choiceIndex)
		QuizService.SubmitAnswer(player, questionId, choiceIndex)
	end)
end

return QuizService
