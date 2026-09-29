-- Scales the default R15/R6 avatar down to classroom-hamster size for MVP,
-- then overlays a lightweight Parts “hamster dress” so Play doesn’t read as a tiny human.
-- Real hamster mesh can replace this later; ScaleTo keeps Humanoid movement working.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local ArtPalette = require(game:GetService("ReplicatedStorage").Shared.ArtPalette)

local HamsterAvatar = {}

local DRESS_NAME = "HamsterDress"

local function waitForHumanoid(character: Model, timeoutSeconds: number): Humanoid?
	local existing = character:FindFirstChildOfClass("Humanoid")
	if existing then
		return existing
	end
	local found = character:WaitForChild("Humanoid", timeoutSeconds)
	if found and found:IsA("Humanoid") then
		return found
	end
	return nil
end

local function softHideBody(character: Model)
	-- Keep collision / Humanoid; fade the human silhouette under the dress.
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			if descendant.Parent and descendant.Parent.Name == DRESS_NAME then
				continue
			end
			descendant.Transparency = math.max(descendant.Transparency, 0.85)
			descendant.CastShadow = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		elseif descendant:IsA("Accessory") then
			descendant:Destroy()
		end
	end
end

local function weldTo(root: BasePart, part: BasePart, offset: CFrame)
	part.CFrame = root.CFrame * offset
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CastShadow = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function makeDressPart(
	parent: Model,
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
	part.CanCollide = false
	part.Massless = true
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function applyHamsterDress(character: Model, root: BasePart)
	local existing = character:FindFirstChild(DRESS_NAME)
	if existing then
		existing:Destroy()
	end

	local P = ArtPalette
	local dress = Instance.new("Model")
	dress.Name = DRESS_NAME
	dress.Parent = character

	-- Prefab offsets are in unscaled studs relative to HRP; ScaleTo already shrunk the character,
	-- so dress sizes are authored at hamster scale (~1 stud tall pet).
	local body = makeDressPart(dress, "FurBody", Vector3.new(0.7, 0.55, 0.95), P.HamsterFur, Enum.PartType.Ball)
	weldTo(root, body, CFrame.new(0, -0.05, 0.05))

	local belly = makeDressPart(dress, "Belly", Vector3.new(0.5, 0.4, 0.7), P.HamsterFurLight, Enum.PartType.Ball)
	weldTo(root, belly, CFrame.new(0, -0.15, 0.05))

	local head = makeDressPart(dress, "FurHead", Vector3.new(0.55, 0.5, 0.55), P.HamsterFur, Enum.PartType.Ball)
	weldTo(root, head, CFrame.new(0, 0.28, -0.35))

	local cheekL = makeDressPart(dress, "CheekL", Vector3.new(0.28, 0.25, 0.28), P.HamsterFurLight, Enum.PartType.Ball)
	weldTo(root, cheekL, CFrame.new(-0.28, 0.22, -0.4))
	local cheekR = makeDressPart(dress, "CheekR", Vector3.new(0.28, 0.25, 0.28), P.HamsterFurLight, Enum.PartType.Ball)
	weldTo(root, cheekR, CFrame.new(0.28, 0.22, -0.4))

	local snout = makeDressPart(dress, "Snout", Vector3.new(0.28, 0.22, 0.28), P.HamsterFurLight, Enum.PartType.Ball)
	weldTo(root, snout, CFrame.new(0, 0.2, -0.58))

	local nose = makeDressPart(dress, "Nose", Vector3.new(0.12, 0.1, 0.1), P.HamsterNose, Enum.PartType.Ball)
	weldTo(root, nose, CFrame.new(0, 0.22, -0.72))

	local eyeL = makeDressPart(dress, "EyeL", Vector3.new(0.1, 0.1, 0.08), P.HamsterEye, Enum.PartType.Ball)
	weldTo(root, eyeL, CFrame.new(-0.16, 0.32, -0.55))
	local eyeR = makeDressPart(dress, "EyeR", Vector3.new(0.1, 0.1, 0.08), P.HamsterEye, Enum.PartType.Ball)
	weldTo(root, eyeR, CFrame.new(0.16, 0.32, -0.55))

	local earL = makeDressPart(dress, "EarL", Vector3.new(0.18, 0.22, 0.1), P.HamsterFurDark)
	weldTo(root, earL, CFrame.new(-0.22, 0.5, -0.28) * CFrame.Angles(0, 0, math.rad(15)))
	local earR = makeDressPart(dress, "EarR", Vector3.new(0.18, 0.22, 0.1), P.HamsterFurDark)
	weldTo(root, earR, CFrame.new(0.22, 0.5, -0.28) * CFrame.Angles(0, 0, math.rad(-15)))

	local tail = makeDressPart(dress, "Tail", Vector3.new(0.12, 0.12, 0.25), P.HamsterFurDark, Enum.PartType.Ball)
	weldTo(root, tail, CFrame.new(0, -0.05, 0.55))

	-- Tiny paws so the silhouette isn’t a floating potato
	local pawFL = makeDressPart(dress, "PawFL", Vector3.new(0.16, 0.12, 0.18), P.HamsterFurDark)
	weldTo(root, pawFL, CFrame.new(-0.22, -0.32, -0.25))
	local pawFR = makeDressPart(dress, "PawFR", Vector3.new(0.16, 0.12, 0.18), P.HamsterFurDark)
	weldTo(root, pawFR, CFrame.new(0.22, -0.32, -0.25))
	local pawBL = makeDressPart(dress, "PawBL", Vector3.new(0.18, 0.12, 0.2), P.HamsterFurDark)
	weldTo(root, pawBL, CFrame.new(-0.22, -0.32, 0.3))
	local pawBR = makeDressPart(dress, "PawBR", Vector3.new(0.18, 0.12, 0.2), P.HamsterFurDark)
	weldTo(root, pawBR, CFrame.new(0.22, -0.32, 0.3))
end

function HamsterAvatar.Apply(character: Model)
	local humanoid = waitForHumanoid(character, 5)
	if not humanoid then
		return
	end
	-- Ensure root exists before scaling (avoids mid-load pivot glitches).
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root or not root:IsA("BasePart") then
		return
	end
	-- ScaleTo is the supported R15/R6 path; keeps HipHeight / accessories coherent.
	local ok = pcall(function()
		humanoid:ScaleTo(GameConfig.HamsterScale)
	end)
	if not ok then
		-- Older Humanoid fallback: proportion scales when present (R15).
		for _, name in { "BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale" } do
			local value = humanoid:FindFirstChild(name)
			if value and value:IsA("NumberValue") then
				value.Value = GameConfig.HamsterScale
			end
		end
	end

	-- ScaleTo shrinks JumpHeight with the body; restore a usable hamster hop.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = GameConfig.HamsterJumpHeight

	-- Wait a frame so ScaleTo finishes welding, then dress + soft-hide human mesh.
	task.defer(function()
		if not character.Parent then
			return
		end
		-- Re-assert jump after ScaleTo settles (some avatars re-sync proportions).
		if humanoid.Parent then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid.UseJumpPower = false
			humanoid.JumpHeight = GameConfig.HamsterJumpHeight
		end
		softHideBody(character)
		applyHamsterDress(character, root)
	end)
end

return HamsterAvatar
