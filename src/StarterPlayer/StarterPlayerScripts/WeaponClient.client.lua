-- StarterPlayer > StarterPlayerScripts > WeaponClient (LocalScript)
-- ЛКМ = удар (шукає ціль перед гравцем через raycast з камери)
-- E   = спец-абілка зброї (Backstab для Kitchen Knife)
-- Працює з third-person камерою (прицільна точка по центру екрана).

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeaponHit   = ReplicatedStorage:WaitForChild("WeaponHit")
local SpecialUsed = ReplicatedStorage:WaitForChild("SpecialUsed")

local HIT_RANGE = 10  -- studs, максимальна дальність удару

local nextClick = 0
local CLICK_CD  = 0.3  -- мінімальний інтервал між кліками на клієнті (сервер валідує точніше)

-- Знайти ціль під прицілом (центр екрана)
local function findTarget()
	local char = player.Character
	if not char then return nil end

	-- Промінь з центра екрана (де крестик)
	local viewportSize = camera.ViewportSize
	local centerRay = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local result = workspace:Raycast(centerRay.Origin, centerRay.Direction * HIT_RANGE, params)
	if not result then return nil end

	-- Шукаємо модель персонажа
	local hit = result.Instance
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then return nil end

	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if not targetPlayer or targetPlayer == player then return nil end

	-- Додаткова перевірка: чи ціль дійсно близько до нас
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	local tgRoot = model:FindFirstChild("HumanoidRootPart")
	if not myRoot or not tgRoot then return nil end
	if (myRoot.Position - tgRoot.Position).Magnitude > HIT_RANGE + 2 then return nil end

	return targetPlayer
end

-- Альтернативний пошук: якщо raycast не знайшов нікого, шукаємо найближчого перед гравцем
local function findTargetNearby()
	local char = player.Character
	if not char then return nil end
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local lookDir = camera.CFrame.LookVector
	local bestTarget = nil
	local bestScore  = math.huge  -- менше = краще

	for _, p in ipairs(Players:GetPlayers()) do
		if p == player then continue end
		local pChar = p.Character
		if not pChar then continue end
		local pRoot = pChar:FindFirstChild("HumanoidRootPart")
		if not pRoot then continue end
		local hum = pChar:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end

		local toTarget = (pRoot.Position - myRoot.Position)
		local dist = toTarget.Magnitude
		if dist > HIT_RANGE then continue end

		-- Перевіряємо що ціль приблизно перед нами (dot product)
		local dot = lookDir:Dot(toTarget.Unit)
		if dot < 0.3 then continue end  -- мінімум ~72° кут від погляду

		-- Score: чим ближче до центра і чим ближче - тим краще
		local score = dist * (2 - dot)
		if score < bestScore then
			bestScore  = score
			bestTarget = p
		end
	end

	return bestTarget
end

local function tryAttack()
	local now = os.clock()
	if now < nextClick then return end
	nextClick = now + CLICK_CD

	-- Перевіряємо що Tool екіпований
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	-- Шукаємо ціль
	local target = findTarget() or findTargetNearby()
	if not target then return end

	WeaponHit:FireServer(target)
end

local function useSpecial()
	-- Перевіряємо Tool
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	SpecialUsed:FireServer()
end

-- === INPUT ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryAttack()
	elseif input.KeyCode == Enum.KeyCode.E then
		useSpecial()
	end
end)
