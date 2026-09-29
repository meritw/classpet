-- Authoritative Day / Night / Won phase owner.
-- Locked: dog catch → force Day (no same-night re-escape); endless cycles until phone win;
-- quizzes do not gate night.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PhaseController = {}

export type Hooks = {
	OnPhaseChanged: (phase: Types.Phase, cycleIndex: number) -> (),
	GetGoalText: (phase: Types.Phase) -> string,
}

local phase: Types.Phase = "Day"
local cycleIndex = 1
local dayToken = 0
local hooks: Hooks? = nil
local remotes = nil :: any

local GOAL = {
	Day = "Play along — ace quizzes for night buffs. Night comes on its own.",
	Night = "Slip the latch. Sneak to the teacher’s desk phone. Call the dog’s family.",
	Won = "You called the family — the dog can go home. Replay anytime.",
}

function PhaseController.GetPhase(): Types.Phase
	return phase
end

function PhaseController.GetCycleIndex(): number
	return cycleIndex
end

function PhaseController.GetGoalText(): string
	if hooks and hooks.GetGoalText then
		return hooks.GetGoalText(phase)
	end
	return GOAL[phase]
end

function PhaseController.IsNight(): boolean
	return phase == "Night"
end

function PhaseController.IsDay(): boolean
	return phase == "Day"
end

function PhaseController.HasWon(): boolean
	return phase == "Won"
end

local function applyLighting(nextPhase: Types.Phase)
	if nextPhase == "Day" then
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(102, 102, 115)
	elseif nextPhase == "Night" then
		Lighting.ClockTime = 22
		Lighting.Brightness = 0.6
		Lighting.Ambient = Color3.fromRGB(40, 40, 55)
	elseif nextPhase == "Won" then
		Lighting.ClockTime = 7
		Lighting.Brightness = 2.5
		Lighting.Ambient = Color3.fromRGB(130, 120, 100)
	end
end

local function broadcast(player: Player?)
	if not remotes then
		return
	end
	local payloadPhase = phase
	local payloadCycle = cycleIndex
	local goal = PhaseController.GetGoalText()
	if player then
		remotes.PhaseChanged:FireClient(player, payloadPhase, payloadCycle, goal)
	else
		remotes.PhaseChanged:FireAllClients(payloadPhase, payloadCycle, goal)
	end
end

local function setPhase(nextPhase: Types.Phase, bumpCycle: boolean?)
	if phase == "Won" and nextPhase ~= "Won" then
		-- Win is sticky until explicit session reset (stub: allow restart via startDay).
	end
	phase = nextPhase
	if bumpCycle then
		cycleIndex += 1
	end
	applyLighting(nextPhase)
	if hooks and hooks.OnPhaseChanged then
		hooks.OnPhaseChanged(nextPhase, cycleIndex)
	end
	broadcast(nil)
end

local function scheduleDayTimer()
	dayToken += 1
	local token = dayToken
	task.delay(GameConfig.DayDurationSeconds, function()
		if token ~= dayToken then
			return
		end
		if phase ~= "Day" then
			return
		end
		-- Night always arrives; quizzes are not a hard gate (locked).
		PhaseController.StartNight()
	end)
end

function PhaseController.BindRemotes(remoteApi)
	remotes = remoteApi
end

function PhaseController.SetHooks(h: Hooks)
	hooks = h
end

function PhaseController.StartDay(options: { bumpCycle: boolean?, reason: string? }?)
	local bump = options and options.bumpCycle == true
	setPhase("Day", bump)
	scheduleDayTimer()
end

function PhaseController.StartNight()
	if phase == "Won" then
		return
	end
	setPhase("Night", false)
end

-- Dog catch: back to cage and wait for next day — no same-night re-escape (locked).
function PhaseController.OnDogCatch()
	if phase ~= "Night" then
		return
	end
	dayToken += 1 -- cancel pending day timer if any
	if remotes then
		for _, player in Players:GetPlayers() do
			remotes.CatchFeedback:FireClient(player, "DogCatch")
		end
	end
	task.delay(GameConfig.CatchToDayDelaySeconds, function()
		if phase == "Won" then
			return
		end
		PhaseController.StartDay({ bumpCycle = true, reason = "DogCatch" })
	end)
end

function PhaseController.OnPhoneWin()
	if phase ~= "Night" then
		return
	end
	dayToken += 1
	setPhase("Won", false)
	if remotes then
		remotes.WinFeedback:FireAllClients()
	end
end

function PhaseController.NotifyPlayerJoined(player: Player)
	broadcast(player)
end

return PhaseController
