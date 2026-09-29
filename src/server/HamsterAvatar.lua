-- Scales the default R15/R6 avatar down to classroom-hamster size for MVP.
-- Real hamster mesh can replace this later; ScaleTo keeps Humanoid movement working.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local HamsterAvatar = {}

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

function HamsterAvatar.Apply(character: Model)
	local humanoid = waitForHumanoid(character, 5)
	if not humanoid then
		return
	end
	-- Ensure root exists before scaling (avoids mid-load pivot glitches).
	character:WaitForChild("HumanoidRootPart", 5)
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
end

return HamsterAvatar
