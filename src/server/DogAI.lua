-- Dog patrol / chase. Catch → CageService return + PhaseController.OnDogCatch
-- (next day; no same-night re-escape). Detect range modified by QuietPaws.
-- Visual: POLYGON Dog Pack stand-in (friendly Labrador-ish blockout).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ArtPalette = require(ReplicatedStorage.Shared.ArtPalette)

local LevelSetup = require(script.Parent.LevelSetup)
local PhaseController = require(script.Parent.PhaseController)
local CageService = require(script.Parent.CageService)
local BuffService = require(script.Parent.BuffService)

local DogAI = {}

local dogRoot: BasePart? = nil
local dogModel: Model? = nil
local connection: RBXScriptConnection? = nil
local patrolTarget: Vector3? = nil
local chasePlayer: Player? = nil
local catchLock = false

local function parentFolder(): Instance
	return Workspace:FindFirstChild("Classroom") or Workspace
end

local function ensureDogModel(): BasePart
	if dogRoot and dogRoot.Parent and dogModel and dogModel.Parent then
		return dogRoot
	end

	local spawn = LevelSetup.GetFirstTagged(GameConfig.Tags.DogSpawn)
	local origin = if spawn and spawn:IsA("BasePart") then spawn.CFrame else CFrame.new(8, 1.5, 12)
	-- Sit body on floor (Y≈1.2 for lab-sized placeholder)
	origin = CFrame.new(origin.Position.X, 1.35, origin.Position.Z)

	local model = Instance.new("Model")
	model.Name = "ClassDog"

	local P = ArtPalette
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.2, 1.4, 3.4)
	body.Color = P.DogFur
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = origin
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.3, 1.2, 1.3)
	head.Color = P.DogFur
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = origin * CFrame.new(0, 0.55, -1.9)
	head.Parent = model

	local snout = Instance.new("Part")
	snout.Name = "Snout"
	snout.Size = Vector3.new(0.7, 0.55, 0.7)
	snout.Color = P.DogFurDark
	snout.Material = Enum.Material.SmoothPlastic
	snout.Anchored = true
	snout.CanCollide = false
	snout.CFrame = origin * CFrame.new(0, 0.35, -2.55)
	snout.Parent = model

	local nose = Instance.new("Part")
	nose.Name = "Nose"
	nose.Shape = Enum.PartType.Ball
	nose.Size = Vector3.new(0.35, 0.35, 0.35)
	nose.Color = P.DogNose
	nose.Material = Enum.Material.SmoothPlastic
	nose.Anchored = true
	nose.CanCollide = false
	nose.CFrame = origin * CFrame.new(0, 0.4, -2.9)
	nose.Parent = model

	local collar = Instance.new("Part")
	collar.Name = "Collar"
	collar.Size = Vector3.new(1.45, 0.25, 1.45)
	collar.Color = P.DogCollar
	collar.Material = Enum.Material.Neon
	collar.Anchored = true
	collar.CanCollide = false
	collar.CFrame = origin * CFrame.new(0, 0.35, -1.35)
	collar.Parent = model

	local earL = Instance.new("Part")
	earL.Name = "EarL"
	earL.Size = Vector3.new(0.35, 0.7, 0.2)
	earL.Color = P.DogFurDark
	earL.Anchored = true
	earL.CanCollide = false
	earL.CFrame = origin * CFrame.new(-0.45, 1.2, -1.7)
	earL.Parent = model

	local earR = earL:Clone()
	earR.Name = "EarR"
	earR.CFrame = origin * CFrame.new(0.45, 1.2, -1.7)
	earR.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Name = "DogLabel"
	tag.Size = UDim2.fromOffset(120, 28)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	label.TextColor3 = Color3.fromRGB(255, 245, 230)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = "Class dog"
	label.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	model.PrimaryPart = body
	model.Parent = parentFolder()

	dogModel = model
	dogRoot = body
	return body
end

local function syncDogParts(rootCf: CFrame)
	local model = dogModel
	if not model then
		return
	end
	local map = {
		Body = CFrame.new(),
		Head = CFrame.new(0, 0.55, -1.9),
		Snout = CFrame.new(0, 0.35, -2.55),
		Nose = CFrame.new(0, 0.4, -2.9),
		Collar = CFrame.new(0, 0.35, -1.35),
		EarL = CFrame.new(-0.45, 1.2, -1.7),
		EarR = CFrame.new(0.45, 1.2, -1.7),
	}
	for name, offset in map do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CFrame = rootCf * offset
		end
	end
end

local function setDogCFrame(pos: Vector3, lookFlat: Vector3?)
	local body = ensureDogModel()
	local y = 1.35
	local at = Vector3.new(pos.X, y, pos.Z)
	local cf: CFrame
	if lookFlat and lookFlat.Magnitude > 0.05 then
		local look = Vector3.new(lookFlat.X, 0, lookFlat.Z).Unit
		cf = CFrame.lookAt(at, at + look)
	else
		cf = CFrame.new(at) * (body.CFrame - body.CFrame.Position)
	end
	body.CFrame = cf
	syncDogParts(cf)
end

local function pickPatrolPoint(from: Vector3): Vector3
	local offset = Vector3.new(math.random(-22, 22), 0, math.random(-18, 18))
	return Vector3.new(from.X, 1.35, from.Z) + offset
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

local function setDogVisible(night: boolean)
	local model = dogModel
	if not model then
		return
	end
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			if night then
				child.Transparency = 0
			else
				-- Day: parked / quieter — still readable silhouette
				child.Transparency = if child.Name == "Collar" then 0.2 else 0.45
			end
		end
	end
	local body = model:FindFirstChild("Body")
	local tag = body and body:FindFirstChild("DogLabel")
	if tag and tag:IsA("BillboardGui") then
		tag.Enabled = night
	end
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
			setDogCFrame(pos + stepVec, delta)
		end
	end
end

function DogAI.OnNightStarted()
	catchLock = false
	chasePlayer = nil
	local spawn = LevelSetup.GetFirstTagged(GameConfig.Tags.DogSpawn)
	local pos = if spawn and spawn:IsA("BasePart") then spawn.Position else Vector3.new(8, 1.35, 12)
	setDogCFrame(pos, Vector3.new(-1, 0, 0))
	setDogVisible(true)
	patrolTarget = pickPatrolPoint(pos)
end

function DogAI.OnDayStarted()
	chasePlayer = nil
	ensureDogModel()
	setDogVisible(false)
end

function DogAI.Start()
	ensureDogModel()
	setDogVisible(false)
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
