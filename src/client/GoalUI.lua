-- Phase / goal / buff HUD + light win/replay polish (overnight).
-- One goal at a time (design juice note).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local BuffDefs = require(ReplicatedStorage.Shared.BuffDefs)

local GoalUI = {}

local player = Players.LocalPlayer
local remotes = nil :: any
local gui: ScreenGui? = nil
local phaseLabel: TextLabel? = nil
local goalLabel: TextLabel? = nil
local buffLabel: TextLabel? = nil
local toastLabel: TextLabel? = nil
local winFrame: Frame? = nil
local winMessage: TextLabel? = nil

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
	frame.Size = UDim2.new(0.52, 0, 0, 100)
	frame.Position = UDim2.new(0.24, 0, 0, 14)
	frame.BackgroundTransparency = 0.28
	frame.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
	frame.BorderSizePixel = 0
	frame.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 140, 200)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.45
	stroke.Parent = frame

	local phase = Instance.new("TextLabel")
	phase.Name = "Phase"
	phase.Size = UDim2.new(1, -20, 0, 28)
	phase.Position = UDim2.new(0, 10, 0, 8)
	phase.BackgroundTransparency = 1
	phase.Font = Enum.Font.GothamBold
	phase.TextSize = 20
	phase.TextXAlignment = Enum.TextXAlignment.Left
	phase.TextColor3 = Color3.fromRGB(255, 236, 190)
	phase.Text = "Day · Cycle 1"
	phase.Parent = frame
	phaseLabel = phase

	local goal = Instance.new("TextLabel")
	goal.Name = "Goal"
	goal.Size = UDim2.new(1, -20, 0, 30)
	goal.Position = UDim2.new(0, 10, 0, 36)
	goal.BackgroundTransparency = 1
	goal.Font = Enum.Font.Gotham
	goal.TextSize = 16
	goal.TextXAlignment = Enum.TextXAlignment.Left
	goal.TextColor3 = Color3.fromRGB(230, 230, 220)
	goal.Text = ""
	goal.TextWrapped = true
	goal.Parent = frame
	goalLabel = goal

	local buffs = Instance.new("TextLabel")
	buffs.Name = "Buffs"
	buffs.Size = UDim2.new(1, -20, 0, 24)
	buffs.Position = UDim2.new(0, 10, 0, 68)
	buffs.BackgroundTransparency = 1
	buffs.Font = Enum.Font.GothamMedium
	buffs.TextSize = 14
	buffs.TextXAlignment = Enum.TextXAlignment.Left
	buffs.TextColor3 = Color3.fromRGB(160, 230, 170)
	buffs.Text = "Buffs: (none yet)"
	buffs.Parent = frame
	buffLabel = buffs

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.Size = UDim2.new(0.42, 0, 0, 40)
	toast.Position = UDim2.new(0.29, 0, 0.72, 0)
	toast.BackgroundTransparency = 0.2
	toast.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 18
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Text = ""
	toast.Visible = false
	toast.Parent = screen
	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toast
	local toastStroke = Instance.new("UIStroke")
	toastStroke.Color = Color3.fromRGB(255, 200, 100)
	toastStroke.Thickness = 1
	toastStroke.Transparency = 0.5
	toastStroke.Parent = toast
	toastLabel = toast

	-- Win overlay: short message + Replay (overnight lock)
	local win = Instance.new("Frame")
	win.Name = "WinPanel"
	win.Size = UDim2.new(0.4, 0, 0, 160)
	win.Position = UDim2.new(0.3, 0, 0.35, 0)
	win.BackgroundColor3 = Color3.fromRGB(245, 240, 230)
	win.BorderSizePixel = 0
	win.Visible = false
	win.Parent = screen
	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = UDim.new(0, 12)
	winCorner.Parent = win

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -24, 0, 36)
	title.Position = UDim2.new(0, 12, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(40, 90, 60)
	title.Text = "You did it!"
	title.Parent = win

	local msg = Instance.new("TextLabel")
	msg.Name = "Message"
	msg.Size = UDim2.new(1, -24, 0, 48)
	msg.Position = UDim2.new(0, 12, 0, 52)
	msg.BackgroundTransparency = 1
	msg.Font = Enum.Font.Gotham
	msg.TextSize = 16
	msg.TextWrapped = true
	msg.TextColor3 = Color3.fromRGB(50, 50, 55)
	msg.Text = "You called the dog’s family. They can come get him!"
	msg.Parent = win
	winMessage = msg

	local replay = Instance.new("TextButton")
	replay.Name = "Replay"
	replay.Size = UDim2.new(0.6, 0, 0, 36)
	replay.Position = UDim2.new(0.2, 0, 0, 108)
	replay.BackgroundColor3 = Color3.fromRGB(70, 140, 100)
	replay.TextColor3 = Color3.new(1, 1, 1)
	replay.Font = Enum.Font.GothamBold
	replay.TextSize = 18
	replay.Text = "Replay"
	replay.AutoButtonColor = true
	replay.Parent = win
	local replayCorner = Instance.new("UICorner")
	replayCorner.CornerRadius = UDim.new(0, 8)
	replayCorner.Parent = replay
	replay.MouseButton1Click:Connect(function()
		if remotes then
			remotes.RequestReplay:FireServer()
		end
	end)

	winFrame = win
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

local function setWinVisible(visible: boolean)
	if winFrame then
		winFrame.Visible = visible
	end
end

function GoalUI.ApplySnapshot(snapshot: Types.SessionSnapshot)
	ensureGui()
	if phaseLabel then
		local accent = if snapshot.phase == "Night"
			then Color3.fromRGB(170, 190, 255)
			elseif snapshot.phase == "Won" then Color3.fromRGB(120, 200, 140)
			else Color3.fromRGB(255, 236, 190)
		phaseLabel.TextColor3 = accent
		phaseLabel.Text = `{snapshot.phase} · Cycle {snapshot.cycleIndex}`
	end
	if goalLabel then
		goalLabel.Text = snapshot.goalText
	end
	if buffLabel then
		buffLabel.Text = formatBuffs(snapshot.buffs)
	end
	setWinVisible(snapshot.phase == "Won")
end

function GoalUI.ApplyPhaseChrome(phase: Types.Phase, cycleIndex: number, goalText: string)
	ensureGui()
	if phaseLabel then
		phaseLabel.Text = `{phase} · Cycle {cycleIndex}`
	end
	if goalLabel then
		goalLabel.Text = goalText
	end
	setWinVisible(phase == "Won")
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

function GoalUI.ShowWin(message: string?)
	ensureGui()
	if winMessage and message then
		winMessage.Text = message
	end
	setWinVisible(true)
end

function GoalUI.BindRemotes(remoteApi)
	remotes = remoteApi
end

function GoalUI.Start()
	ensureGui()
end

return GoalUI
