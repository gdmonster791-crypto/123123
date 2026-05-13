-- StarterPlayer > StarterPlayerScripts > ChargesClient (LocalScript)
-- Показує заряди зброї з Tool-атрибутів CurrentAmmo / MaxAmmo.
-- GUI: StarterGui/ChargesGui/ChargesTemplate/ChargesText

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local chargesGui  = playerGui:WaitForChild("ChargesGui")
local template    = chargesGui:WaitForChild("ChargesTemplate")
local chargesText = template:WaitForChild("ChargesText")

local currentConnection = nil
local character = player.Character or player.CharacterAdded:Wait()

local function connectTool(tool)
	if currentConnection then
		currentConnection:Disconnect()
		currentConnection = nil
	end

	if not tool then
		chargesText.Text = "Charges: — / —"
		return
	end

	local function updateText()
		local cur = tool:GetAttribute("CurrentAmmo") or 0
		local max = tool:GetAttribute("MaxAmmo") or 0
		chargesText.Text = "Charges: " .. cur .. " / " .. max
	end

	updateText()
	currentConnection = tool:GetAttributeChangedSignal("CurrentAmmo"):Connect(updateText)
end

local function findTool()
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped then return equipped end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then return backpack:FindFirstChildOfClass("Tool") end
	return nil
end

local function setupCharacter(char)
	character = char
	connectTool(nil)

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then connectTool(child) end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.1)
			local backpack = player:FindFirstChild("Backpack")
			connectTool(backpack and backpack:FindFirstChildOfClass("Tool") or nil)
		end
	end)

	-- Якщо Tool вже є
	task.wait(0.3)
	connectTool(findTool())
end

-- Ініціалізація
setupCharacter(character)

player.CharacterAdded:Connect(function(char)
	setupCharacter(char)
end)
