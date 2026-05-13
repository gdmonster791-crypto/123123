-- ServerScriptService > WeaponsManager (ModuleScript)
-- Валідація ударів, заряди, спец-абілки мечів.
-- Клієнт шле WeaponHit (вже є) та SpecialUsed (новий).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local WeaponsConfig  = require(ReplicatedStorage.Modules.WeaponsConfig)
local EffectsManager = require(script.Parent.EffectsManager)

local WeaponsManager = {}

-- state[player] = {
--   Equipped      = "KitchenKnife",
--   Charges       = 5,
--   NextAttack    = 0,                 -- os.clock
--   NextCharge    = 0,
--   AbilityCD     = { [id] = expireAt },
--   SpikeStacks   = { [targetUserId] = count },
--   BackstabHits  = { [targetUserId] = count },  -- на час способки
--   BackstabUntil = 0,
--   StealthUntil  = 0,
--   CloneSpawnedThisMatch = 0,
-- }
local state = {}

local function getState(player)
	if not state[player] then
		state[player] = {
			Equipped = "KitchenKnife",
			Charges  = 5,
			NextAttack = 0,
			NextCharge = 0,
			AbilityCD = {},
			SpikeStacks = {},
			BackstabHits = {},
			BackstabUntil = 0,
			StealthUntil = 0,
			CloneSpawnedThisMatch = 0,
			HitStreak = {}, -- { [targetUserId] = nPrevHits } для SpikedBlade
		}
	end
	return state[player]
end

-- Remote events (створимо якщо нема)
local function ensureRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local WeaponHit    = ensureRemote("WeaponHit", "RemoteEvent")
local SpecialUsed  = ensureRemote("SpecialUsed", "RemoteEvent")
local WeaponEquip  = ensureRemote("WeaponEquip", "RemoteEvent")
local ChargesSync  = ensureRemote("ChargesSync", "RemoteEvent")

-- Регенерація зарядів
local function regenLoop()
	while true do
		RunService.Heartbeat:Wait()
		local now = os.clock()
		for player, s in pairs(state) do
			if not player.Parent then state[player] = nil continue end
			local cfg = WeaponsConfig.Get(s.Equipped)
			if cfg and s.Charges < cfg.MaxCharges and now >= s.NextCharge then
				s.Charges += 1
				s.NextCharge = now + cfg.ChargeCooldown
				ChargesSync:FireClient(player, s.Charges, cfg.MaxCharges)
			end
		end
	end
end
task.spawn(regenLoop)

-- Допоміжне: застосувати ефекти зі списку до цілі
local function applyEffects(target, effectIds, duration)
	if not effectIds then return end
	for _, id in ipairs(effectIds) do
		EffectsManager.Apply(target, id, duration or 5)
	end
end

-- Урон з урахуванням DamageOut і DamageIn
local function damage(attacker, target, base)
	local char = target.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return 0 end

	local outMult = EffectsManager.GetDamageOutMult(attacker)
	local inMult  = EffectsManager.GetDamageInMult(target)
	local final   = base * outMult * inMult

	hum:TakeDamage(final)

	-- Тег вбивці (для DataManager/GameManager)
	local tag = hum:FindFirstChild("creator")
	if not tag then
		tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Parent = hum
		game:GetService("Debris"):AddItem(tag, 5)
	end
	tag.Value = attacker
	-- Який меч задав фінальний хіт (для дропу осколків)
	local wtag = hum:FindFirstChild("creatorWeapon")
	if not wtag then
		wtag = Instance.new("StringValue")
		wtag.Name = "creatorWeapon"
		wtag.Parent = hum
	end
	wtag.Value = getState(attacker).Equipped

	return final
end

-- === ПУБЛІЧНЕ API ===

function WeaponsManager.Equip(player, weaponId)
	local cfg = WeaponsConfig.Get(weaponId)
	if not cfg then return end
	local s = getState(player)
	s.Equipped = weaponId
	s.Charges  = cfg.MaxCharges
	s.NextCharge = os.clock() + cfg.ChargeCooldown
	ChargesSync:FireClient(player, s.Charges, cfg.MaxCharges)
end

function WeaponsManager.GetEquipped(player)
	return getState(player).Equipped
end

-- === ОБРОБКА УДАРА ===

