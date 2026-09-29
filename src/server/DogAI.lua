-- Dog patrol / chase stub. Catch → CageService return + PhaseController.OnDogCatch
-- (next day; no same-night re-escape). Detect range modified by QuietPaws.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local LevelSetup = require(script.Parent.LevelSetup)
local PhaseController = require(script.Parent.PhaseController)
local CageService = require(script.Parent.CageService)
local BuffService = require(script.Parent.BuffService)

local DogAI = {}

local dog: BasePart? = nil
local connection: RBXScriptConnection? = nil
local patrolTarget: Vector3? = nil
local chasePlayer: Player? = nil
local catchLock = false

local function ensureDogModel(): BasePart
	if dog and dog.Parent then
		return dog
	end
	local spawn = LevelSetup.GetFirstTagged(GameConfig.Tags.DogSpawn)
	local origin = if spawn and spawn:IsA("BasePart") then spawn.CFrame else CFrame.new(10, 2.5, 10)

	local part = Instance.new("Part")
	part.Name = "ClassDog"
	part.Size = Vector3.new(4, 3, 6)
	part.Color = Color3.fromRGB(140, 100, 60)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = origin
	part.Parent = Workspace:FindFirstChild("Classroom") or Workspace
	dog = part
	return part
end

local function pickPatrolPoint(from: Vector3): Vector3
	local offset = Vector3.new(
		math.random(-25, 25),
		0,
		math.random(-20, 20)
	)
	return Vector3.new(from.X, 2.5, from.Z) + offset
end

local function nearestEscapedPlayer(dogPos: Vector3): (Player?, number)
	local best: Player? = nil
	local bestDist = math.huge
	for _, player in Players:GetPlayers() do
		if not CageService.HasEscapedThisNight(player) then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local dist = (root.Position - dogPos).Magnitude
		local mult = BuffService.GetDetectRangeMultiplier(player)
		local detect = GameConfig.DogDetectRange * mult
		if dist <= detect and dist < bestDist then
			best = player
			bestDist = dist
		end
	end
	return best, bestDist
end

local function performCatch(player: Player)
	if catchLock then
		return
	end
	if not PhaseController.IsNight() then
		return
	end
	-- LessonLeftover grace: cancel one catch per night.
	if BuffService.TryConsumeGrace(player) then
		chasePlayer = nil
		return
	end

	catchLock = true
	chasePlayer = nil
	CageService.ReturnToCage(player)
	PhaseController.OnDogCatch()
	task.delay(GameConfig.CatchToDayDelaySeconds + 0.5, function()
		catchLock = false
	end)
end

local function step(dt: number)
	if not PhaseController.IsNight() or PhaseController.HasWon() then
		return
	end
	local body = ensureDogModel()
	local pos = body.Position

	local targetPlayer = chasePlayer
	if not targetPlayer or not CageService.HasEscapedThisNight(targetPlayer) then
		local found = nearestEscapedPlayer(pos)
		targetPlayer = found
		chasePlayer = found
	end

	local speed = GameConfig.DogPatrolSpeed
	local goal = patrolTarget

	if targetPlayer then
		local character = targetPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			speed = GameConfig.DogChaseSpeed
			goal = root.Position
			if (root.Position - pos).Magnitude <= GameConfig.DogCatchRange then
				performCatch(targetPlayer)
				return
			end
		else
			chasePlayer = nil
		end
	end

	if not goal or (goal - pos).Magnitude < 2 then
		patrolTarget = pickPatrolPoint(pos)
		goal = patrolTarget
	end

	if goal then
		local flatGoal = Vector3.new(goal.X, pos.Y, goal.Z)
		local delta = flatGoal - pos
		if delta.Magnitude > 0.1 then
			local stepVec = delta.Unit * math.min(delta.Magnitude, speed * dt)
			body.CFrame = CFrame.new(pos + stepVec)
		end
	end
end

function DogAI.OnNightStarted()
	catchLock = false
	chasePlayer = nil
	local body = ensureDogModel()
	local spawn = LevelSetup.GetFirstTagged(GameConfig.Tags.DogSpawn)
	if spawn and spawn:IsA("BasePart") then
		body.CFrame = spawn.CFrame
	end
	body.Transparency = 0
	patrolTarget = pickPatrolPoint(body.Position)
end

function DogAI.OnDayStarted()
	chasePlayer = nil
	if dog then
		-- Park/hide dog during day (still in classroom story-wise, but inactive).
		dog.Transparency = 0.5
	end
end

function DogAI.Start()
	ensureDogModel()
	if connection then
		return
	end
	connection = RunService.Heartbeat:Connect(function(dt)
		step(dt)
	end)
end

function DogAI.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return DogAI
