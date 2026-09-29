-- Teacher desk phone → call dog’s family → win.
-- Only valid during Night; server validates proximity and phase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local LevelSetup = require(script.Parent.LevelSetup)
local PhaseController = require(script.Parent.PhaseController)
local CageService = require(script.Parent.CageService)

local PhoneObjective = {}

local callInProgress: { [Player]: boolean } = {}

function PhoneObjective.ClearPlayer(player: Player)
	callInProgress[player] = nil
end

function PhoneObjective.TryCall(player: Player): (boolean, string?)
	if not PhaseController.IsNight() then
		return false, "Phone is for night — after you escape."
	end
	if PhaseController.HasWon() then
		return false, "Already won."
	end
	if not CageService.HasEscapedThisNight(player) then
		return false, "Escape the cage first."
	end
	if callInProgress[player] then
		return false, "Calling…"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "No character."
	end

	local phone = LevelSetup.GetFirstTagged(GameConfig.Tags.Phone)
	if not phone or not phone:IsA("BasePart") then
		return false, "No phone."
	end

	if (root.Position - phone.Position).Magnitude > GameConfig.PhoneInteractDistance then
		return false, "Too far from the phone."
	end

	callInProgress[player] = true
	task.delay(GameConfig.PhoneCallDurationSeconds, function()
		callInProgress[player] = nil
		if not PhaseController.IsNight() then
			return
		end
		-- Re-check proximity at call end (anti-teleport stub).
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local phoneNow = LevelSetup.GetFirstTagged(GameConfig.Tags.Phone)
		if not hrp or not phoneNow or not phoneNow:IsA("BasePart") then
			return
		end
		if (hrp.Position - phoneNow.Position).Magnitude > GameConfig.PhoneInteractDistance * 1.5 then
			return
		end
		PhaseController.OnPhoneWin()
	end)

	return true, nil
end

return PhoneObjective