WeaponHit.OnServerEvent:Connect(function(player, targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	if EffectsManager.IsStunned(player) then return end
	if player == targetPlayer then return end

	local s = getState(player)
	local cfg = WeaponsConfig.Get(s.Equipped)
	if not cfg then return end

	local now = os.clock()
	-- Кулдаун між ударами
	if now < s.NextAttack then return end
	-- Заряди
	if s.Charges <= 0 then return end

	-- Перевірка відстані (анти-чіт)
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local tgRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot or not tgRoot then return end
	if (myRoot.Position - tgRoot.Position).Magnitude > 10 then return end

	-- Забираємо заряд
	s.Charges -= 1
	s.NextAttack = now + cfg.AttackSpeed
	if s.Charges < cfg.MaxCharges then
		s.NextCharge = math.max(s.NextCharge, now + cfg.ChargeCooldown)
	end
	ChargesSync:FireClient(player, s.Charges, cfg.MaxCharges)

	-- Рахуємо базовий урон
	local baseDmg = cfg.Damage

	-- SpikedBlade: +1 за стріку
	if cfg.DamagePerHitStack then
		local tid = targetPlayer.UserId
		s.HitStreak[tid] = (s.HitStreak[tid] or 0) + 1
		baseDmg = cfg.Damage + cfg.DamagePerHitStack * s.HitStreak[tid]
	end

	-- Backstab режим
	if s.BackstabUntil > now then
		local tid = targetPlayer.UserId
		s.BackstabHits[tid] = s.BackstabHits[tid] or 0
		local maxHits = cfg.Ability.MaxHitsPerTarget or 2
		if s.BackstabHits[tid] >= maxHits then return end
		s.BackstabHits[tid] += 1
		baseDmg = cfg.Ability.HitDamage or baseDmg
	end

	-- Stealth: подвійний урон + накидає спешку на себе + знімає прозорість
	if s.StealthUntil > now then
		baseDmg = baseDmg * (cfg.Ability.HitDamageMultiplier or 2)
		s.StealthUntil = 0 -- бекдор: починаючи бити — видимий
		local selfEff = cfg.Ability.OnHitAppliesToSelf
		if selfEff then
			EffectsManager.Apply(player, selfEff.Effect, selfEff.Duration)
		end
		-- прозорість відновиться через Heartbeat-лоп нижче
	end

	local actualDmg = damage(player, targetPlayer, baseDmg)

	-- Накладаємо ефекти мечу
	applyEffects(targetPlayer, cfg.AppliesEffects, 5)

	-- Backstab — накладає уязвимість і рвану рану
	if s.BackstabUntil > now then
		applyEffects(targetPlayer, cfg.Ability.AppliesEffects, 7)
	end

	-- ElectroHammer: mark + ланцюг
	if cfg.ElectroMark then
		EffectsManager.Apply(targetPlayer, "ElectroMark", cfg.ElectroMark.Duration)
		-- Ланцюг до ближніх
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= targetPlayer and other ~= player and other.Character then
				local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
				if oRoot and (oRoot.Position - tgRoot.Position).Magnitude <= cfg.ElectroMark.ChainRadius then
					damage(player, other, cfg.ElectroMark.ChainDamage)
				end
			end
		end
	end

	-- Трек урона для DataManager (XP/монети)
	local data = ReplicatedStorage:FindFirstChild("DataRemotes")
	local giveDamage = data and data:FindFirstChild("GiveDamage")
	if giveDamage then giveDamage:Fire(player, actualDmg) end
end)

-- === СПЕЦ-АБІЛКА ===

SpecialUsed.OnServerEvent:Connect(function(player, payload)
	if EffectsManager.IsStunned(player) then return end
	local s = getState(player)
	local cfg = WeaponsConfig.Get(s.Equipped)
	if not cfg then return end
	local a = cfg.Ability
	if not a then return end

	local now = os.clock()
	if (s.AbilityCD[a.Id] or 0) > now then return end
	s.AbilityCD[a.Id] = now + a.Cooldown

	-- Backstab
	if a.Id == "Backstab" then
		s.BackstabUntil = now + a.Duration
		s.BackstabHits  = {}
		EffectsManager.Apply(player, "Haste", a.Duration) -- приблизно 10% (Haste у конфігу 1.10)

	-- Throw (клієнт передає Ray/позицію; ми шукаємо найближчого гравця вздовж променя)
	elseif a.Id == "Throw" then
		local origin, direction = payload and payload.Origin, payload and payload.Direction
		if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
		direction = direction.Unit * 120
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local result = workspace:Raycast(origin, direction, params)
		if result and result.Instance then
			local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
			local hitPlr  = hitChar and Players:GetPlayerFromCharacter(hitChar)
			if hitPlr and hitPlr ~= player then
				damage(player, hitPlr, a.Damage)
				applyEffects(hitPlr, a.AppliesEffects, a.EffectDuration)
			end
		end

	-- Stealth
	elseif a.Id == "Stealth" then
		s.StealthUntil = now + a.Duration
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.LocalTransparencyModifier = a.Transparency
					part.Transparency = a.Transparency
				end
			end
			-- Знімемо прозорість після закінчення
			task.delay(a.Duration, function()
				if s.StealthUntil <= os.clock() then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
						end
					end
				end
			end)
		end

	-- Spike (дистанційний удар по цілі з шипами)
	elseif a.Id == "Spike" then
		local targetPlr = payload and payload.Target
		if typeof(targetPlr) ~= "Instance" or not targetPlr:IsA("Player") then return end
		if not EffectsManager.Has(targetPlr, "Spikes") then return end
		damage(player, targetPlr, a.Damage)
		EffectsManager.Apply(targetPlr, "Spikes", a.EffectDuration)

	-- ElectroShock — станить усіх з міткою
	elseif a.Id == "ElectroShock" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and EffectsManager.Has(p, "ElectroMark") then
				for _, fx in ipairs(a.AppliesEffects) do
					EffectsManager.Apply(p, fx, a.Duration)
				end
			end
		end

	-- Clone — клієнт шле або Place або Teleport
	elseif a.Id == "Clone" then
		-- Повна логіка клонів заслуговує окремого модуля — залишимо як TODO
		-- Передбачено: payload.Action = "Place" | "Teleport"
		-- Реалізуємо в наступній ітерації.
	end

end)

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
end)

-- Скидання стріків при респавні
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local s = getState(player)
		s.HitStreak = {}
		s.BackstabHits = {}
		s.BackstabUntil = 0
		s.StealthUntil = 0
	end)
end)

return WeaponsManager
