-- ServerScriptService > AbilityManager (Script)
-- Основні (купуються) абілки гравця: Щит, Злість, Бігун.
-- Клієнт шле AbilityUsed:FireServer() коли натиснув Q (або інший біндінг).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilitiesConfig = require(ReplicatedStorage.Modules.AbilitiesConfig)
local EffectsManager  = require(script.Parent.EffectsManager)

local AbilityUsed = ReplicatedStorage:WaitForChild("AbilityUsed")

-- cd[player] = { [id] = expiresAt }
local cd = {}
local function getCD(p)
	if not cd[p] then cd[p] = {} end
	return cd[p]
end

local function dashPlayer(player, distance)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local dir = root.CFrame.LookVector
	root.CFrame = root.CFrame + dir * distance
end

AbilityUsed.OnServerEvent:Connect(function(player, abilityId)
	if EffectsManager.IsStunned(player) then return end
	local cfg = AbilitiesConfig.Get(abilityId); if not cfg then return end

	-- Перевіряємо що абілка екіпірована у гравця
	local data = _G.DataAPI and _G.DataAPI.GetSnapshot(player)
	if not data or data.EquippedAbility ~= abilityId then return end

	local pcd = getCD(player)
	local now = os.clock()
	if (pcd[abilityId] or 0) > now then return end
	pcd[abilityId] = now + cfg.Cooldown

	if abilityId == "Shield" then
		-- Імунітет = DamageInMult 0 через псевдо-ефект
		-- Додаємо тимчасовий ефект напряму через EffectsManager із кастомом.
		-- Найпростіше: створимо ефект Shield on-the-fly:
		EffectsManager.Apply(player, "Shield", cfg.Duration)
	elseif abilityId == "Rage" then
		EffectsManager.Apply(player, "Rage", cfg.Duration)
	elseif abilityId == "Runner" then
		dashPlayer(player, cfg.DashDistance)
		EffectsManager.Apply(player, "Haste", cfg.Duration) -- +10% бейз
		-- якщо потрібно саме +20% — можна додати окремий ефект RunnerHaste
	end
end)

Players.PlayerRemoving:Connect(function(p) cd[p] = nil end)
