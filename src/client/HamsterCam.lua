-- Close third-person / over-shoulder hamster cam (overnight lock).
-- Client-only. Uses Scriptable camera + PreRender.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HamsterCam = {}

local player = Players.LocalPlayer
local yaw = 0
local pitch = -0.18
local connection: RBXScriptConnection? = nil
local rotateConn: RBXScriptConnection? = nil

-- Tight follow for ScaleTo(0.2) hamster — over-shoulder, not default human cam.
local DISTANCE = 4.2
local HEIGHT = 1.35
local SHOULDER = 0.85
local FOV = 62
local SENS = 0.0045

local function getRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function updateCamera(_dt: number)
	local camera = Workspace.CurrentCamera
	local root = getRoot()
	if not camera or not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV

	local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local focus = root.Position + Vector3.new(0, 0.55, 0)
	local offset = rot:VectorToWorldSpace(Vector3.new(SHOULDER, HEIGHT, DISTANCE))
	local camPos = focus + offset
	camera.CFrame = CFrame.lookAt(camPos, focus)
	camera.Focus = CFrame.new(focus)
end

function HamsterCam.Start()
	if connection then
		return
	end
	-- Seed yaw from current look if available
	local root = getRoot()
	if root then
		yaw = math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z)
	end

	rotateConn = UserInputService.InputChanged:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				yaw -= input.Delta.X * SENS
				pitch = math.clamp(pitch - input.Delta.Y * SENS, -0.85, 0.35)
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			-- Touch look is handled lightly via delta when not processed by UI
			yaw -= input.Delta.X * SENS * 0.6
			pitch = math.clamp(pitch - input.Delta.Y * SENS * 0.6, -0.85, 0.35)
		end
	end)

	-- Prefer RMB orbit; also lock mouse on RMB hold for PC feel.
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)

	connection = RunService.PreRender:Connect(updateCamera)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			local r = getRoot()
			if r then
				yaw = math.atan2(-r.CFrame.LookVector.X, -r.CFrame.LookVector.Z)
			end
		end)
	end)
end

return HamsterCam
