-- ServerScriptService > GameManager

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local TweenService      = game:GetService("TweenService")

local LOBBY_TIME       = 15
local DEATHMATCH_TIME  = 300
local KOTH_MAX_POINTS  = 500
local KOTH_TICK        = 0.4
local RESULTS_TIME     = 10
local MODES            = { "Deathmatch", "KingOfTheHill" }
local MULTIPLIER_HOLD_TIME = 3

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remotes then
	remotes = Instance.new("Folder"); remotes.Name = "GameRemotes"
	remotes.Parent = ReplicatedStorage
end
local function ensure(parent, class, name)
	local ex = parent:FindFirstChild(name); if ex then return ex end
	local o = Instance.new(class); o.Name = name; o.Parent = parent; return o
end

local updateGUI   = ensure(remotes, "RemoteEvent", "UpdateGUI")
local showResults = ensure(remotes, "RemoteEvent", "ShowResults")
local fadeEvent   = ensure(remotes, "RemoteEvent", "FadeScreen")
local kothUpdate  = ensure(remotes, "RemoteEvent", "KothUpdate")

local gameState       = "Lobby"
local kothSharedPoints = 0
local capturingPlayer  = nil
local currentMap       = nil
local playerPoints     = {}
local playerKills      = {}
local kothPart         = nil
local kothCircle       = nil

local lobbySpawns = workspace.Lobby.Spawns:GetChildren()

