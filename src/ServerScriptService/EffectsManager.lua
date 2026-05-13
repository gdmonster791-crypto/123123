-- ServerScriptService > EffectsManager (ModuleScript)
-- Єдиний модуль керування статус-ефектами.
-- Підключається з WeaponsManager/AbilityManager: EffectsManager.Apply(target, "Weakness", 7)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local EffectsConfig = require(ReplicatedStorage.Modules.EffectsConfig)

local EffectsManager = {}

-- Створюємо RemoteEvent для клієнта (візуал/сліпота)
local applyEffectRemote = ReplicatedStorage:FindFirstChild("ApplyEffect")
if not applyEffectRemote then
	applyEffectRemote = Instance.new("RemoteEvent")
	applyEffectRemote.Name = "ApplyEffect"
	applyEffectRemote.Parent = ReplicatedStorage
end

-- active[player] = { [effectId] = { Expires = t, Config = cfg } }
local active = {}

local DEFAULT_WALK_SPEED = 16

local function getActive(player)
	if not active[player] then active[player] = {} end
	return active[player]
end

-- Пересчитуємо стату гравця (швидкість, мульти урона) на основі активних ефектів
local function recompute(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local speedMult   = 1
	local damageOut   = 1
	local damageIn    = 1
	local stunned     = false
	local blockHeal   = false

	for _, e in pairs(getActive(player)) do
		local cfg = e.Config
		if cfg.SpeedMult     then speedMult = speedMult * cfg.SpeedMult end
		if cfg.DamageOutMult then damageOut = damageOut * cfg.DamageOutMult end
		if cfg.DamageInMult  then damageIn  = damageIn * cfg.DamageInMult end
		if cfg.Stunned       then stunned = true end
		if cfg.BlockHeal     then blockHeal = true end
	end

	hum.WalkSpeed = DEFAULT_WALK_SPEED * speedMult
	if stunned then hum.WalkSpeed = 0 end

	-- Зберігаємо модифікатори в атрибутах, щоб WeaponsManager/AbilityManager могли читати
	player:SetAttribute("DamageOutMult", damageOut)
	player:SetAttribute("DamageInMult",  damageIn)
	player:SetAttribute("Stunned",       stunned)
	player:SetAttribute("BlockHeal",     blockHeal)
end

-- Публічне API

function EffectsManager.Apply(player, effectId, duration)
	if not player or not player.Parent then return end
	local cfg = EffectsConfig.Get(effectId)
	if not cfg then warn("[EffectsManager] Unknown effect: " .. tostring(effectId)); return end

	local eff = getActive(player)
	eff[effectId] = {
		Config  = cfg,
		Expires = os.clock() + (duration or 5),
	}
	recompute(player)

	-- Клієнту — для візуалу (сліпота, бордюр екрана, іконка)
	applyEffectRemote:FireClient(player, "Add", effectId, duration or 5, cfg)
end

function EffectsManager.Remove(player, effectId)
	local eff = active[player]
	if not eff then return end
	if eff[effectId] then
		eff[effectId] = nil
		recompute(player)
		applyEffectRemote:FireClient(player, "Remove", effectId)
	end
end

function EffectsManager.Has(player, effectId)
	local eff = active[player]
	return eff and eff[effectId] ~= nil
end

function EffectsManager.Clear(player)
	active[player] = {}
	recompute(player)
	applyEffectRemote:FireClient(player, "Clear")
end

function EffectsManager.GetDamageOutMult(player)
	return player:GetAttribute("DamageOutMult") or 1
end

function EffectsManager.GetDamageInMult(player)
	return player:GetAttribute("DamageInMult") or 1
end

function EffectsManager.IsStunned(player)
	return player:GetAttribute("Stunned") == true
end

function EffectsManager.CanHeal(player)
	return player:GetAttribute("BlockHeal") ~= true
end

-- Тіки DOT/HOT + прибирання експайрнутих ефектів
local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 0.5 then return end
	accum = 0

	local now = os.clock()
	for player, eff in pairs(active) do
		if not player.Parent then active[player] = nil continue end
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		local changed = false
		for id, data in pairs(eff) do
			if now >= data.Expires then
				eff[id] = nil
				changed = true
				applyEffectRemote:FireClient(player, "Remove", id)
			else
				local cfg = data.Config
				if hum and hum.Health > 0 then
					if cfg.DamagePerSecond then
						hum:TakeDamage(cfg.DamagePerSecond * 0.5)
					end
					if cfg.HealPerSecond and EffectsManager.CanHeal(player) then
						hum.Health = math.min(hum.MaxHealth, hum.Health + cfg.HealPerSecond * 0.5)
					end
				end
			end
		end
		if changed then recompute(player) end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	active[player] = nil
end)

return EffectsManager
