-- StarterPlayer > StarterPlayerScripts > AbilityClient (LocalScript)
-- Натискання Q — використати екіпіровану абілку гравця.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityUsed   = ReplicatedStorage:WaitForChild("AbilityUsed")
local GetPlayerData = ReplicatedStorage:WaitForChild("GetPlayerData")

local player = Players.LocalPlayer

local function fire()
	local data = GetPlayerData:InvokeServer()
	if not data or not data.EquippedAbility then return end
	AbilityUsed:FireServer(data.EquippedAbility)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Q then
		fire()
	end
end)
