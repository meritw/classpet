-- Cage containment: day catch if leave cage; latch escape only at night;
-- respawn to cage on day catch or dog catch. Latch is the unreliable "doesn't latch" beat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local LevelSetup = require(script.Parent.LevelSetup)
local PhaseController = require(script.Parent.PhaseController)

local CageService = {}

local escapedThisNight: { [Player]: boolean } = {}
local remotes = nil :: any
local running = false

function CageService.BindRemotes(remoteApi)
	remotes = remoteApi
end

function CageService.InitPlayer(player: Player)
	escapedThisNight[player] = false
	CageService.ReturnToCage(player)
end

function CageService.ClearPlayer(player: Player)
	escapedThisNight[player] = nil
end

function CageService.OnDayStarted()
	for _, player in Players:GetPlayers() do
		escapedThisNight[player] = false
		CageService.ReturnToCage(player)
	end
end

function CageService.OnNightStarted()
	-- Latch becomes usable; player may still be in cage until they interact.
	for _, player in Players:GetPlayers() do
		escapedThisNight[player] = false
	end
end

function CageService.HasEscapedThisNight(player: Player): boolean
	return escapedThisNight[player] == true
end

function CageService.ReturnToCage(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	root.CFrame = LevelSetup.GetCageRespawnCFrame()
	escapedThisNight[player] = false
end

function CageService.TryLatchEscape(player: Player): (boolean, string?)
	if not PhaseController.IsNight() then
		return false, "Latch only works at night."
	end
	if PhaseController.HasWon() then
		return false, "Already won."
	end
	-- After dog catch, phase is Day — so this path is already blocked.
	-- Extra guard: if somehow still Night but flagged, reject.
	if escapedThisNight[player] then
		return false, "Already out."
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "No character."
	end

	local latch = LevelSetup.GetFirstTagged(GameConfig.Tags.Latch)
	if not latch or not latch:IsA("BasePart") then
		return false, "No latch."
	end

	if (root.Position - latch.Position).Magnitude > GameConfig.LatchInteractDistance then
		return false, "Too far."
	end

	-- "Latch that doesn’t latch" — escape succeeds.
	escapedThisNight[player] = true
	root.CFrame = latch.CFrame + Vector3.new(4, 0, 0)
	return true, nil
end

local function dayCatchCheck()
	if not PhaseController.IsDay() then
		return
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and not LevelSetup.IsPointInsideCage(root.Position) then
			CageService.ReturnToCage(player)
			if remotes then
				remotes.CatchFeedback:FireClient(player, "DayCatch")
			end
		end
	end
end

function CageService.Start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while running do
			dayCatchCheck()
			task.wait(GameConfig.DayCatchCheckInterval)
		end
	end)
end

function CageService.Stop()
	running = false
end

-- Convenience for CollectionService latch prompts (optional Studio wiring).
function CageService.GetLatchParts(): { BasePart }
	local parts: { BasePart } = {}
	for _, inst in CollectionService:GetTagged(GameConfig.Tags.Latch) do
		if inst:IsA("BasePart") then
			table.insert(parts, inst)
		end
	end
	return parts
end

return CageService
