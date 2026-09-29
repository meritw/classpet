-- Ensures tagged placeholder parts exist so the loop can run without a hand-built place.
-- Studio authors can replace these with real classroom geometry; tags stay the contract.
-- Player fantasy: tiny hamster in a desk-pet cage; classroom props stay human scale.
--
-- Scale contract (do not fight — from hamster-scale PR):
--   GameConfig.CageSize / CageCenter / HamsterDesk / HamsterScale
-- Visual pass adds POLYGON-style shell + custom pet cage dressing around those sizes.
-- Overnight polish: richer Parts set dressing (no Synty FBX in repo).

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

local function ensureSurfaceGuiLabel(parent: BasePart, name: string, text: string, textSize: number)
	local gui = parent:FindFirstChild(name)
	if not gui or not gui:IsA("SurfaceGui") then
		if gui then
			gui:Destroy()
		end
		gui = Instance.new("SurfaceGui")
		gui.Name = name
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = parent
	end
	local label = gui:FindFirstChild("Label")
	if not label or not label:IsA("TextLabel") then
		if label then
			label:Destroy()
		end
		label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.fromRGB(50, 70, 110)
		label.TextScaled = false
		label.Parent = gui
	end
	label.Text = text
	label.TextSize = textSize
	return gui
end

local function buildClassroomShell(classroom: Folder)
	local shell = ensureModel(classroom, "RoomShell")
	local P = ArtPalette

	-- Subfloor (human classroom)
	ensurePart(shell, "Floor", Vector3.new(80, 1, 60), CFrame.new(0, 0, 0), P.Floor, Enum.Material.WoodPlanks)

	-- Checkerboard floor tiles (readable classroom linoleum / vinyl vibe)
	local tiles = ensureModel(shell, "FloorTiles")
	local tileW, tileD = 5, 5
	local cols, rows = 14, 10
	local originX = -((cols - 1) * tileW) * 0.5
	local originZ = -((rows - 1) * tileD) * 0.5
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local light = ((row + col) % 2) == 0
			local x = originX + col * tileW
			local z = originZ + row * tileD
			ensurePart(
				tiles,
				`Tile_{row}_{col}`,
				Vector3.new(tileW - 0.08, 0.06, tileD - 0.08),
				CFrame.new(x, 0.53, z),
				if light then P.FloorTileA else P.FloorTileB,
				Enum.Material.SmoothPlastic,
				{ canCollide = false }
			)
		end
	end

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

	-- Wood baseboard trim
	ensurePart(shell, "Trim_N", Vector3.new(79.5, 0.35, 0.18), CFrame.new(0, 0.75, -29.35), P.FloorTrim, Enum.Material.Wood, { canCollide = false })
	ensurePart(shell, "Trim_S", Vector3.new(79.5, 0.35, 0.18), CFrame.new(0, 0.75, 29.35), P.FloorTrim, Enum.Material.Wood, { canCollide = false })
	ensurePart(shell, "Trim_W", Vector3.new(0.18, 0.35, 59.5), CFrame.new(-39.35, 0.75, 0), P.FloorTrim, Enum.Material.Wood, { canCollide = false })
	ensurePart(shell, "Trim_E", Vector3.new(0.18, 0.35, 59.5), CFrame.new(39.35, 0.75, 0), P.FloorTrim, Enum.Material.Wood, { canCollide = false })

	-- Ceiling
	ensurePart(shell, "Ceiling", Vector3.new(80, 1, 60), CFrame.new(0, wallH + 1, 0), P.Ceiling, Enum.Material.SmoothPlastic)

	-- Windows on +X wall (day light reads through) + blinds
	for i = 1, 3 do
		local z = -16 + (i - 1) * 16
		ensurePart(shell, `WindowFrame_{i}`, Vector3.new(0.4, 5, 8), CFrame.new(39.6, 6, z), P.WindowFrame, Enum.Material.SmoothPlastic, { canCollide = false })
		local glass = ensurePart(shell, `WindowGlass_{i}`, Vector3.new(0.15, 4.4, 7.2), CFrame.new(39.7, 6, z), P.WindowGlass, Enum.Material.Glass, {
			canCollide = false,
			transparency = 0.45,
		})
		ensurePointLight(glass, "DayWindowGlow", Color3.fromRGB(255, 245, 220), 0.35, 18)
		-- Horizontal blind slats (partially open)
		for s = 1, 6 do
			local y = 4.1 + (s - 1) * 0.7
			ensurePart(
				shell,
				`Blind_{i}_{s}`,
				Vector3.new(0.12, 0.12, 7),
				CFrame.new(39.45, y, z),
				if s % 2 == 0 then P.Blind else P.BlindSlat,
				Enum.Material.SmoothPlastic,
				{ canCollide = false }
			)
		end
		ensurePart(shell, `BlindHeader_{i}`, Vector3.new(0.2, 0.25, 7.4), CFrame.new(39.45, 8.3, z), P.WindowFrame, Enum.Material.SmoothPlastic, { canCollide = false })
	end

	-- Door on -Z wall
	ensurePart(shell, "DoorFrame", Vector3.new(5, 8, 0.6), CFrame.new(18, 4.5, -29.6), P.DoorFrame, Enum.Material.Wood)
	ensurePart(shell, "Door", Vector3.new(4, 7, 0.35), CFrame.new(18, 4, -29.3), P.Door, Enum.Material.Wood)
	ensurePart(shell, "DoorKnob", Vector3.new(0.25, 0.25, 0.35), CFrame.new(16.4, 4, -29.05), Color3.fromRGB(220, 190, 80), Enum.Material.Metal, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
end

local function buildCeilingLights(classroom: Folder)
	local lights = ensureModel(classroom, "CeilingLights")
	local P = ArtPalette
	local positions = {
		Vector3.new(-18, 12.2, -12),
		Vector3.new(0, 12.2, -12),
		Vector3.new(18, 12.2, -12),
		Vector3.new(-18, 12.2, 8),
		Vector3.new(0, 12.2, 8),
		Vector3.new(18, 12.2, 8),
	}
	for i, pos in positions do
		local fixture = ensurePart(
			lights,
			`Fixture_{i}`,
			Vector3.new(6, 0.25, 1.4),
			CFrame.new(pos),
			P.CeilingFixture,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		local lamp = ensurePart(
			lights,
			`Lamp_{i}`,
			Vector3.new(5.4, 0.12, 1),
			CFrame.new(pos + Vector3.new(0, -0.2, 0)),
			P.CeilingLamp,
			Enum.Material.Neon,
			{ canCollide = false }
		)
		local light = ensurePointLight(lamp, "CeilingGlow", Color3.fromRGB(255, 245, 220), 1.1, 28)
		light:SetAttribute("ClassPetDayBrightness", 1.1)
		light:SetAttribute("ClassPetNightBrightness", 0.08)
		fixture:SetAttribute("ClassPetCeilingLight", true)
		lamp:SetAttribute("ClassPetCeilingLight", true)
	end
end

local function buildBoardsAndTeacherZone(classroom: Folder)
	local zone = ensureModel(classroom, "TeacherZone")
	local P = ArtPalette

	-- Whiteboard on -Z wall (Police Station whiteboard stand-in)
	ensurePart(zone, "Whiteboard", Vector3.new(16, 6, 0.35), CFrame.new(-6, 7, -29.2), P.Whiteboard, Enum.Material.SmoothPlastic)
	ensurePart(zone, "WhiteboardFrame", Vector3.new(16.6, 6.5, 0.2), CFrame.new(-6, 7, -29.35), P.WhiteboardFrame, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(zone, "ChalkTray", Vector3.new(16, 0.25, 0.45), CFrame.new(-6, 3.9, -28.9), P.ChalkTray, Enum.Material.SmoothPlastic)

	-- Bulletin board accent
	local bulletin = ensurePart(zone, "BulletinBoard", Vector3.new(6, 4, 0.3), CFrame.new(8, 6.5, -29.2), Color3.fromRGB(255, 230, 140), Enum.Material.Cardboard)
	ensureSurfaceGuiLabel(bulletin, "BulletinLabel", "Class News!", 28)

	-- Wall clock above door-side
	local clock = ensureModel(zone, "WallClock")
	-- Cylinder default axis is +X; rotate Y so flat face points into room (+Z from -Z wall).
	local clockCf = CFrame.new(14, 10.2, -29.15) * CFrame.Angles(0, math.rad(90), 0)
	ensurePart(clock, "Face", Vector3.new(0.15, 1.8, 1.8), clockCf, P.ClockFace, Enum.Material.SmoothPlastic, {
		canCollide = false,
		shape = Enum.PartType.Cylinder,
	})
	ensurePart(clock, "Rim", Vector3.new(0.08, 2.05, 2.05), CFrame.new(14, 10.2, -29.25) * CFrame.Angles(0, math.rad(90), 0), P.ClockRim, Enum.Material.Metal, {
		canCollide = false,
		shape = Enum.PartType.Cylinder,
	})
	ensurePart(clock, "HandHour", Vector3.new(0.08, 0.55, 0.05), CFrame.new(14, 10.35, -29.05), P.ClockHand, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(clock, "HandMinute", Vector3.new(0.06, 0.75, 0.05), CFrame.new(14.15, 10.45, -29.05), P.ClockHand, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(clock, "Center", Vector3.new(0.18, 0.18, 0.12), CFrame.new(14, 10.2, -29.02), P.ClockRim, Enum.Material.Metal, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})

	-- Educational posters on side walls
	local posters = ensureModel(zone, "Posters")
	local posterSpecs = {
		{ name = "Poster_Alphabet", cf = CFrame.new(-39.55, 7.5, -10) * CFrame.Angles(0, math.rad(90), 0), text = "A B C", color = Color3.fromRGB(255, 220, 200) },
		{ name = "Poster_Numbers", cf = CFrame.new(-39.55, 7.5, 8) * CFrame.Angles(0, math.rad(90), 0), text = "1 2 3", color = Color3.fromRGB(200, 230, 255) },
		{ name = "Poster_Hamster", cf = CFrame.new(-39.55, 7.2, 18) * CFrame.Angles(0, math.rad(90), 0), text = "Class Pet!", color = Color3.fromRGB(255, 235, 180) },
		{ name = "Poster_Rules", cf = CFrame.new(12, 8, 29.55), text = "Be Kind", color = Color3.fromRGB(220, 255, 220) },
	}
	for _, spec in posterSpecs do
		ensurePart(posters, `{spec.name}_Frame`, Vector3.new(3.4, 2.6, 0.12), spec.cf * CFrame.new(0, 0, 0.05), P.PosterFrame, Enum.Material.Wood, { canCollide = false })
		local paper = ensurePart(posters, spec.name, Vector3.new(3, 2.2, 0.08), spec.cf, spec.color, Enum.Material.Cardboard, { canCollide = false })
		ensureSurfaceGuiLabel(paper, "PosterText", spec.text, 42)
	end

	-- Teacher desk (Office Pack proportion) toward +X / -Z corner
	local deskCf = CFrame.new(28, 2.1, -20)
	ensurePart(zone, "TeacherDesk", Vector3.new(8, 0.4, 4), deskCf, P.TeacherDesk, Enum.Material.Wood)
	ensurePart(zone, "TeacherDeskLeg_L", Vector3.new(0.4, 3.2, 0.4), CFrame.new(25, 1.6, -21.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_R", Vector3.new(0.4, 3.2, 0.4), CFrame.new(31, 1.6, -18.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_L2", Vector3.new(0.4, 3.2, 0.4), CFrame.new(25, 1.6, -18.5), P.DeskLeg, Enum.Material.Metal)
	ensurePart(zone, "TeacherDeskLeg_R2", Vector3.new(0.4, 3.2, 0.4), CFrame.new(31, 1.6, -21.5), P.DeskLeg, Enum.Material.Metal)
	-- Desk clutter
	ensurePart(zone, "DeskPaperStack", Vector3.new(1.4, 0.15, 1.1), CFrame.new(26.2, 2.4, -20.5), Color3.fromRGB(245, 245, 240), Enum.Material.Cardboard, { canCollide = false })
	ensurePart(zone, "DeskMug", Vector3.new(0.45, 0.55, 0.45), CFrame.new(27.2, 2.55, -18.6), Color3.fromRGB(80, 140, 180), Enum.Material.SmoothPlastic, {
		canCollide = false,
		shape = Enum.PartType.Cylinder,
	})

	-- Desk phone on teacher desk — landline silhouette (tagged Phone is the interactable base)
	local phone = ensureTaggedPart(
		classroom,
		"Phone",
		GameConfig.Tags.Phone,
		Vector3.new(1.6, 0.35, 1.1),
		CFrame.new(30, 2.48, -19.2),
		P.PhoneBase
	)
	phone.Material = Enum.Material.SmoothPlastic

	local phoneProp = ensureModel(classroom, "PhoneProps")
	-- Raised keypad wedge
	ensurePart(phoneProp, "KeypadBody", Vector3.new(1.35, 0.22, 0.85), CFrame.new(30.05, 2.72, -19.05) * CFrame.Angles(math.rad(-12), 0, 0), P.PhoneBody, Enum.Material.SmoothPlastic, { canCollide = false })
	-- 3x4 button grid
	local btn = 0
	for row = 0, 3 do
		for col = 0, 2 do
			btn += 1
			local bx = 29.55 + col * 0.32
			local bz = -19.35 + row * 0.22
			ensurePart(
				phoneProp,
				`Key_{btn}`,
				Vector3.new(0.22, 0.06, 0.16),
				CFrame.new(bx, 2.86, bz),
				P.PhoneButton,
				Enum.Material.SmoothPlastic,
				{ canCollide = false }
			)
		end
	end
	-- Cradle + handset (classic landline read)
	ensurePart(phoneProp, "Cradle", Vector3.new(1.5, 0.2, 0.35), CFrame.new(29.95, 2.78, -19.7), P.PhoneBody, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(phoneProp, "Handset", Vector3.new(1.35, 0.28, 0.32), CFrame.new(29.95, 3.05, -19.7), P.PhoneHandset, Enum.Material.SmoothPlastic, { canCollide = false })
	ensurePart(phoneProp, "HandsetEar", Vector3.new(0.35, 0.35, 0.35), CFrame.new(29.35, 3.1, -19.7), P.PhoneHandset, Enum.Material.SmoothPlastic, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
	ensurePart(phoneProp, "HandsetMouth", Vector3.new(0.35, 0.35, 0.35), CFrame.new(30.55, 3.1, -19.7), P.PhoneHandset, Enum.Material.SmoothPlastic, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
	-- Coiled cord hint
	ensurePart(phoneProp, "Cord", Vector3.new(0.08, 0.08, 0.9), CFrame.new(30.55, 2.7, -19.45), P.PhoneCord, Enum.Material.SmoothPlastic, { canCollide = false })
	local ready = ensurePart(phoneProp, "ReadyLight", Vector3.new(0.18, 0.18, 0.18), CFrame.new(30.7, 2.9, -18.7), P.PhoneAccent, Enum.Material.Neon, {
		canCollide = false,
		shape = Enum.PartType.Ball,
	})
	ensurePointLight(ready, "PhoneGlow", P.PhoneAccent, 1.2, 10)
end

local function buildBookshelves(classroom: Folder)
	local shelves = ensureModel(classroom, "Bookshelves")
	local P = ArtPalette
	-- Back wall (+Z) bookshelf near classroom rear
	ensurePart(shelves, "ShelfUnit", Vector3.new(8, 6, 1.2), CFrame.new(-22, 3.5, 28.8), P.ShelfWood, Enum.Material.Wood)
	for row = 1, 4 do
		local y = 1.2 + (row - 1) * 1.35
		ensurePart(shelves, `ShelfBoard_{row}`, Vector3.new(7.6, 0.15, 1), CFrame.new(-22, y, 28.8), P.ShelfWood, Enum.Material.Wood, { canCollide = false })
		local spines = { P.BookSpineA, P.BookSpineB, P.BookSpineC, P.BookSpineD }
		for b = 1, 10 do
			local color = spines[((b + row) % 4) + 1]
			local h = 0.7 + ((b + row) % 3) * 0.15
			ensurePart(
				shelves,
				`Book_{row}_{b}`,
				Vector3.new(0.55, h, 0.85),
				CFrame.new(-25.2 + (b - 1) * 0.7, y + 0.1 + h * 0.5, 28.75),
				color,
				Enum.Material.SmoothPlastic,
				{ canCollide = false }
			)
		end
	end
	-- Small shelf near hamster desk (classroom pet corner)
	ensurePart(shelves, "PetCornerShelf", Vector3.new(3.5, 3.5, 1), CFrame.new(-32, 2.5, -8), P.ShelfWood, Enum.Material.Wood)
	for b = 1, 5 do
		local spines = { P.BookSpineB, P.BookSpineC, P.BookSpineA, P.BookSpineD, P.BookSpineB }
		ensurePart(
			shelves,
			`PetShelfBook_{b}`,
			Vector3.new(0.45, 0.9, 0.7),
			CFrame.new(-33.2 + (b - 1) * 0.55, 3.2, -8),
			spines[b],
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
	end
end

local function buildTrashAndExtras(classroom: Folder)
	local props = ensureModel(classroom, "RoomExtras")
	local P = ArtPalette
	-- Trash can near door
	ensurePart(props, "TrashCan", Vector3.new(1.4, 2.2, 1.4), CFrame.new(22, 1.6, -26), P.TrashCan, Enum.Material.Metal, {
		shape = Enum.PartType.Cylinder,
	})
	ensurePart(props, "TrashRim", Vector3.new(1.55, 0.15, 1.55), CFrame.new(22, 2.75, -26), P.TrashRim, Enum.Material.Metal, {
		canCollide = false,
		shape = Enum.PartType.Cylinder,
	})
	-- Recycling bin near back
	ensurePart(props, "RecycleBin", Vector3.new(1.2, 2, 1.2), CFrame.new(-8, 1.5, 26), Color3.fromRGB(70, 140, 90), Enum.Material.SmoothPlastic, {
		shape = Enum.PartType.Cylinder,
	})
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
			-- Notebook / pencil on a few desks
			if i % 2 == 1 then
				ensurePart(props, `Notebook_{i}`, Vector3.new(0.9, 0.08, 1.1), CFrame.new(x + 0.4, 2.55, z), Color3.fromRGB(250, 250, 255), Enum.Material.Cardboard, { canCollide = false })
			end
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
	ensurePart(props, "Backpack_C", Vector3.new(1.1, 1.3, 0.75), CFrame.new(4, 1.15, 6), Color3.fromRGB(240, 180, 60), Enum.Material.Fabric, { canCollide = false })
end

local function buildPetCage(classroom: Folder)
	-- Custom cage dressing around GameConfig cage sizes (no Synty hamster cage).
	local cageSize = GameConfig.CageSize
	local cageCenter = GameConfig.CageCenter
	local deskTopY = cageCenter.Y - cageSize.Y * 0.5
	local P = ArtPalette
	local tags = GameConfig.Tags

	-- Desk the cage sits on (human/classroom scale; footprint grows with CageSize).
	local deskHeight = deskTopY - 0.5 -- floor top ≈ 0.5
	local deskFootX = cageSize.X + 2.5
	local deskFootZ = cageSize.Z + 2.5
	ensurePart(
		classroom,
		"HamsterDesk",
		Vector3.new(deskFootX, deskHeight, deskFootZ),
		CFrame.new(cageCenter.X, 0.5 + deskHeight * 0.5, cageCenter.Z),
		Color3.fromRGB(140, 100, 60),
		Enum.Material.Wood
	)
	-- Desk edge trim
	ensurePart(
		classroom,
		"HamsterDeskEdge",
		Vector3.new(deskFootX + 0.2, 0.15, deskFootZ + 0.2),
		CFrame.new(cageCenter.X, deskTopY - 0.05, cageCenter.Z),
		Color3.fromRGB(120, 85, 50),
		Enum.Material.Wood,
		{ canCollide = false }
	)

	-- Transparent gameplay volume — keep exact CageSize/CageCenter (non-colliding marker).
	local cage = ensureTaggedPart(
		classroom,
		"CageVolume",
		tags.CageVolume,
		cageSize,
		CFrame.new(cageCenter),
		Color3.fromRGB(180, 180, 200)
	)
	cage.Transparency = 0.92
	cage.CanCollide = false
	cage.Material = Enum.Material.ForceField

	local visual = ensureModel(classroom, "PetCageVisual")
	local halfX = cageSize.X * 0.5
	local halfY = cageSize.Y * 0.5
	local halfZ = cageSize.Z * 0.5
	local wallThick = 0.2

	-- Solid invisible walls + ceiling: walk-out only via latch teleport (E).
	-- Thin visual bars alone leave gaps a ScaleTo(0.2) HRP can slip through.
	local collision = ensureModel(classroom, "PetCageCollision")
	local wallH = cageSize.Y
	local wallY = cageCenter.Y
	local function collideWall(name: string, size: Vector3, cf: CFrame)
		local wall = ensurePart(
			collision,
			name,
			size,
			cf,
			Color3.fromRGB(200, 200, 210),
			Enum.Material.SmoothPlastic,
			{ canCollide = true, transparency = 1 }
		)
		wall.CanQuery = false
		wall.CanTouch = false
		return wall
	end
	collideWall("Wall_Door", Vector3.new(wallThick, wallH, cageSize.Z), CFrame.new(cageCenter.X + halfX, wallY, cageCenter.Z))
	collideWall("Wall_Back", Vector3.new(wallThick, wallH, cageSize.Z), CFrame.new(cageCenter.X - halfX, wallY, cageCenter.Z))
	collideWall("Wall_NZ", Vector3.new(cageSize.X, wallH, wallThick), CFrame.new(cageCenter.X, wallY, cageCenter.Z - halfZ))
	collideWall("Wall_PZ", Vector3.new(cageSize.X, wallH, wallThick), CFrame.new(cageCenter.X, wallY, cageCenter.Z + halfZ))
	collideWall(
		"Wall_Ceiling",
		Vector3.new(cageSize.X + wallThick, wallThick, cageSize.Z + wallThick),
		CFrame.new(cageCenter.X, cageCenter.Y + halfY, cageCenter.Z)
	)

	-- Plastic tray / base with raised lip (floor collision)
	ensurePart(
		visual,
		"CageTray",
		Vector3.new(cageSize.X + 0.35, 0.28, cageSize.Z + 0.35),
		CFrame.new(cageCenter.X, deskTopY + 0.08, cageCenter.Z),
		P.CageTray,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	ensurePart(
		visual,
		"CageTrayLip",
		Vector3.new(cageSize.X + 0.45, 0.12, cageSize.Z + 0.45),
		CFrame.new(cageCenter.X, deskTopY + 0.28, cageCenter.Z),
		P.CageTrayLip,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	-- Wood-chip bedding
	ensurePart(
		visual,
		"Bedding",
		Vector3.new(cageSize.X - 0.35, 0.12, cageSize.Z - 0.35),
		CFrame.new(cageCenter.X, deskTopY + 0.28, cageCenter.Z),
		P.Bedding,
		Enum.Material.Sand,
		{ canCollide = false }
	)
	-- Bedding speckles for chip read
	for i = 1, 5 do
		local ox = ((i % 3) - 1) * (halfX * 0.35)
		local oz = ((i % 2) * 2 - 1) * (halfZ * 0.25)
		ensurePart(
			visual,
			`BeddingChip_{i}`,
			Vector3.new(0.35, 0.06, 0.25),
			CFrame.new(cageCenter.X + ox, deskTopY + 0.36, cageCenter.Z + oz),
			if i % 2 == 0 then Color3.fromRGB(190, 150, 90) else Color3.fromRGB(230, 195, 130),
			Enum.Material.Sand,
			{ canCollide = false }
		)
	end

	-- Plastic rim / top frame (visual; ceiling collision is separate)
	ensurePart(
		visual,
		"CageRim",
		Vector3.new(cageSize.X + 0.25, 0.22, cageSize.Z + 0.25),
		CFrame.new(cageCenter.X, cageCenter.Y + halfY - 0.05, cageCenter.Z),
		P.CagePlastic,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)

	-- Wire bars: denser verticals + horizontal crossbars (visual + CanCollide backup)
	local barThick = 0.08
	local barH = cageSize.Y - 0.4
	local barY = deskTopY + 0.32 + barH * 0.5
	local function bar(name: string, size: Vector3, cf: CFrame)
		ensurePart(visual, name, size, cf, P.CageWire, Enum.Material.Metal, { canCollide = true })
	end
	-- Long sides (±X faces: door +X, back −X; ±Z short sides). Spacing stays < hamster HRP.
	local doorBarCount = 11
	for i = 0, doorBarCount - 1 do
		local t = (i / (doorBarCount - 1)) * 2 - 1
		local z = cageCenter.Z + t * (halfZ - 0.12)
		bar(`Wire_DoorV_{i}`, Vector3.new(barThick, barH, barThick), CFrame.new(cageCenter.X + halfX - 0.02, barY, z))
		bar(`Wire_BackV_{i}`, Vector3.new(barThick, barH, barThick), CFrame.new(cageCenter.X - halfX + 0.05, barY, z))
	end
	local sideBarCount = 13
	for i = 0, sideBarCount - 1 do
		local t = (i / (sideBarCount - 1)) * 2 - 1
		local x = cageCenter.X + t * (halfX - 0.12)
		bar(`Wire_NZ_{i}`, Vector3.new(barThick, barH, barThick), CFrame.new(x, barY, cageCenter.Z - halfZ + 0.05))
		bar(`Wire_PZ_{i}`, Vector3.new(barThick, barH, barThick), CFrame.new(x, barY, cageCenter.Z + halfZ - 0.05))
	end
	-- Horizontal crossbars (4 per face)
	for level = 1, 4 do
		local y = deskTopY + 0.45 + (level - 1) * (barH / 4.2)
		bar(
			`Wire_H_Door_{level}`,
			Vector3.new(barThick, barThick, cageSize.Z - 0.15),
			CFrame.new(cageCenter.X + halfX - 0.02, y, cageCenter.Z)
		)
		bar(
			`Wire_H_Back_{level}`,
			Vector3.new(barThick, barThick, cageSize.Z - 0.15),
			CFrame.new(cageCenter.X - halfX + 0.05, y, cageCenter.Z)
		)
		bar(
			`Wire_H_NZ_{level}`,
			Vector3.new(cageSize.X - 0.15, barThick, barThick),
			CFrame.new(cageCenter.X, y, cageCenter.Z - halfZ + 0.05)
		)
		bar(
			`Wire_H_PZ_{level}`,
			Vector3.new(cageSize.X - 0.15, barThick, barThick),
			CFrame.new(cageCenter.X, y, cageCenter.Z + halfZ - 0.05)
		)
	end

	-- Corner posts (plastic, colliding)
	for _, ox in { -1, 1 } do
		for _, oz in { -1, 1 } do
			ensurePart(
				visual,
				`Post_{ox}_{oz}`,
				Vector3.new(0.22, cageSize.Y, 0.22),
				CFrame.new(cageCenter.X + ox * halfX, cageCenter.Y, cageCenter.Z + oz * halfZ),
				P.CagePlastic,
				Enum.Material.SmoothPlastic,
				{ canCollide = true }
			)
		end
	end

	-- Latch on +X face — green “doesn’t really latch”; non-colliding so E interact isn’t blocked
	local latchPos = Vector3.new(cageCenter.X + halfX + 0.15, deskTopY + 0.85, cageCenter.Z)
	local latch = ensureTaggedPart(
		classroom,
		"Latch",
		tags.Latch,
		Vector3.new(0.4, 0.4, 0.3),
		CFrame.new(latchPos),
		P.CageLatch
	)
	latch.Material = Enum.Material.Metal
	latch.CanCollide = false
	ensurePointLight(latch, "LatchHint", P.CageLatch, 0.7, 5)
	-- Latch handle nub
	ensurePart(
		visual,
		"LatchHandle",
		Vector3.new(0.15, 0.15, 0.35),
		CFrame.new(latchPos + Vector3.new(0.22, 0, 0)),
		Color3.fromRGB(70, 110, 55),
		Enum.Material.Metal,
		{ canCollide = false }
	)

	-- Lesson pad inside cage (forward of center)
	local lesson = ensureTaggedPart(
		classroom,
		"LessonSpot",
		tags.LessonSpot,
		Vector3.new(0.85, 0.12, 0.85),
		CFrame.new(cageCenter.X, deskTopY + 0.06, cageCenter.Z + halfZ * 0.35),
		Color3.fromRGB(90, 140, 200)
	)
	lesson.CanCollide = false

	-- Food bowl (back-left corner)
	local foodX = cageCenter.X - halfX + 1.1
	local foodZ = cageCenter.Z - halfZ + 1.0
	ensurePart(
		visual,
		"FoodBowl",
		Vector3.new(0.6, 0.24, 0.6),
		CFrame.new(foodX, deskTopY + 0.35, foodZ),
		P.FoodBowl,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	ensurePart(
		visual,
		"FoodPellets",
		Vector3.new(0.38, 0.08, 0.38),
		CFrame.new(foodX, deskTopY + 0.5, foodZ),
		Color3.fromRGB(180, 120, 60),
		Enum.Material.Sand,
		{ canCollide = false }
	)

	-- Water bottle on side of cage (+Z face)
	local bottleX = cageCenter.X + halfX * 0.35
	local bottleZ = cageCenter.Z + halfZ + 0.15
	ensurePart(
		visual,
		"WaterBottle",
		Vector3.new(0.45, 1.2, 0.45),
		CFrame.new(bottleX, deskTopY + 1.5, bottleZ) * CFrame.Angles(0, 0, math.rad(90)),
		P.WaterBottle,
		Enum.Material.Glass,
		{ shape = Enum.PartType.Cylinder, canCollide = false, transparency = 0.25 }
	)
	ensurePart(
		visual,
		"WaterCap",
		Vector3.new(0.4, 0.2, 0.4),
		CFrame.new(bottleX, deskTopY + 2.15, bottleZ),
		P.WaterCap,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	ensurePart(
		visual,
		"WaterNozzle",
		Vector3.new(0.12, 0.45, 0.12),
		CFrame.new(bottleX, deskTopY + 0.95, bottleZ - 0.2),
		P.WaterNozzle,
		Enum.Material.Metal,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	ensurePart(
		visual,
		"WaterHolder",
		Vector3.new(0.15, 0.55, 0.5),
		CFrame.new(bottleX, deskTopY + 1.65, cageCenter.Z + halfZ - 0.05),
		P.CagePlastic,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)

	-- Wheel: ring + stand on −Z side of cage (scales with enclosure)
	local wheelX = cageCenter.X + halfX * 0.2
	local wheelZ = cageCenter.Z - halfZ + 0.55
	local wheelY = deskTopY + 1.15
	ensurePart(
		visual,
		"WheelRing",
		Vector3.new(1.6, 1.6, 0.14),
		CFrame.new(wheelX, wheelY, wheelZ) * CFrame.Angles(0, 0, math.rad(90)),
		P.Wheel,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	ensurePart(
		visual,
		"WheelHub",
		Vector3.new(0.28, 0.28, 0.22),
		CFrame.new(wheelX, wheelY, wheelZ),
		Color3.fromRGB(255, 200, 220),
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball, canCollide = false }
	)
	ensurePart(
		visual,
		"WheelStand",
		Vector3.new(0.15, 1.0, 0.15),
		CFrame.new(wheelX, deskTopY + 0.6, wheelZ - 0.15),
		P.CagePlastic,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
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

-- Dim / restore ceiling PointLights for day vs night (called from PhaseController).
function LevelSetup.SetCeilingLightsForPhase(phase: string)
	local classroom = Workspace:FindFirstChild("Classroom")
	if not classroom then
		return
	end
	local lights = classroom:FindFirstChild("CeilingLights")
	if not lights then
		return
	end
	local night = phase == "Night"
	for _, child in lights:GetChildren() do
		if child:IsA("BasePart") then
			local glow = child:FindFirstChild("CeilingGlow")
			if glow and glow:IsA("PointLight") then
				local dayB = glow:GetAttribute("ClassPetDayBrightness")
				local nightB = glow:GetAttribute("ClassPetNightBrightness")
				if typeof(dayB) == "number" and typeof(nightB) == "number" then
					glow.Brightness = if night then nightB else dayB
				else
					glow.Brightness = if night then 0.08 else 1.1
				end
			end
			if child.Name:match("^Lamp_") then
				child.Material = if night then Enum.Material.SmoothPlastic else Enum.Material.Neon
				child.Color = if night then Color3.fromRGB(180, 180, 190) else ArtPalette.CeilingLamp
			end
		end
	end
end

function LevelSetup.EnsurePlaceholders()
	local classroom = ensureFolder()
	buildClassroomShell(classroom)
	buildCeilingLights(classroom)
	buildBoardsAndTeacherZone(classroom)
	buildBookshelves(classroom)
	buildTrashAndExtras(classroom)
	buildStudentDesks(classroom)
	buildPetCage(classroom)
	buildDogSpawn(classroom)
	ensureAtmosphere()
	LevelSetup.SetCeilingLightsForPhase("Day")
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
