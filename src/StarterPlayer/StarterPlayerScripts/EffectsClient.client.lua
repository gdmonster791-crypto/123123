-- StarterPlayer > StarterPlayerScripts > EffectsClient (LocalScript)
-- Отримує ApplyEffect (Add/Remove/Clear) і малює візуал.
-- Підсвітки, сліпота, індикатори — все на клієнті.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local ApplyEffect = ReplicatedStorage:WaitForChild("ApplyEffect")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Контейнер для іконок активних ефектів (можеш замінити на твій GUI)
local container = Instance.new("ScreenGui")
container.Name = "EffectsHUD"
container.ResetOnSpawn = false
container.Parent = playerGui

local list = Instance.new("Frame")
list.Size = UDim2.new(0, 220, 0, 40)
list.Position = UDim2.new(0, 20, 0, 20)
list.BackgroundTransparency = 1
list.Parent = container
local layout = Instance.new("UIListLayout", list)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 4)

local icons = {}

local function addIcon(id, duration, cfg)
	if icons[id] then icons[id]:Destroy() end
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 36, 0, 36)
	f.BackgroundColor3 = (cfg and cfg.Color) or Color3.fromRGB(255,255,255)
	f.BorderSizePixel = 0
	f.Parent = list

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.Text = tostring(math.ceil(duration))
	lbl.Parent = f

	icons[id] = f
	task.spawn(function()
		local t = duration
		while t > 0 and icons[id] == f do
			task.wait(0.5); t -= 0.5
			if icons[id] == f then lbl.Text = tostring(math.max(0, math.ceil(t))) end
		end
		if icons[id] == f then f:Destroy(); icons[id] = nil end
	end)
end

local function removeIcon(id)
	if icons[id] then icons[id]:Destroy(); icons[id] = nil end
end

-- Сліпота — зменшуємо яскравість екрана
local blindBlur = nil
local function setBlindness(on)
	if on and not blindBlur then
		blindBlur = Instance.new("BlurEffect")
		blindBlur.Size = 24
		blindBlur.Parent = Lighting
	elseif not on and blindBlur then
		blindBlur:Destroy(); blindBlur = nil
	end
end

ApplyEffect.OnClientEvent:Connect(function(action, id, duration, cfg)
	if action == "Add" then
		addIcon(id, duration or 5, cfg)
		if id == "Blindness" then setBlindness(true) end
	elseif action == "Remove" then
		removeIcon(id)
		if id == "Blindness" then setBlindness(false) end
	elseif action == "Clear" then
		for k, v in pairs(icons) do v:Destroy() end
		icons = {}
		setBlindness(false)
	end
end)
