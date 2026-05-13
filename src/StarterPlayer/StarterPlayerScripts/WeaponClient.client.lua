-- StarterPlayer > StarterPlayerScripts > WeaponClient (LocalScript)
-- Універсальний клієнтський контролер для будь-якого меча.
-- Читає WeaponsConfig, шле WeaponHit / SpecialUsed.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsConfig = require(ReplicatedStorage.Modules.WeaponsConfig)

local WeaponHit   = ReplicatedStorage:WaitForChild("WeaponHit")
local SpecialUsed = ReplicatedStorage:WaitForChild("SpecialUsed")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local activeTool = nil
local nextClick  = 0

local function currentWeaponId()
	-- Tool.Name має збігатись з WeaponsConfig ID (наприклад, "KitchenKnife")
	return activeTool and activeTool.Name or nil
end

local function tryHit()
	local id = currentWeaponId(); if not id then return end
	local cfg = WeaponsConfig.Get(id); if not cfg then return end
	local now = os.clock()
	if now < nextClick then return end
	nextClick = now + cfg.AttackSpeed

	-- Пошук цілі перед собою (raycast з камери)
	local mouse = player:GetMouse()
	local origin = camera.CFrame.Position
	local direction = (mouse.Hit.Position - origin).Unit * 10
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local result = workspace:Raycast(origin, direction, params)
	if not result then return end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local target = model and Players:GetPlayerFromCharacter(model)
	if not target then return end

	WeaponHit:FireServer(target)
end

local function useSpecial()
	local id = currentWeaponId(); if not id then return end
	local cfg = WeaponsConfig.Get(id); if not cfg or not cfg.Ability then return end

	local payload = {}
	if cfg.Ability.Id == "Throw" then
		payload.Origin    = camera.CFrame.Position
		payload.Direction = camera.CFrame.LookVector
	elseif cfg.Ability.Id == "Spike" then
		-- клієнт шукає найближчого ігрока з шипами під курсором
		local mouse = player:GetMouse()
		local target = mouse.Target and mouse.Target:FindFirstAncestorOfClass("Model")
		payload.Target = target and Players:GetPlayerFromCharacter(target)
	end
	SpecialUsed:FireServer(payload)
end

player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then activeTool = c end end)
	char.ChildRemoved:Connect(function(c) if c == activeTool then activeTool = nil end end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryHit()
	elseif input.KeyCode == Enum.KeyCode.E then
		useSpecial()
	end
end)
