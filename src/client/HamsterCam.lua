-- Close third-person hamster cam via CameraType.Custom + PlayerModule.
-- Preserves normal mouse look / RMB orbit / right-stick (no Scriptable lock).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local HamsterCam = {}

local player = Players.LocalPlayer

-- Tight zoom band for ScaleTo(0.2) hamster — still PlayerModule-controlled.
local MIN_ZOOM = 2.5
local MAX_ZOOM = 14
local FOV = 62
local CAMERA_OFFSET = Vector3.new(0.55, 0.55, 0) -- slight over-shoulder

local function applyToCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		camera.FieldOfView = FOV
	end

	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
	-- Prefer a close default without fighting PlayerModule's zoom input.
	if player.CameraMode ~= Enum.CameraMode.Classic then
		player.CameraMode = Enum.CameraMode.Classic
	end

	humanoid.CameraOffset = CAMERA_OFFSET
end

function HamsterCam.Start()
	if player.Character then
		task.spawn(applyToCharacter, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.defer(applyToCharacter, character)
	end)

	-- Re-assert Custom if something else flips Scriptable (e.g. Studio tooling).
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local camera = Workspace.CurrentCamera
		local character = player.Character
		if camera and character then
			task.defer(applyToCharacter, character)
		end
	end)
end

return HamsterCam
