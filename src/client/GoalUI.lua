-- Minimal phase / goal / buff HUD. One goal at a time (design juice note).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local BuffDefs = require(ReplicatedStorage.Shared.BuffDefs)

local GoalUI = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local phaseLabel: TextLabel? = nil
local goalLabel: TextLabel? = nil
local buffLabel: TextLabel? = nil
local toastLabel: TextLabel? = nil

local function ensureGui()
	if gui and gui.Parent then
		return
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "ClassPetGoalUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "Hud"
	frame.Size = UDim2.new(0.5, 0, 0, 96)
	frame.Position = UDim2.new(0.25, 0, 0, 16)
	frame.BackgroundTransparency = 0.35
	frame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	frame.BorderSizePixel = 0
	frame.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local phase = Instance.new("TextLabel")
	phase.Name = "Phase"
	phase.Size = UDim2.new(1, -16, 0, 28)
	phase.Position = UDim2.new(0, 8, 0, 6)
	phase.BackgroundTransparency = 1
	phase.Font = Enum.Font.GothamBold
	phase.TextSize = 20
	phase.TextXAlignment = Enum.TextXAlignment.Left
	phase.TextColor3 = Color3.fromRGB(245, 240, 230)
	phase.Text = "Day · Cycle 1"
	phase.Parent = frame
	phaseLabel = phase

	local goal = Instance.new("TextLabel")
	goal.Name = "Goal"
	goal.Size = UDim2.new(1, -16, 0, 28)
	goal.Position = UDim2.new(0, 8, 0, 34)
	goal.BackgroundTransparency = 1
	goal.Font = Enum.Font.Gotham
	goal.TextSize = 16
	goal.TextXAlignment = Enum.TextXAlignment.Left
	goal.TextColor3 = Color3.fromRGB(220, 220, 210)
	goal.Text = ""
	goal.TextWrapped = true
	goal.Parent = frame
	goalLabel = goal

	local buffs = Instance.new("TextLabel")
	buffs.Name = "Buffs"
	buffs.Size = UDim2.new(1, -16, 0, 24)
	buffs.Position = UDim2.new(0, 8, 0, 64)
	buffs.BackgroundTransparency = 1
	buffs.Font = Enum.Font.GothamMedium
	buffs.TextSize = 14
	buffs.TextXAlignment = Enum.TextXAlignment.Left
	buffs.TextColor3 = Color3.fromRGB(180, 220, 180)
	buffs.Text = "Buffs: (none yet)"
	buffs.Parent = frame
	buffLabel = buffs

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.Size = UDim2.new(0.4, 0, 0, 36)
	toast.Position = UDim2.new(0.3, 0, 0.75, 0)
	toast.BackgroundTransparency = 0.25
	toast.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 18
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Text = ""
	toast.Visible = false
	toast.Parent = screen
	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toast
	toastLabel = toast

	gui = screen
end

local function formatBuffs(buffs: { Types.BuffCharge }): string
	if #buffs == 0 then
		return "Buffs: (none yet)"
	end
	local parts = {}
	for _, b in buffs do
		local def = BuffDefs[b.id]
		local name = if def then def.displayName else b.id
		table.insert(parts, `{name} ×{b.charges}`)
	end
	return "Buffs: " .. table.concat(parts, " · ")
end

function GoalUI.ApplySnapshot(snapshot: Types.SessionSnapshot)
	ensureGui()
	if phaseLabel then
		phaseLabel.Text = `{snapshot.phase} · Cycle {snapshot.cycleIndex}`
	end
	if goalLabel then
		goalLabel.Text = snapshot.goalText
	end
	if buffLabel then
		buffLabel.Text = formatBuffs(snapshot.buffs)
	end
end

function GoalUI.ApplyPhaseChrome(phase: Types.Phase, cycleIndex: number, goalText: string)
	ensureGui()
	if phaseLabel then
		phaseLabel.Text = `{phase} · Cycle {cycleIndex}`
	end
	if goalLabel then
		goalLabel.Text = goalText
	end
end

function GoalUI.ShowToast(message: string, duration: number?)
	ensureGui()
	if not toastLabel then
		return
	end
	toastLabel.Text = message
	toastLabel.Visible = true
	local hideAfter = duration or 2.5
	task.delay(hideAfter, function()
		if toastLabel and toastLabel.Text == message then
			toastLabel.Visible = false
		end
	end)
end

function GoalUI.Start()
	ensureGui()
end

return GoalUI
