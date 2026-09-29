-- Solo-first session orchestration: wires systems, remotes, player lifecycle,
-- and pushes SessionSnapshot to the client. Endless day/night until phone win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LevelSetup = require(script.Parent.LevelSetup)
local PhaseController = require(script.Parent.PhaseController)
local CageService = require(script.Parent.CageService)
local BuffService = require(script.Parent.BuffService)
local QuizService = require(script.Parent.QuizService)
local DogAI = require(script.Parent.DogAI)
local PhoneObjective = require(script.Parent.PhoneObjective)

local SessionService = {}

local remotes = nil :: any
local started = false

local function buildSnapshot(player: Player): Types.SessionSnapshot
	return {
		phase = PhaseController.GetPhase(),
		cycleIndex = PhaseController.GetCycleIndex(),
		buffs = BuffService.GetSnapshot(player),
		escapedThisNight = CageService.HasEscapedThisNight(player),
		goalText = PhaseController.GetGoalText(),
	}
end

local function pushSnapshot(player: Player)
	if not remotes then
		return
	end
	remotes.SessionUpdated:FireClient(player, buildSnapshot(player))
end

local function pushAll()
	for _, player in Players:GetPlayers() do
		pushSnapshot(player)
	end
end

local function onPhaseChanged(phase: Types.Phase, _cycleIndex: number)
	if phase == "Day" then
		for _, player in Players:GetPlayers() do
			BuffService.ResetForNewDay(player)
		end
		CageService.OnDayStarted()
		DogAI.OnDayStarted()
	elseif phase == "Night" then
		for _, player in Players:GetPlayers() do
			BuffService.OnNightStarted(player)
		end
		CageService.OnNightStarted()
		DogAI.OnNightStarted()
	end
	pushAll()
end

local function handleInteract(player: Player, kind: unknown)
	if typeof(kind) ~= "string" then
		return
	end
	if kind == "Latch" then
		local ok = CageService.TryLatchEscape(player)
		if ok then
			pushSnapshot(player)
		end
	elseif kind == "Phone" then
		PhoneObjective.TryCall(player)
		pushSnapshot(player)
	elseif kind == "Lesson" then
		QuizService.RequestQuiz(player)
	end
end

local function handleSugarDash(player: Player)
	if not PhaseController.IsNight() then
		return
	end
	if not CageService.HasEscapedThisNight(player) then
		return
	end
	if not BuffService.Consume(player, "SugarDash") then
		return
	end
	-- Movement burst is client-presented; server only consumes charge (MVP stub).
	-- A later pass can apply a short server-side speed attribute.
	pushSnapshot(player)
end

local function onPlayerAdded(player: Player)
	BuffService.InitPlayer(player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			if PhaseController.IsDay() or not CageService.HasEscapedThisNight(player) then
				CageService.ReturnToCage(player)
			end
			PhaseController.NotifyPlayerJoined(player)
			pushSnapshot(player)
		end)
	end)
	if player.Character then
		CageService.InitPlayer(player)
		PhaseController.NotifyPlayerJoined(player)
		pushSnapshot(player)
	end
end

local function onPlayerRemoving(player: Player)
	BuffService.ClearPlayer(player)
	CageService.ClearPlayer(player)
	QuizService.ClearPlayer(player)
	PhoneObjective.ClearPlayer(player)
end

function SessionService.Start()
	if started then
		return
	end
	started = true

	LevelSetup.EnsurePlaceholders()

	Remotes.InitServer()
	remotes = Remotes.GetServer()

	PhaseController.BindRemotes(remotes)
	CageService.BindRemotes(remotes)
	QuizService.BindRemotes(remotes)

	PhaseController.SetHooks({
		OnPhaseChanged = onPhaseChanged,
		GetGoalText = function(phase)
			if phase == "Day" then
				return "Play along — ace quizzes for night buffs. Night comes on its own."
			elseif phase == "Night" then
				return "Slip the latch. Sneak to the teacher’s desk phone. Call the dog’s family."
			else
				return "You called the family — the dog can go home. Replay anytime."
			end
		end,
	})

	QuizService.WireRemotes()
	remotes.RequestInteract.OnServerEvent:Connect(handleInteract)
	remotes.RequestSugarDash.OnServerEvent:Connect(handleSugarDash)

	CageService.Start()
	DogAI.Start()

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Solo MVP: start first day immediately.
	PhaseController.StartDay({ bumpCycle = false, reason = "SessionStart" })
	pushAll()

	-- Keep clients' buff strips fresh after quiz grants.
	task.spawn(function()
		while started do
			pushAll()
			task.wait(1)
		end
	end)
end

return SessionService