local function getLobbySpawn()
	return lobbySpawns[math.random(1, #lobbySpawns)].Position + Vector3.new(0, 3, 0)
end

local function spawnInLobby(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(getLobbySpawn()) end
end

local function spawnInMap(player)
	if not currentMap then return end
	local spawns = currentMap:FindFirstChild("SpawnPoints")
	if not spawns then return end
	local list = spawns:GetChildren()
	if #list == 0 then return end
	local s = list[math.random(1, #list)]
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(s.Position + Vector3.new(0, 3, 0)) end
end

local function loadMap(mapName)
	if currentMap then currentMap:Destroy(); currentMap = nil end
	local template = ServerStorage.Maps:FindFirstChild(mapName)
	if not template then return end
	currentMap = template:Clone()
	currentMap.Parent = workspace
	kothPart = currentMap:FindFirstChild("KothPart", true)
end

local function unloadMap()
	if currentMap then currentMap:Destroy(); currentMap = nil end
	if kothCircle then kothCircle:Destroy(); kothCircle = nil end
	kothPart = nil
end

local function createKothCircle()
	if not kothPart then return end
	if kothCircle then kothCircle:Destroy() end

	local circle = Instance.new("Part")
	circle.Name = "KothCircle"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(1, 16, 16)
	circle.CFrame = kothPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	circle.Anchored = true
	circle.CanCollide = false
	circle.Material = Enum.Material.Neon
	circle.BrickColor = BrickColor.new("Bright yellow")
	circle.Transparency = 0.3
	circle.Parent = currentMap

	local inner = Instance.new("Part")
	inner.Name = "KothInner"
	inner.Shape = Enum.PartType.Cylinder
	inner.Size = Vector3.new(1.1, 14, 14)
	inner.CFrame = circle.CFrame
	inner.Anchored = true
	inner.CanCollide = false
	inner.Transparency = 1
	inner.Parent = currentMap

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "KothBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = circle

	local label = Instance.new("TextLabel")
	label.Name = "PointsLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "0 / 500"
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.Parent = billboard

	kothCircle = circle
end

local function animateKothCircle()
	if not kothCircle or not kothPart then return end
	task.spawn(function()
		while gameState == "KingOfTheHill" do
			local waitTime = math.random() * 1.5 + 1.5
			task.wait(waitTime)
			if gameState ~= "KingOfTheHill" or not kothCircle then break end

			local newDiameter = math.random(12, 24)
			local offsetX = math.random(-6, 6)
			local offsetZ = math.random(-6, 6)
			local newCFrame = (kothPart.CFrame * CFrame.new(offsetX, 0, offsetZ))
				* CFrame.Angles(0, 0, math.rad(90))

			TweenService:Create(kothCircle,
				TweenInfo.new(1.0, Enum.EasingStyle.Sine),
				{ CFrame = newCFrame, Size = Vector3.new(1, newDiameter, newDiameter) }
			):Play()

			local inner = currentMap:FindFirstChild("KothInner")
			if inner then
				TweenService:Create(inner,
					TweenInfo.new(1.0, Enum.EasingStyle.Sine),
					{ CFrame = newCFrame, Size = Vector3.new(1.1, newDiameter - 2, newDiameter - 2) }
				):Play()
			end
		end
	end)
end

local function updateAll(mode, timeLeft, extraText)
	for _, p in ipairs(Players:GetPlayers()) do
		updateGUI:FireClient(p, mode, timeLeft, extraText or "")
	end
end

local function fadeAll(fadeIn)
	for _, p in ipairs(Players:GetPlayers()) do
		fadeEvent:FireClient(p, fadeIn)
	end
end

local function onCharacterAdded(player, char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		local tag = hum:FindFirstChild("creator")
		if tag and tag.Value and gameState == "Deathmatch" then
			local killer = tag.Value
			if killer ~= player then
				playerKills[killer] = (playerKills[killer] or 0) + 1
			end
		end
		task.wait(3)
		player:LoadCharacter()
		task.wait(0.5)
		if gameState == "Lobby" then
			spawnInLobby(player)
		else
			spawnInMap(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	playerPoints[player] = 0
	playerKills[player]  = 0
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
		task.wait(0.5)
		if gameState == "Lobby" then spawnInLobby(player) else spawnInMap(player) end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerPoints[player] = nil
	playerKills[player]  = nil
end)

local function runKoth()
	kothSharedPoints = 0
	capturingPlayer = nil
	local playerTime = {}

	task.spawn(function()
		while gameState == "KingOfTheHill" do
			task.wait(KOTH_TICK)
			if not kothCircle then continue end

			local circlePos = kothCircle.Position
			local radius    = kothCircle.Size.Y / 2

			local playersInCircle = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end
				local dist = (Vector3.new(root.Position.X, circlePos.Y, root.Position.Z) - circlePos).Magnitude
				if dist <= radius then table.insert(playersInCircle, p) end
			end

			if #playersInCircle == 0 then
				capturingPlayer = nil
				kothCircle.BrickColor = BrickColor.new("Bright yellow")

			elseif #playersInCircle == 1 then
				local p = playersInCircle[1]
				capturingPlayer = p
				kothCircle.BrickColor = BrickColor.new("Bright green")

				playerTime[p] = (playerTime[p] or 0) + KOTH_TICK
				local multiplier = math.min(1 + math.floor(playerTime[p] / 2), 9)
				local gained = multiplier + 1
				kothSharedPoints = math.min(kothSharedPoints + gained, KOTH_MAX_POINTS)
				playerPoints[p] = (playerPoints[p] or 0) + gained

				local addKothBind = ReplicatedStorage.DataRemotes:FindFirstChild("AddKothPoints")
				if addKothBind then addKothBind:Invoke(p, gained) end

			else
				capturingPlayer = nil
				for _, p in ipairs(playersInCircle) do playerTime[p] = 0 end
				kothCircle.BrickColor = BrickColor.new("Bright red")
			end

			local billboard = kothCircle:FindFirstChild("KothBillboard")
			local label = billboard and billboard:FindFirstChild("PointsLabel")
			if label then label.Text = math.floor(kothSharedPoints) .. " / 500" end

			updateAll("King of the Hill", nil, "")

			if kothSharedPoints >= KOTH_MAX_POINTS then
				gameState = "Results"
				return
			end
		end
	end)
end

local function showResultsScreen(mode)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(list, {
			player = p,
			score = mode == "Deathmatch"
				and (playerKills[p] or 0)
				or math.floor(playerPoints[p] or 0)
		})
	end
	table.sort(list, function(a, b) return a.score > b.score end)
	for _, p in ipairs(Players:GetPlayers()) do
		showResults:FireClient(p, list, mode)
	end
end

local function resetScores()
	kothSharedPoints = 0
	for _, p in ipairs(Players:GetPlayers()) do
		playerPoints[p] = 0
		playerKills[p]  = 0
	end
end

local mapNames = { "Map1", "Map2", "Map3", "Map4" }

local function gameLoop()
	while true do
		gameState = "Lobby"
		unloadMap()
		resetScores()
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then spawnInLobby(p) end
		end
		for t = LOBBY_TIME, 1, -1 do
			updateAll("Lobby", t, "")
			task.wait(1)
		end

		local mapName = mapNames[math.random(1, #mapNames)]
		local mode    = MODES[math.random(1, #MODES)]

		fadeAll(true); task.wait(1)
		loadMap(mapName)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then spawnInMap(p) end
		end
		task.wait(0.5); fadeAll(false)

		if mode == "Deathmatch" then
			gameState = "Deathmatch"
			for t = DEATHMATCH_TIME, 1, -1 do
				if gameState ~= "Deathmatch" then break end
				updateAll("Deathmatch", t, "")
				task.wait(1)
			end
		elseif mode == "KingOfTheHill" then
			gameState = "KingOfTheHill"
			createKothCircle()
			animateKothCircle()
			runKoth()
			while gameState == "KingOfTheHill" do
				if kothSharedPoints >= KOTH_MAX_POINTS then break end
				task.wait(1)
			end
		end

		gameState = "Results"
		fadeAll(true); task.wait(0.5)
		showResultsScreen(mode)
		task.wait(RESULTS_TIME)
		fadeAll(false); task.wait(0.5)
	end
end

task.spawn(gameLoop)
