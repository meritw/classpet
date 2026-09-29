-- Remote folder contract. Server creates instances; client waits with timeout.
-- Remotes are typed APIs — never trust client "I won" / "I have buff" claims.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "ClassPetRemotes"
local WAIT_TIMEOUT = 10

local RemoteNames = {
	-- Server → client
	SessionUpdated = "SessionUpdated", -- SessionSnapshot
	QuizPresented = "QuizPresented", -- quiz payload without correctIndex
	QuizResult = "QuizResult", -- { ok, buffId? }
	PhaseChanged = "PhaseChanged", -- Phase, cycleIndex, goalText
	CatchFeedback = "CatchFeedback", -- "DayCatch" | "DogCatch"
	WinFeedback = "WinFeedback",

	-- Client → server
	RequestInteract = "RequestInteract", -- InteractKind
	SubmitQuizAnswer = "SubmitQuizAnswer", -- questionId, choiceIndex
	RequestQuiz = "RequestQuiz", -- optional; lesson spot / teacher prompt
	RequestSugarDash = "RequestSugarDash", -- consume SugarDash charge if available
}

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	error(`[{FOLDER_NAME}] folder missing — server bootstrap must run first`)
end

local function waitForFolder(): Folder
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, WAIT_TIMEOUT)
	if not folder or not folder:IsA("Folder") then
		error(`Timed out waiting for {FOLDER_NAME}`)
	end
	return folder
end

local function ensureEvent(folder: Folder, name: string): RemoteEvent
	local child = folder:FindFirstChild(name)
	if child and child:IsA("RemoteEvent") then
		return child
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Remotes = {}

function Remotes.InitServer()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in RemoteNames do
		ensureEvent(folder, name)
	end
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.GetServer()
	local folder = getFolder()
	local api = {}
	for key, name in RemoteNames do
		api[key] = ensureEvent(folder, name)
	end
	return api
end

function Remotes.GetClient()
	local folder = waitForFolder()
	local api = {}
	for key, name in RemoteNames do
		local remote = folder:WaitForChild(name, WAIT_TIMEOUT)
		if not remote or not remote:IsA("RemoteEvent") then
			error(`Timed out waiting for remote {name}`)
		end
		api[key] = remote
	end
	return api
end

Remotes.Names = RemoteNames

return Remotes
