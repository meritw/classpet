-- Ensures tagged placeholder parts exist so the loop can run without a hand-built place.
-- Studio authors can replace these with real classroom geometry; tags stay the contract.
-- Player fantasy: tiny hamster in a desk-pet cage; classroom props stay human scale.
--
-- Scale contract (do not fight — from hamster-scale PR):
--   GameConfig.CageSize / CageCenter / HamsterDesk / HamsterScale
-- Visual pass adds POLYGON-style shell + custom pet cage dressing around those sizes.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ArtPalette = require(ReplicatedStorage.Shared.ArtPalette)

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

local function ensureModel(parent: Instance, name: string): Model
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
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
			existing.Color = color
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

local function ensurePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	opts: { canCollide: boolean?, transparency: number?, shape: Enum.PartType? }?
): BasePart
	local existing = parent:FindFirstChild(name)
	local part: BasePart
	if existing and existing:IsA("BasePart") then
		part = existing
		if part:GetAttribute("ClassPetPlaceholder") == false then
			return part
		end
	else
		if existing then
			existing:Destroy()
		end
		part = Instance.new("Part")
		part.Name = name
		part:SetAttribute("ClassPetPlaceholder", true)
		part.Parent = parent
	end
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = if opts and opts.canCollide ~= nil then opts.canCollide else true
	part.Transparency = if opts and opts.transparency ~= nil then opts.transparency else 0
	part.Color = color
	part.Material = material
	part.CastShadow = true
	if opts and opts.shape then
		part.Shape = opts.shape
	end
	part:SetAttribute("ClassPetPlaceholder", true)
	return part
end

local function ensurePointLight(parent: BasePart, name: string, color: Color3, brightness: number, range: number)
	local light = parent:FindFirstChild(name)
	if not light or not light:IsA("PointLight") then
		if light then
			light:Destroy()
		end
		light = Instance.new("PointLight")
		light.Name = name
		light.Parent = parent
	end
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	return light
end

