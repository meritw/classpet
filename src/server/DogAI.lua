-- Dog patrol / chase. Catch → CageService return + PhaseController.OnDogCatch
-- (next day; no same-night re-escape). Detect range modified by QuietPaws.
-- Visual: POLYGON Dog Pack stand-in (friendly Labrador-ish Parts silhouette).

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

-- Local offsets from Body (PrimaryPart). Keep in sync with ensureDogModel.
local PART_OFFSETS: { [string]: CFrame } = {
	Body = CFrame.new(),
	Chest = CFrame.new(0, -0.05, -0.85),
	Belly = CFrame.new(0, -0.55, 0.15),
	Head = CFrame.new(0, 0.65, -2.05),
	Snout = CFrame.new(0, 0.4, -2.7),
	Nose = CFrame.new(0, 0.42, -3.05),
	Jaw = CFrame.new(0, 0.15, -2.55),
	EyeL = CFrame.new(-0.35, 0.8, -2.35),
	EyeR = CFrame.new(0.35, 0.8, -2.35),
	EarL = CFrame.new(-0.55, 1.25, -1.85) * CFrame.Angles(0, 0, math.rad(18)),
	EarR = CFrame.new(0.55, 1.25, -1.85) * CFrame.Angles(0, 0, math.rad(-18)),
	Collar = CFrame.new(0, 0.4, -1.45),
	Neck = CFrame.new(0, 0.35, -1.55),
	Tail = CFrame.new(0, 0.35, 1.95) * CFrame.Angles(math.rad(25), 0, 0),
	TailTip = CFrame.new(0, 0.7, 2.55) * CFrame.Angles(math.rad(40), 0, 0),
	LegFL = CFrame.new(-0.65, -1.05, -1.0),
	LegFR = CFrame.new(0.65, -1.05, -1.0),
	LegBL = CFrame.new(-0.7, -1.05, 1.05),
	LegBR = CFrame.new(0.7, -1.05, 1.05),
	PawFL = CFrame.new(-0.65, -1.55, -1.15),
	PawFR = CFrame.new(0.65, -1.55, -1.15),
	PawBL = CFrame.new(-0.7, -1.55, 1.2),
	PawBR = CFrame.new(0.7, -1.55, 1.2),
}

local function parentFolder(): Instance
	return Workspace:FindFirstChild("Classroom") or Workspace
end

local function makePart(
	model: Model,
	name: string,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = true
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

local function ensureDogModel(): BasePart
	if dogRoot and dogRoot.Parent and dogModel and dogModel.Parent then
		return dogRoot
	end

	local spawn = LevelSetup.GetFirstTagged(GameConfig.Tags.DogSpawn)
	local origin = if spawn and spawn:IsA("BasePart") then spawn.CFrame else CFrame.new(8, 1.5, 12)
	-- Sit body on floor (Y≈1.55 for lab-sized placeholder with legs)
	origin = CFrame.new(origin.Position.X, 1.55, origin.Position.Z)

	local model = Instance.new("Model")
	model.Name = "ClassDog"

	local P = ArtPalette
	local body = makePart(model, "Body", Vector3.new(1.9, 1.35, 2.8), P.DogFur)
	body.CFrame = origin

	makePart(model, "Chest", Vector3.new(2.05, 1.45, 1.4), P.DogFur)
	makePart(model, "Belly", Vector3.new(1.5, 0.55, 2.2), P.DogFurLight)
	makePart(model, "Neck", Vector3.new(1.1, 0.9, 0.9), P.DogFur, Enum.PartType.Ball)
	makePart(model, "Head", Vector3.new(1.35, 1.25, 1.35), P.DogFur, Enum.PartType.Ball)
	makePart(model, "Snout", Vector3.new(0.75, 0.55, 0.85), P.DogFurLight)
	makePart(model, "Jaw", Vector3.new(0.65, 0.3, 0.55), P.DogFurDark)
	makePart(model, "Nose", Vector3.new(0.32, 0.28, 0.28), P.DogNose, Enum.PartType.Ball)
	makePart(model, "EyeL", Vector3.new(0.22, 0.22, 0.18), P.DogEye, Enum.PartType.Ball)
	makePart(model, "EyeR", Vector3.new(0.22, 0.22, 0.18), P.DogEye, Enum.PartType.Ball)
	makePart(model, "EarL", Vector3.new(0.4, 0.85, 0.25), P.DogFurDark)
	makePart(model, "EarR", Vector3.new(0.4, 0.85, 0.25), P.DogFurDark)

	local collar = makePart(model, "Collar", Vector3.new(1.5, 0.28, 1.5), P.DogCollar)
	collar.Material = Enum.Material.Neon

	makePart(model, "Tail", Vector3.new(0.35, 0.35, 1.1), P.DogFurDark)
	makePart(model, "TailTip", Vector3.new(0.3, 0.3, 0.7), P.DogFur)

	-- Legs + paws
	for _, name in { "LegFL", "LegFR", "LegBL", "LegBR" } do
		makePart(model, name, Vector3.new(0.45, 1.1, 0.5), P.DogFurDark)
	end
	for _, name in { "PawFL", "PawFR", "PawBL", "PawBR" } do
		makePart(model, name, Vector3.new(0.5, 0.28, 0.65), P.DogPaw)
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "DogLabel"
	tag.Size = UDim2.fromOffset(120, 28)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
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
	for name, offset in PART_OFFSETS do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CFrame = rootCf * offset
		end
	end
end

local function setDogCFrame(pos: Vector3, lookFlat: Vector3?)
	local body = ensureDogModel()
	local y = 1.55
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
	return Vector3.new(from.X, 1.55, from.Z) + offset
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
				child.Transparency = if child.Name == "Collar" then 0.15 else 0.4
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
	local pos = if spawn and spawn:IsA("BasePart") then spawn.Position else Vector3.new(8, 1.55, 12)
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
