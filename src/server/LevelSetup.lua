-- Ensures tagged placeholder parts exist so the loop can run without a hand-built place.
-- Studio authors can replace these with real classroom geometry; tags stay the contract.
-- Player fantasy: tiny hamster in a desk-pet cage; classroom props stay human scale.

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

-- Sync Size/CFrame for scaffold placeholders so playtests pick up scale fixes.
-- Custom authored replacements should use different names or clear ClassPetPlaceholder.
local function ensureTaggedPart(parent: Instance, name: string, tag: string, size: Vector3, cframe: CFrame, color: Color3): BasePart
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		if not CollectionService:HasTag(existing, tag) then
			CollectionService:AddTag(existing, tag)
		end
		if existing:GetAttribute("ClassPetPlaceholder") ~= false then
			existing.Size = size
			existing.CFrame = cframe
			existing:SetAttribute("ClassPetPlaceholder", true)
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
	part:SetAttribute("ClassPetPlaceholder", true)
	part.Parent = parent
	CollectionService:AddTag(part, tag)
	return part
end

local function ensureUntaggedPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): BasePart
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		if existing:GetAttribute("ClassPetPlaceholder") ~= false then
			existing.Size = size
			existing.CFrame = cframe
			existing:SetAttribute("ClassPetPlaceholder", true)
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
	part.Material = material
	part:SetAttribute("ClassPetPlaceholder", true)
	part.Parent = parent
	return part
end

function LevelSetup.EnsurePlaceholders()
	local classroom = ensureFolder()
	local tags = GameConfig.Tags
	local cageSize = GameConfig.CageSize
	local cageCenter = GameConfig.CageCenter

	-- Floor slab for orientation (not tagged gameplay). Human classroom scale.
	ensureUntaggedPart(
		classroom,
		"Floor",
		Vector3.new(80, 1, 60),
		CFrame.new(0, 0, 0),
		Color3.fromRGB(210, 190, 160),
		Enum.Material.WoodPlanks
	)

	-- Desk the cage sits on (human/classroom scale — hamster is tiny on top at night).
	local deskTopY = cageCenter.Y - cageSize.Y * 0.5
	local deskHeight = deskTopY - 0.5 -- floor top ≈ 0.5
	ensureUntaggedPart(
		classroom,
		"HamsterDesk",
		Vector3.new(6, deskHeight, 4.5),
		CFrame.new(cageCenter.X, 0.5 + deskHeight * 0.5, cageCenter.Z),
		Color3.fromRGB(140, 100, 60),
		Enum.Material.Wood
	)

	-- Cage volume (axis-aligned region for day containment) — desk-pet enclosure.
	local cage = ensureTaggedPart(
		classroom,
		"CageVolume",
		tags.CageVolume,
		cageSize,
		CFrame.new(cageCenter),
		Color3.fromRGB(180, 180, 200)
	)
	cage.Transparency = 0.55
	cage.CanCollide = false

	-- Latch on the +X face of the cage (door toward the classroom).
	local latchPos = Vector3.new(
		cageCenter.X + cageSize.X * 0.5,
		deskTopY + 0.7,
		cageCenter.Z
	)
	ensureTaggedPart(
		classroom,
		"Latch",
		tags.Latch,
		Vector3.new(0.35, 0.35, 0.25),
		CFrame.new(latchPos),
		Color3.fromRGB(120, 90, 40)
	)

	-- Lesson pad inside the cage (hamster must stand on it).
	ensureTaggedPart(
		classroom,
		"LessonSpot",
		tags.LessonSpot,
		Vector3.new(0.7, 0.12, 0.7),
		CFrame.new(cageCenter.X, deskTopY + 0.06, cageCenter.Z + 0.6),
		Color3.fromRGB(90, 140, 200)
	)

	-- Phone / dog / hide spots stay human classroom scale.
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
	return CFrame.new(GameConfig.CageCenter + GameConfig.CageRespawnOffset)
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
