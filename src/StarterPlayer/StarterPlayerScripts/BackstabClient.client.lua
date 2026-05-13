-- StarterPlayer > StarterPlayerScripts > BackstabClient (LocalScript)
-- Отримує BackstabEvent від сервера і малює Highlight на всіх ворогах
-- на час дії способки Backstab.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackstabEvent = ReplicatedStorage:WaitForChild("BackstabEvent")

local player = Players.LocalPlayer

-- Збережені хайлайти за персонажами щоб можна було зняти
local activeHighlights = {}  -- [character] = Highlight

local function highlightCharacter(char)
	if not char or activeHighlights[char] then return end
	local hl = Instance.new("Highlight")
	hl.Name = "BackstabHighlight"
	hl.FillColor = Color3.fromRGB(255, 40, 40)
	hl.OutlineColor = Color3.fromRGB(255, 200, 200)
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char
	activeHighlights[char] = hl
end

local function clearAll()
	for char, hl in pairs(activeHighlights) do
		if hl and hl.Parent then hl:Destroy() end
	end
	activeHighlights = {}
end

BackstabEvent.OnClientEvent:Connect(function(action, enemies, duration)
	if action == "Start" then
		clearAll()
		if type(enemies) == "table" then
			for _, p in ipairs(enemies) do
				if typeof(p) == "Instance" and p:IsA("Player") and p.Character then
					highlightCharacter(p.Character)
				end
			end
		end
	elseif action == "Stop" then
		clearAll()
	end
end)

-- Чистимо при смерті персонажа
player.CharacterAdded:Connect(function()
	clearAll()
end)