local function buildClassroomShell(classroom: Folder)
	local shell = ensureModel(classroom, "RoomShell")
	local P = ArtPalette

	-- Floor (human classroom)
	ensurePart(shell, "Floor", Vector3.new(80, 1, 60), CFrame.new(0, 0, 0), P.Floor, Enum.Material.WoodPlanks)

	-- Walls: N(-Z) S(+Z) W(-X) E(+X). Height ~12 studs.
	local wallH = 12
	local wallY = wallH * 0.5 + 0.5
	ensurePart(shell, "Wall_N", Vector3.new(80, wallH, 1), CFrame.new(0, wallY, -30), P.Wall, Enum.Material.SmoothPlastic)
	ensurePart(shell, "Wall_S", Vector3.new(80, wallH, 1), CFrame.new(0, wallY, 30), P.Wall, Enum.Material.SmoothPlastic)
	ensurePart(shell, "Wall_W", Vector3.new(1, wallH, 60), CFrame.new(-40, wallY, 0), P.Wall, Enum.Material.SmoothPlastic)
	ensurePart(shell, "Wall_E", Vector3.new(1, wallH, 60), CFrame.new(40, wallY, 0), P.Wall, Enum.Material.SmoothPlastic)

	-- Bright blue wainscot band (Kids Pack classroom vibe)
	ensurePart(shell, "Wainscot_N", Vector3.new(79.5, 1.2, 0.2), CFrame.new(0, 2.1, -29.4), P.WallAccent, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(shell, "Wainscot_S", Vector3.new(79.5, 1.2, 0.2), CFrame.new(0, 2.1, 29.4), P.WallAccent, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(shell, "Wainscot_W", Vector3.new(0.2, 1.2, 59.5), CFrame.new(-39.4, 2.1, 0), P.WallAccent, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(shell, "Wainscot_E", Vector3.new(0.2, 1.2, 59.5), CFrame.new(39.4, 2.1, 0), P.WallAccent, Enum.Material.SmoothPlastic, { canCollide = false })

	-- Ceiling
	ensurePart(shell, "Ceiling", Vector3.new(80, 1, 60), CFrame.new(0, wallH + 1, 0), P.Ceiling, Enum.Material.SmoothPlastic)

	-- Windows on +X wall (day light reads through)
	for i = 1, 3 do
		local z = -16 + (i - 1) * 16
		ensurePart(shell, `WindowFrame_{i}`, Vector3.new(0.4, 5, 8), CFrame.new(39.6, 6, z), P.WindowFrame, Enum.Material.SmoothPlastic, { canCollide = false })
		local glass = ensurePart(shell, `WindowGlass_{i}`, Vector3.new(0.15, 4.4, 7.2), CFrame.new(39.7, 6, z), P.WindowGlass, Enum.Material.Glass, {
			canCollide = false,
			transparency = 0.45,
		})
		ensurePointLight(glass, "DayWindowGlow", Color3.fromRGB(255, 245, 220), 0.35, 18)
	end

	-- Door on -Z wall
	ensurePart(shell, "DoorFrame", Vector3.new(5, 8, 0.6), CFrame.new(18, 4.5, -29.6), P.DoorFrame, Enum.Material.Wood)
	ensurePart(shell, "Door", Vector3.new(4, 7, 0.35), CFrame.new(18, 4, -29.3), P.Door, Enum.Material.Wood)
	ensurePart(shell, "DoorKnob", Vector3.new(0.25, 0.25, 0.35), CFrame.new(16.4, 4, -29.05), Color3.fromRGB(220, 190, 80), Enum.Material.Metal, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
end

local function buildBoardsAndTeacherZone(classroom: Folder)
	local zone = ensureModel(classroom, "TeacherZone")
	local P = ArtPalette

	-- Whiteboard on -Z wall (Police Station whiteboard stand-in)
	ensurePart(zone, "Whiteboard", Vector3.new(16, 6, 0.35), CFrame.new(-6, 7, -29.2), P.Whiteboard, Enum.Material.SmoothPlastic)
	ensurePart(zone, "WhiteboardFrame", Vector3.new(16.6, 6.5, 0.2), CFrame.new(-6, 7, -29.35), P.WhiteboardFrame, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(zone, "ChalkTray", Vector3.new(16, 0.25, 0.45), CFrame.new(-6, 3.9, -28.9), P.ChalkTray, Enum.Material.SmoothPlastic)

	-- Bulletin board accent
	ensurePart(zone, "BulletinBoard", Vector3.new(6, 4, 0.3), CFrame.new(8, 6.5, -29.2), Color3.fromRGB(255, 230, 140), Enum.Material.Cardboard)

	-- Teacher desk (Office Pack proportion) toward +X / -Z corner
	local deskCf = CFrame.new(28, 2.1, -20)
	ensurePart(zone, "TeacherDesk", Vector3.new(8, 0.4, 4), deskCf, P.TeacherDesk, Enum.Material.Wood)
	ensurePart(zone, "TeacherDeskLeg_L", Vector3.new(0.4, 3.2, 0.4), CFrame.new(25, 1.6, -21.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_R", Vector3.new(0.4, 3.2, 0.4), CFrame.new(31, 1.6, -18.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_L2", Vector3.new(0.4, 3.2, 0.4), CFrame.new(25, 1.6, -18.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_R2", Vector3.new(0.4, 3.2, 0.4), CFrame.new(31, 1.6, -21.5), P.DeskLeg, Enum.Material.Metal)

	-- Desk phone on teacher desk (Police Station phone stand-in) — tagged Phone
	local phone = ensureTaggedPart(
		classroom,
		"Phone",
		GameConfig.Tags.Phone,
		Vector3.new(1.2, 0.45, 0.9),
		CFrame.new(30, 2.55, -19.2),
		P.PhoneBody
	)
	phone.Material = Enum.Material.SmoothPlastic
	-- Handset + ready light as sibling decorations (not the tagged interactable)
	local phoneProp = ensureModel(classroom, "PhoneProps")
	ensurePart(phoneProp, "Handset", Vector3.new(0.35, 0.25, 0.9), CFrame.new(29.3, 2.85, -19.2), P.PhoneHandset, Enum.Material.SmoothPlastic, { canCollide = false })
	local ready = ensurePart(phoneProp, "ReadyLight", Vector3.new(0.2, 0.2, 0.2), CFrame.new(30.5, 2.85, -18.9), P.PhoneAccent, Enum.Material.Neon, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
	ensurePointLight(ready, "PhoneGlow", P.PhoneAccent, 1.2, 10)
end

local function buildStudentDesks(classroom: Folder)
	local props = ensureModel(classroom, "StudentDesks")
	local P = ArtPalette
	-- 3x3 grid of desks — Kids Pack school furniture proportions
	local startX, startZ = -12, -8
	local i = 0
	for row = 0, 2 do
		for col = 0, 2 do
			i += 1
			local x = startX + col * 8
			local z = startZ + row * 8
			ensurePart(props, `StudentDesk_{i}`, Vector3.new(3.5, 0.3, 2.2), CFrame.new(x, 2.35, z), P.DeskTop, Enum.Material.Wood)
			ensurePart(props, `StudentDeskLeg_{i}`, Vector3.new(0.25, 2.1, 0.25), CFrame.new(x, 1.2, z), P.DeskLeg, Enum.Material.Metal)
			ensurePart(props, `StudentChair_{i}`, Vector3.new(1.6, 0.25, 1.6), CFrame.new(x, 1.55, z + 1.6), P.ChairSeat, Enum.Material.SmoothPlastic)
			ensurePart(props, `StudentChairBack_{i}`, Vector3.new(1.6, 1.4, 0.2), CFrame.new(x, 2.3, z + 2.3), P.ChairBack, Enum.Material.SmoothPlastic, { canCollide = false })
		end
	end

	-- Hide spots under / behind desks (human scale for night routes)
	ensureTaggedPart(
		classroom,
		"HideSpot_A",
		GameConfig.Tags.HideSpot,
		Vector3.new(3.2, 1.6, 2.4),
		CFrame.new(-5, 1.3, -8),
		ArtPalette.HideCloth
	).Transparency = 0.35
	ensureTaggedPart(
		classroom,
		"HideSpot_B",
		GameConfig.Tags.HideSpot,
		Vector3.new(3.2, 1.6, 2.4),
		CFrame.new(15, 1.3, 0),
		ArtPalette.HideCloth
	).Transparency = 0.35

	-- Backpack clutter (Kids Pack vibe)
	ensurePart(props, "Backpack_A", Vector3.new(1.2, 1.4, 0.8), CFrame.new(-4, 1.2, -10), P.Backpack, Enum.Material.Fabric, { canCollide = false })
	ensurePart(props, "Backpack_B", Vector3.new(1.2, 1.4, 0.8), CFrame.new(12, 1.2, 2), Color3.fromRGB(60, 120, 200), Enum.Material.Fabric, { canCollide = false })
end

local function buildPetCage(classroom: Folder)
	-- Custom cage dressing around GameConfig cage sizes (no Synty hamster cage).
	local cageSize = GameConfig.CageSize
	local cageCenter = GameConfig.CageCenter
	local deskTopY = cageCenter.Y - cageSize.Y * 0.5
	local P = ArtPalette
	local tags = GameConfig.Tags

	-- Desk the cage sits on (human/classroom scale — sizes from hamster-scale PR).
	local deskHeight = deskTopY - 0.5 -- floor top ≈ 0.5
	ensurePart(
		classroom,
		"HamsterDesk",
		Vector3.new(6, deskHeight, 4.5),
		CFrame.new(cageCenter.X, 0.5 + deskHeight * 0.5, cageCenter.Z),
		Color3.fromRGB(140, 100, 60),
		Enum.Material.Wood
	)

	-- Transparent gameplay volume — keep exact CageSize/CageCenter.
	local cage = ensureTaggedPart(
		classroom,
		"CageVolume",
		tags.CageVolume,
		cageSize,
		CFrame.new(cageCenter),
		Color3.fromRGB(180, 180, 200)
	)
	cage.Transparency = 0.85
	cage.CanCollide = false
	cage.Material = Enum.Material.ForceField

	local visual = ensureModel(classroom, "PetCageVisual")
	local halfX = cageSize.X * 0.5
	local halfY = cageSize.Y * 0.5
	local halfZ = cageSize.Z * 0.5

	-- Plastic tray / base
	ensurePart(
		visual,
		"CageTray",
		Vector3.new(cageSize.X + 0.3, 0.25, cageSize.Z + 0.3),
		CFrame.new(cageCenter.X, deskTopY + 0.05, cageCenter.Z),
		P.CageTray,
		Enum.Material.SmoothPlastic
	)
	ensurePart(
		visual,
		"Bedding",
		Vector3.new(cageSize.X - 0.2, 0.08, cageSize.Z - 0.2),
		CFrame.new(cageCenter.X, deskTopY + 0.2, cageCenter.Z),
		P.Bedding,
		Enum.Material.Sand,
		{ canCollide = false }
	)

	-- Plastic rim / top frame
	ensurePart(
		visual,
		"CageRim",
		Vector3.new(cageSize.X + 0.2, 0.2, cageSize.Z + 0.2),
		CFrame.new(cageCenter.X, cageCenter.Y + halfY - 0.05, cageCenter.Z),
		P.CagePlastic,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)

	-- Wire bars on long sides (±Z) and back (−X). Front (+X) is the door/latch face — sparser.
	local barThick = 0.08
	local barH = cageSize.Y - 0.35
	local barY = deskTopY + 0.2 + barH * 0.5
	local barIndex = 0
	local function bar(name: string, size: Vector3, cf: CFrame)
		barIndex += 1
		ensurePart(visual, name, size, cf, P.CageWire, Enum.Material.Metal, { canCollide = false })
	end
	for i = -2, 2 do
		local z = cageCenter.Z + i * (cageSize.Z / 5)
		bar(`Wire_N_{i + 3}`, Vector3.new(barThick, barH, barThick), CFrame.new(cageCenter.X - halfX + 0.05, barY, z))
		bar(`Wire_S_{i + 3}`, Vector3.new(barThick, barH, barThick), CFrame.new(cageCenter.X + halfX - 0.05, barY, z))
	end
	for i = -3, 3 do
		local x = cageCenter.X + i * (cageSize.X / 7)
		bar(`Wire_Back_{i + 4}`, Vector3.new(barThick, barH, barThick), CFrame.new(x, barY, cageCenter.Z - halfZ + 0.05))
	end
	-- Door-face verticals (sparse — “latch that doesn’t latch”)
	for i = -1, 1 do
		local z = cageCenter.Z + i * (cageSize.Z / 3)
		bar(`Wire_Door_{i + 2}`, Vector3.new(barThick, barH, barThick), CFrame.new(cageCenter.X + halfX - 0.02, barY, z))
	end

	-- Corner posts (plastic)
	for _, ox in { -1, 1 } do
		for _, oz in { -1, 1 } do
			ensurePart(
				visual,
				`Post_{ox}_{oz}`,
				Vector3.new(0.18, cageSize.Y, 0.18),
				CFrame.new(cageCenter.X + ox * halfX, cageCenter.Y, cageCenter.Z + oz * halfZ),
				P.CagePlastic,
				Enum.Material.SmoothPlastic,
				{ canCollide = false }
			)
		end
	end

	-- Latch on +X face (GameConfig latch position) — green “doesn’t really latch”
	local latchPos = Vector3.new(cageCenter.X + halfX, deskTopY + 0.7, cageCenter.Z)
	local latch = ensureTaggedPart(
		classroom,
		"Latch",
		tags.Latch,
		Vector3.new(0.35, 0.35, 0.25),
		CFrame.new(latchPos),
		P.CageLatch
	)
	latch.Material = Enum.Material.Metal
	ensurePointLight(latch, "LatchHint", P.CageLatch, 0.6, 4)

	-- Lesson pad inside cage
	ensureTaggedPart(
		classroom,
		"LessonSpot",
		tags.LessonSpot,
		Vector3.new(0.7, 0.12, 0.7),
		CFrame.new(cageCenter.X, deskTopY + 0.06, cageCenter.Z + 0.6),
		Color3.fromRGB(90, 140, 200)
	)

	-- Food bowl + wheel hints (simple parts)
	ensurePart(
		visual,
		"FoodBowl",
		Vector3.new(0.55, 0.22, 0.55),
		CFrame.new(cageCenter.X - 1.1, deskTopY + 0.28, cageCenter.Z - 0.7),
		P.FoodBowl,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	-- Wheel: ring + stand on −Z side of cage
	ensurePart(
		visual,
		"WheelRing",
		Vector3.new(1.4, 1.4, 0.12),
		CFrame.new(cageCenter.X + 0.4, deskTopY + 0.95, cageCenter.Z - halfZ + 0.35) * CFrame.Angles(0, 0, math.rad(90)),
		P.Wheel,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	ensurePart(
		visual,
		"WheelHub",
		Vector3.new(0.25, 0.25, 0.2),
		CFrame.new(cageCenter.X + 0.4, deskTopY + 0.95, cageCenter.Z - halfZ + 0.35),
		Color3.fromRGB(255, 200, 220),
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball, canCollide = false }
	)
end

local function buildDogSpawn(classroom: Folder)
	-- DogSpawn marker stays tagged; DogAI builds the readable dog body.
	local spawn = ensureTaggedPart(
		classroom,
		"DogSpawn",
		GameConfig.Tags.DogSpawn,
		Vector3.new(2, 0.2, 2),
		CFrame.new(8, 0.6, 12),
		ArtPalette.DogFur
	)
	spawn.Transparency = 1
	spawn.CanCollide = false
end

local function ensureAtmosphere()
	-- Baseline day look; PhaseController tweaks ClockTime/Brightness/Ambient per phase.
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	if not Lighting:FindFirstChild("ClassPetAtmosphere") then
		local atmo = Instance.new("Atmosphere")
		atmo.Name = "ClassPetAtmosphere"
		atmo.Density = 0.22
		atmo.Offset = 0.1
		atmo.Color = Color3.fromRGB(210, 220, 235)
		atmo.Decay = Color3.fromRGB(140, 150, 170)
		atmo.Glare = 0.1
		atmo.Haze = 0.5
		atmo.Parent = Lighting
	end
	if not Lighting:FindFirstChild("ClassPetColorCorrection") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "ClassPetColorCorrection"
		cc.Brightness = 0.02
		cc.Contrast = 0.08
		cc.Saturation = 0.12
		cc.Parent = Lighting
	end
end

function LevelSetup.EnsurePlaceholders()
	local classroom = ensureFolder()
	buildClassroomShell(classroom)
	buildBoardsAndTeacherZone(classroom)
	buildStudentDesks(classroom)
	buildPetCage(classroom)
	buildDogSpawn(classroom)
	ensureAtmosphere()
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
