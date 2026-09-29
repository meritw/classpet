-- Client entry. Waits for remotes, then wires UI + interact.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Types = require(ReplicatedStorage.Shared.Types)

local GoalUI = require(script.Parent.GoalUI)
local QuizUI = require(script.Parent.QuizUI)
local InteractController = require(script.Parent.InteractController)
local PhasePresenter = require(script.Parent.PhasePresenter)

local remotes = Remotes.GetClient()

GoalUI.Start()
QuizUI.Start(remotes)
PhasePresenter.Start(remotes)

InteractController.Start(remotes, function(hint: string)
	if hint ~= "" then
		GoalUI.ShowToast(hint, 1.2)
	end
end)

remotes.SessionUpdated.OnClientEvent:Connect(function(snapshot: Types.SessionSnapshot)
	if typeof(snapshot) == "table" then
		GoalUI.ApplySnapshot(snapshot)
	end
end)

remotes.PhaseChanged.OnClientEvent:Connect(function(phase, cycleIndex, goalText)
	-- SessionUpdated carries buffs; this only refreshes phase chrome if snapshot lags.
	GoalUI.ApplyPhaseChrome(phase, cycleIndex, goalText)
end)

remotes.CatchFeedback.OnClientEvent:Connect(function(kind)
	if kind == "DogCatch" then
		GoalUI.ShowToast("Caught! Back to the cage — wait for tomorrow…", 3)
	elseif kind == "DayCatch" then
		GoalUI.ShowToast("Teacher noticed! Stay in your cage during class.", 2.5)
	end
end)

remotes.QuizResult.OnClientEvent:Connect(function(result)
	if typeof(result) == "table" and result.ok then
		GoalUI.ShowToast("Nice! Night buff earned.", 2)
	elseif typeof(result) == "table" then
		GoalUI.ShowToast("Not quite — try another question.", 2)
	end
end)

remotes.WinFeedback.OnClientEvent:Connect(function()
	GoalUI.ShowToast("You called the dog’s family. They can come get him!", 5)
end)
