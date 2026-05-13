-- ServerScriptService > AbilityManager (Script)
-- Основні абілки гравця (не залежать від меча).
-- Поки що: Shield (імунітет 5 секунд).
-- Клієнт шле AbilityUsed:FireServer(abilityId) по Q.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectsManager = require(script.Parent:WaitForChild("EffectsManager"))

local function ensure(parent, class, name)
	local ex = parent:FindFirstChild(name)
	if ex then return ex end
	local o = Instance.new(class); o.Name = name; o.Parent = parent
	return o
end

local AbilityUsed     = ensure(ReplicatedStorage, "RemoteEvent", "AbilityUsed")
local UpdateCooldown  = ensure(ReplicatedStorage, "RemoteEvent", "UpdateCooldownEvent")

-- Конфіг абілок
local ABILITIES = {
	Shield = {
		Id       = "Shield",
		Cooldown = 20,
		Duration = 5,
	},
}

-- cd[player] = { [abilityId] = expiresAt }
local cd = {}
local function getCD(p)
	if not cd[p] then cd[p] = {} end
	return cd[p]
end

AbilityUsed.OnServerEvent:Connect(function(player, abilityId)
	if EffectsManager.IsStunned(player) then return end

	local cfg = ABILITIES[abilityId]
	if not cfg then return end

	-- Перевіряємо що абілка екіпірована
	local api = _G.DataAPI
	if not api then return end
	local data = api.GetSnapshot(player)
	if not data or data.EquippedAbility ~= abilityId then return end

	-- Кулдаун
	local pcd = getCD(player)
	local now = os.clock()
	if (pcd[abilityId] or 0) > now then return end
	pcd[abilityId] = now + cfg.Cooldown

	-- Застосовуємо ефект
	if abilityId == "Shield" then
		EffectsManager.Apply(player, "Shield", cfg.Duration)
	end

	-- Кажемо клієнту показати кулдаун (тип "Ability")
	UpdateCooldown:FireClient(player, "Ability", cfg.Cooldown)
end)

Players.PlayerRemoving:Connect(function(p) cd[p] = nil end)
