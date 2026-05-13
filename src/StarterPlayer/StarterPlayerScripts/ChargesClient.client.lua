-- StarterPlayer > StarterPlayerScripts > ChargesClient (LocalScript)
-- Отримує ChargesSync (кількість зарядів поточного меча) і апдейтить ChargesGui.
-- Структура GUI з твого скріну:
--   StarterGui/ChargesGui/ChargesTemplate (Frame з ChargesText)
-- Клонуємо шаблон по кількості MaxCharges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChargesSync = ReplicatedStorage:WaitForChild("ChargesSync")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ChargesGui")
local template = gui:WaitForChild("ChargesTemplate")
template.Visible = false

local containers = {}

local function rebuild(max)
	for _, c in ipairs(containers) do c:Destroy() end
	containers = {}
	for i = 1, max do
		local c = template:Clone()
		c.Name = "Charge_" .. i
		c.Visible = true
		c.Position = UDim2.new(0, (i-1) * (c.Size.X.Offset + 6), 0, 0)
		c.Parent = gui
		table.insert(containers, c)
	end
end

ChargesSync.OnClientEvent:Connect(function(current, max)
	if #containers ~= max then rebuild(max) end
	for i, c in ipairs(containers) do
		local txt = c:FindFirstChild("ChargesText")
		if txt and txt:IsA("TextLabel") then
			txt.Text = (i <= current) and "●" or "○"
		end
		c.BackgroundTransparency = (i <= current) and 0.2 or 0.6
	end
end)
