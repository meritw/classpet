-- Client interact requests for Latch / Phone / Lesson. Server validates.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)

local InteractController = {}

local remotes = nil :: any
local hintCallback: ((string) -> ())? = nil
local lastHint = ""

local function getRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearestTagged(tag: string, maxDist: number): BasePart?
	local root = getRoot()
	if not root then
		return nil
	end
	local best: BasePart? = nil
	local bestDist = maxDist
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsA("BasePart") then
			local d = (inst.Position - root.Position).Magnitude
			if d <= bestDist then
				best = inst
				bestDist = d
			end
		end
	end
	return best
end

local function currentInteract(): (Types.InteractKind?, string)
	if nearestTagged(GameConfig.Tags.Latch, GameConfig.LatchInteractDistance) then
		return "Latch", "Press E — Slip the latch"
	end
	if nearestTagged(GameConfig.Tags.Phone, GameConfig.PhoneInteractDistance) then
		return "Phone", "Press E — Call the dog’s family"
	end
	if nearestTagged(GameConfig.Tags.LessonSpot, GameConfig.LessonInteractDistance) then
		return "Lesson", "Press E — Join the lesson (quiz)"
	end
	return nil, ""
end

function InteractController.Start(remoteApi, onHint: ((string) -> ())?)
	remotes = remoteApi
	hintCallback = onHint

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			local kind = currentInteract()
			if kind and remotes then
				remotes.RequestInteract:FireServer(kind)
			end
		elseif input.KeyCode == Enum.KeyCode.Q then
			-- Sugar Dash consume request (night buff stub).
			if remotes then
				remotes.RequestSugarDash:FireServer()
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local _, hint = currentInteract()
		if hint ~= lastHint then
			lastHint = hint
			if hintCallback then
				hintCallback(hint)
			end
		end
	end)
end

return InteractController
