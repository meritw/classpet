-- Ensures tagged placeholder parts exist so the loop can run without a hand-built place.
-- Studio authors can replace these with real classroom geometry; tags stay the contract.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local LevelSetup = {}

local function ensureFolder(): Folder
	local classroom = Workspace:FindFirstChild("Classroom")
	if classroom and classroom:IsA("Folder") then
		return classroom
	end
	local folder = Instance.new("Folder")
	folder.Name = "Classroom"
	folder.Parent = Workspace
	return folder
end

local function ensureTaggedPart(parent: Instance, name: string, tag: string, size: Vector3, cframe: CFrame, color: Color3): BasePart
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		if not CollectionService:HasTag(existing, tag) then
			CollectionService:AddTag(existing, tag)
		end
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	CollectionService:AddTag(part, tag)
	return part
end

function LevelSetup.EnsurePlaceholders()
	local classroom = ensureFolder()
	local tags = GameConfig.Tags

	-- Floor slab for orientation (not tagged gameplay).
	if not classroom:FindFirstChild("Floor") then
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(80, 1, 60)
		floor.CFrame = CFrame.new(0, 0, 0)
		floor.Anchored = true
		floor.CanCollide = true
		floor.Color = Color3.fromRGB(210, 190, 160)
		floor.Material = Enum.Material.WoodPlanks
		floor.Parent = classroom
	end

	-- Cage volume (axis-aligned region for day containment).
	local cage = ensureTaggedPart(
		classroom,
		"CageVolume",
		tags.CageVolume,
		Vector3.new(10, 6, 8),
		CFrame.new(-28, 3.5, 0),
		Color3.fromRGB(180, 180, 200)
	)
	cage.Transparency = 0.6
	cage.CanCollide = false

	ensureTaggedPart(
		classroom,
		"Latch",
		tags.Latch,
		Vector3.new(1.5, 1.5, 1.5),
		CFrame.new(-23, 2, 0),
		Color3.fromRGB(120, 90, 40)
	)

	ensureTaggedPart(
		classroom,
		"LessonSpot",
		tags.LessonSpot,
		Vector3.new(2, 1, 2),
		CFrame.new(-28, 1.5, 2),
		Color3.fromRGB(90, 140, 200)
	)

	ensureTaggedPart(
		classroom,
		"Phone",
		tags.Phone,
		Vector3.new(2, 1.2, 2),
		CFrame.new(30, 2, -18),
		Color3.fromRGB(40, 40, 40)
	)

	ensureTaggedPart(
		classroom,
		"DogSpawn",
		tags.DogSpawn,
		Vector3.new(3, 3, 3),
		CFrame.new(10, 2.5, 10),
		Color3.fromRGB(160, 110, 70)
	)

	-- Optional hide spots for night route teaching.
	ensureTaggedPart(
		classroom,
		"HideSpot_A",
		tags.HideSpot,
		Vector3.new(4, 2, 3),
		CFrame.new(-5, 1.5, -8),
		Color3.fromRGB(100, 100, 100)
	)
	ensureTaggedPart(
		classroom,
		"HideSpot_B",
		tags.HideSpot,
		Vector3.new(4, 2, 3),
		CFrame.new(15, 1.5, 0),
		Color3.fromRGB(100, 100, 100)
	)

	return classroom
end

function LevelSetup.GetFirstTagged(tag: string): Instance?
	local tagged = CollectionService:GetTagged(tag)
	return tagged[1]
end

function LevelSetup.GetCageRespawnCFrame(): CFrame
	local cage = LevelSetup.GetFirstTagged(GameConfig.Tags.CageVolume)
	if cage and cage:IsA("BasePart") then
		return cage.CFrame + GameConfig.CageRespawnOffset
	end
	return CFrame.new(-28, 3, 0)
end

function LevelSetup.IsPointInsideCage(worldPos: Vector3): boolean
	local cage = LevelSetup.GetFirstTagged(GameConfig.Tags.CageVolume)
	if not cage or not cage:IsA("BasePart") then
		return true -- fail-safe: treat as inside if marker missing
	end
	local localPos = cage.CFrame:PointToObjectSpace(worldPos)
	local half = cage.Size * 0.5
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

return LevelSetup
