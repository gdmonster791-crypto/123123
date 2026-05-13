-- StarterPlayer > StarterPlayerScripts > AbilityClient (LocalScript)
-- Q = використати екіпіровану абілку гравця (Shield для релізу).
-- Відправляє AbilityUsed:FireServer(abilityId)
-- Показує кулдаун в PlayerAbilityGui.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AbilityUsed      = ReplicatedStorage:WaitForChild("AbilityUsed")
local GetPlayerData    = ReplicatedStorage:WaitForChild("GetPlayerData")
local UpdateCooldown   = ReplicatedStorage:WaitForChild("UpdateCooldownEvent")

-- GUI елементи (PlayerAbilityGui з скріну)
local abilityGui    = playerGui:WaitForChild("PlayerAbilityGui")
local cooldownText  = abilityGui:FindFirstChild("CooldownText", true)

local isOnCooldown = false

local function startCooldownDisplay(cd)
	if not cooldownText then return end
	isOnCooldown = true
	cooldownText.Visible = true

	task.spawn(function()
		local remaining = cd
		while remaining > 0 do
			cooldownText.Text = math.ceil(remaining) .. "с"
			task.wait(0.5)
			remaining -= 0.5
		end
		cooldownText.Text = ""
		cooldownText.Visible = false
		isOnCooldown = false
	end)
end

-- Сервер надсилає кулдаун: (type, cd) де type = "Ability" | "Weapon"
UpdateCooldown.OnClientEvent:Connect(function(cdType, cd)
	if cdType == "Ability" then
		startCooldownDisplay(cd)
	end
	-- Weapon cooldown для Backstab обробляє інший клієнт (опціонально)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= Enum.KeyCode.Q then return end
	if isOnCooldown then return end

	-- Перевіряємо що абілка є
	local data = GetPlayerData:InvokeServer()
	if not data or not data.EquippedAbility then return end

	AbilityUsed:FireServer(data.EquippedAbility)
end)
