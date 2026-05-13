-- ServerScriptService > WeaponsManager (ModuleScript)
-- Серверна логіка зброї: заряди, валідація ударів, Backstab.
-- Клієнт шле WeaponHit (ціль) та SpecialUsed (спец-абілка).
-- WeaponsManager також оновлює Tool-атрибути CurrentAmmo/MaxAmmo для ChargesClient.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")

local WeaponsConfig  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponsConfig"))
local EffectsManager = require(script.Parent:WaitForChild("EffectsManager"))

local WeaponsManager = {}

-- === REMOTES ===
local function ensureRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = ReplicatedStorage end
	return r
end

local WeaponHit       = ensureRemote("WeaponHit",   "RemoteEvent")
local SpecialUsed     = ensureRemote("SpecialUsed",  "RemoteEvent")
local UpdateCooldown  = ensureRemote("UpdateCooldownEvent", "RemoteEvent")  -- шлемо клієнту кд абілки

-- === STATE ===
-- state[player] = { Equipped, Charges, NextAttack, NextCharge, AbilityCD, BackstabUntil, BackstabHits }
local state = {}

local function getState(player)
	if not state[player] then
		state[player] = {
			Equipped      = "KitchenKnife",
			Charges       = 5,
			NextAttack    = 0,
			NextCharge    = 0,
			AbilityCD     = 0,
			BackstabUntil = 0,
			BackstabHits  = {},  -- [targetUserId] = hitCount
		}
	end
	return state[player]
end

-- === TOOL ATTRIBUTE SYNC (для ChargesClient) ===
local function syncCharges(player, s)
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChildOfClass("Tool"))
	if tool then
		tool:SetAttribute("CurrentAmmo", s.Charges)
		tool:SetAttribute("MaxAmmo", WeaponsConfig.Get(s.Equipped).MaxCharges)
	end
end

-- === РЕГЕНЕРАЦІЯ ЗАРЯДІВ ===
local regenAccum = 0
RunService.Heartbeat:Connect(function(dt)
	regenAccum += dt
	if regenAccum < 0.25 then return end -- перевіряємо 4 рази в секунду
	regenAccum = 0

	local now = os.clock()
	for player, s in pairs(state) do
		if not player.Parent then state[player] = nil continue end
		local cfg = WeaponsConfig.Get(s.Equipped)
		if not cfg then continue end
		if s.Charges < cfg.MaxCharges and now >= s.NextCharge then
			s.Charges += 1
			s.NextCharge = now + cfg.ChargeCooldown
			syncCharges(player, s)
		end
	end
end)

-- === ДОПОМІЖНЕ ===
local function applyEffects(target, effectIds, duration)
	if not effectIds then return end
	for _, id in ipairs(effectIds) do
		EffectsManager.Apply(target, id, duration or 5)
	end
end

local function dealDamage(attacker, target, baseDmg)
	local char = target.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return 0 end

	local outMult = EffectsManager.GetDamageOutMult(attacker)
	local inMult  = EffectsManager.GetDamageInMult(target)
	local final   = baseDmg * outMult * inMult

	hum:TakeDamage(final)

	-- Тег вбивці
	local tag = hum:FindFirstChild("creator")
	if not tag then
		tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Parent = hum
		Debris:AddItem(tag, 5)
	end
	tag.Value = attacker

	-- Тег зброї (для осколків в майбутньому)
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
	s.Equipped   = weaponId
	s.Charges    = cfg.MaxCharges
	s.NextCharge = os.clock() + cfg.ChargeCooldown
	s.AbilityCD  = 0
	s.BackstabUntil = 0
	s.BackstabHits  = {}
	syncCharges(player, s)
end

function WeaponsManager.GetEquipped(player)
	return getState(player).Equipped
end

-- === ОБРОБКА УДАРА (LMB) ===

WeaponHit.OnServerEvent:Connect(function(player, targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	if not targetPlayer.Character then return end
	if player == targetPlayer then return end
	if EffectsManager.IsStunned(player) then return end

	local s = getState(player)
	local cfg = WeaponsConfig.Get(s.Equipped)
	if not cfg then return end

	local now = os.clock()

	-- Кулдаун між ударами
	if now < s.NextAttack then return end
	-- Заряди
	if s.Charges <= 0 then return end

	-- Анти-чіт: перевірка відстані
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local tgRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot or not tgRoot then return end
	if (myRoot.Position - tgRoot.Position).Magnitude > 12 then return end

	-- Забираємо заряд
	s.Charges -= 1
	s.NextAttack = now + cfg.AttackSpeed
	if s.Charges < cfg.MaxCharges and s.NextCharge <= now then
		s.NextCharge = now + cfg.ChargeCooldown
	end
	syncCharges(player, s)

	-- Визначаємо урон
	local baseDmg = cfg.Damage
	local isBackstabActive = s.BackstabUntil > now

	if isBackstabActive then
		-- Backstab режим: макс 2 удари на ціль
		local tid = targetPlayer.UserId
		s.BackstabHits[tid] = (s.BackstabHits[tid] or 0)
		if s.BackstabHits[tid] >= (cfg.Ability.MaxHitsPerTarget or 2) then
			-- Ціль вже отримала макс ударів — не б'ємо
			-- Повертаємо заряд
			s.Charges += 1
			syncCharges(player, s)
			return
		end
		s.BackstabHits[tid] += 1
		baseDmg = cfg.Ability.HitDamage or baseDmg
	end

	-- Наносимо урон
	local actualDmg = dealDamage(player, targetPlayer, baseDmg)

	-- Ефекти Backstab (Vulnerability + TearWound)
	if isBackstabActive then
		applyEffects(targetPlayer, cfg.Ability.AppliesEffects, 7)
	end

	-- Трекаємо урон для DataManager (XP/монети)
	local dataRemotes = ReplicatedStorage:FindFirstChild("DataRemotes")
	local giveDamage  = dataRemotes and dataRemotes:FindFirstChild("GiveDamage")
	if giveDamage then
		giveDamage:Fire(player, actualDmg)
	end
end)

-- === СПЕЦ-АБІЛКА (E) ===

SpecialUsed.OnServerEvent:Connect(function(player)
	if EffectsManager.IsStunned(player) then return end

	local s = getState(player)
	local cfg = WeaponsConfig.Get(s.Equipped)
	if not cfg or not cfg.Ability then return end
	local a = cfg.Ability

	local now = os.clock()
	if s.AbilityCD > now then return end
	s.AbilityCD = now + a.Cooldown

	-- Backstab: швидкість + підсвітка + 2 удари на ціль
	if a.Id == "Backstab" then
		s.BackstabUntil = now + a.Duration
		s.BackstabHits  = {}
		EffectsManager.Apply(player, "Haste", a.Duration)
		-- Кажемо клієнту про кулдаун (для GUI)
		UpdateCooldown:FireClient(player, a.Cooldown)
	end
end)

-- === CLEANUP ===

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local s = getState(player)
		s.BackstabHits  = {}
		s.BackstabUntil = 0
		-- Ресет зарядів при респавні
		local cfg = WeaponsConfig.Get(s.Equipped)
		if cfg then
			s.Charges    = cfg.MaxCharges
			s.NextCharge = os.clock() + cfg.ChargeCooldown
		end
		task.wait(0.1)
		syncCharges(player, s)
	end)
end)

return WeaponsManager
