-- Quiz presentation: multiple-choice buttons. Server validates; UI never decides correctness.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local QuizUI = {}

local player = Players.LocalPlayer
local remotes = nil :: any
local screen: ScreenGui? = nil
local panel: Frame? = nil
local promptLabel: TextLabel? = nil
local buttonsFolder: Frame? = nil
local currentQuestionId: string? = nil

local function clearButtons()
	if not buttonsFolder then
		return
	end
	for _, child in buttonsFolder:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function ensureGui()
	if screen and screen.Parent then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ClassPetQuizUI"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.Size = UDim2.new(0.45, 0, 0, 220)
	frame.Position = UDim2.new(0.275, 0, 0.55, 0)
	frame.BackgroundColor3 = Color3.fromRGB(245, 242, 235)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.Size = UDim2.new(1, -24, 0, 48)
	prompt.Position = UDim2.new(0, 12, 0, 12)
	prompt.BackgroundTransparency = 1
	prompt.Font = Enum.Font.GothamBold
	prompt.TextSize = 18
	prompt.TextColor3 = Color3.fromRGB(30, 30, 35)
	prompt.TextWrapped = true
	prompt.TextXAlignment = Enum.TextXAlignment.Left
	prompt.Text = ""
	prompt.Parent = frame

	local choices = Instance.new("Frame")
	choices.Name = "Choices"
	choices.Size = UDim2.new(1, -24, 0, 140)
	choices.Position = UDim2.new(0, 12, 0, 68)
	choices.BackgroundTransparency = 1
	choices.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent = choices

	screen = gui
	panel = frame
	promptLabel = prompt
	buttonsFolder = choices
end

local function hide()
	if panel then
		panel.Visible = false
	end
	currentQuestionId = nil
	clearButtons()
end

function QuizUI.Present(question)
	ensureGui()
	if typeof(question) ~= "table" then
		return
	end
	local id = question.id
	local prompt = question.prompt
	local choices = question.choices
	if typeof(id) ~= "string" or typeof(prompt) ~= "string" or typeof(choices) ~= "table" then
		return
	end

	currentQuestionId = id
	if promptLabel then
		promptLabel.Text = `{question.subject or "Quiz"}: {prompt}`
	end
	clearButtons()
	if not buttonsFolder or not remotes then
		return
	end

	for i, choiceText in choices do
		if typeof(choiceText) ~= "string" then
			continue
		end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(70, 120, 180)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 16
		btn.Text = choiceText
		btn.AutoButtonColor = true
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn
		local index = i
		btn.MouseButton1Click:Connect(function()
			local qid = currentQuestionId
			if not qid then
				return
			end
			remotes.SubmitQuizAnswer:FireServer(qid, index)
			hide()
		end)
		btn.Parent = buttonsFolder
	end

	if panel then
		panel.Visible = true
	end
end

function QuizUI.Start(remoteApi)
	remotes = remoteApi
	ensureGui()
	remotes.QuizPresented.OnClientEvent:Connect(function(question)
		QuizUI.Present(question)
	end)
	remotes.PhaseChanged.OnClientEvent:Connect(function(phase)
		if phase ~= "Day" then
			hide()
		end
	end)
end

return QuizUI
