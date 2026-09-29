-- Lightweight day/night presentation hooks (lights already server-driven).
-- Future: ambient NPC idles, audio stingers, cage rattles.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local PhasePresenter = {}

function PhasePresenter.OnPhaseChanged(phase: Types.Phase, _cycleIndex: number, _goalText: string)
	-- Soft local nudge; authoritative lighting is set by PhaseController on the server.
	if phase == "Night" then
		Lighting.FogEnd = 120
		Lighting.FogColor = Color3.fromRGB(20, 22, 35)
	elseif phase == "Day" then
		Lighting.FogEnd = 100000
	elseif phase == "Won" then
		Lighting.FogEnd = 100000
	end
end

function PhasePresenter.Start(remotes)
	remotes.PhaseChanged.OnClientEvent:Connect(function(phase, cycleIndex, goalText)
		PhasePresenter.OnPhaseChanged(phase, cycleIndex, goalText)
	end)
end

return PhasePresenter
