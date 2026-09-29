-- Server-owned buff charges earned during Day, consumed/applied during Night.
-- Client never grants or invents buffs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BuffDefs = require(ReplicatedStorage.Shared.BuffDefs)

local BuffService = {}

type PlayerBuffState = {
	charges: { [Types.BuffId]: number },
	correctAnswersToday: number,
	graceUsedThisNight: boolean,
}

local buffState: { [Player]: PlayerBuffState } = {}

local function ensure(player: Player): PlayerBuffState
	local s = buffState[player]
	if not s then
		s = {
			charges = {
				QuietPaws = 0,
				SugarDash = 0,
				LessonLeftover = 0,
			},
			correctAnswersToday = 0,
			graceUsedThisNight = false,
		}
		buffState[player] = s
	end
	return s
end

function BuffService.InitPlayer(player: Player)
	ensure(player)
end

function BuffService.ClearPlayer(player: Player)
	buffState[player] = nil
end

function BuffService.ResetForNewDay(player: Player)
	local s = ensure(player)
	-- Day-earned buffs refresh each day (design: re-earn for upcoming night).
	s.charges = {
		QuietPaws = 0,
		SugarDash = 0,
		LessonLeftover = 0,
	}
	s.correctAnswersToday = 0
	s.graceUsedThisNight = false
end

function BuffService.OnNightStarted(player: Player)
	local s = ensure(player)
	s.graceUsedThisNight = false
end

function BuffService.Grant(player: Player, buffId: Types.BuffId, amount: number?): boolean
	if not BuffDefs[buffId] then
		return false
	end
	local s = ensure(player)
	local add = amount or 1
	local current = s.charges[buffId] or 0
	if current >= GameConfig.MaxBuffChargesPerDay then
		return false
	end
	s.charges[buffId] = math.min(GameConfig.MaxBuffChargesPerDay, current + add)
	return true
end

function BuffService.RecordCorrectAnswer(player: Player, buffId: Types.BuffId)
	local s = ensure(player)
	s.correctAnswersToday += 1
	BuffService.Grant(player, buffId, 1)
	-- LessonLeftover proposal: N correct in one day → one grace charge.
	if s.correctAnswersToday >= 3 and (s.charges.LessonLeftover or 0) < 1 then
		BuffService.Grant(player, "LessonLeftover", 1)
	end
end

function BuffService.Has(player: Player, buffId: Types.BuffId): boolean
	local s = ensure(player)
	return (s.charges[buffId] or 0) > 0
end

function BuffService.Consume(player: Player, buffId: Types.BuffId): boolean
	local s = ensure(player)
	local n = s.charges[buffId] or 0
	if n <= 0 then
		return false
	end
	s.charges[buffId] = n - 1
	return true
end

function BuffService.GetDetectRangeMultiplier(player: Player): number
	if BuffService.Has(player, "QuietPaws") then
		return GameConfig.DogQuietPawsDetectMultiplier
	end
	return 1
end

-- Returns true if catch should be cancelled (grace consumed).
function BuffService.TryConsumeGrace(player: Player): boolean
	local s = ensure(player)
	if s.graceUsedThisNight then
		return false
	end
	if not BuffService.Consume(player, "LessonLeftover") then
		return false
	end
	s.graceUsedThisNight = true
	return true
end

function BuffService.GetSnapshot(player: Player): { Types.BuffCharge }
	local s = ensure(player)
	local list: { Types.BuffCharge } = {}
	for id, charges in s.charges do
		if charges > 0 then
			table.insert(list, { id = id, charges = charges })
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

return BuffService
