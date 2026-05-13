-- ServerScriptService > DataManager (Script)
-- Єдина точка правди по даних гравця: leaderstats, XP/рівень, монети,
-- душі, осколки, куплені мечі/абілки, статистика по зброї.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

local ResourcesConfig = require(ReplicatedStorage.Modules.ResourcesConfig)
local WeaponsConfig   = require(ReplicatedStorage.Modules.WeaponsConfig)

-- === XP ===
local function xpForLevel(level) return 100 + (level - 1) * 50 end

-- === REMOTES ===
local dataRemotes = ReplicatedStorage:FindFirstChild("DataRemotes")
if not dataRemotes then
	dataRemotes = Instance.new("Folder"); dataRemotes.Name = "DataRemotes"
	dataRemotes.Parent = ReplicatedStorage
end

local function ensure(parent, class, name)
	local ex = parent:FindFirstChild(name)
	if ex then return ex end
	local o = Instance.new(class); o.Name = name; o.Parent = parent
	return o
end

local GiveDamage    = ensure(dataRemotes, "BindableEvent",    "GiveDamage")
local GiveKill      = ensure(dataRemotes, "BindableEvent",    "GiveKill")
local AddKothPoints = ensure(dataRemotes, "BindableFunction", "AddKothPoints")
local ResetAccum    = ensure(dataRemotes, "BindableFunction", "ResetAccum")

local UpdateCoins      = ensure(ReplicatedStorage, "RemoteEvent",    "UpdateCoins")
local UpdatePlayerData = ensure(ReplicatedStorage, "RemoteEvent",    "UpdatePlayerData")
local GetPlayerData    = ensure(ReplicatedStorage, "RemoteFunction", "GetPlayerData")

local WeaponHit   = ensure(ReplicatedStorage, "RemoteEvent", "WeaponHit")
local ApplyEffect = ensure(ReplicatedStorage, "RemoteEvent", "ApplyEffect")
local AbilityUsed = ensure(ReplicatedStorage, "RemoteEvent", "AbilityUsed")
local KillNotify  = ensure(ReplicatedStorage, "RemoteEvent", "KillNotify")

-- === DATA ===
local playerData = {}

-- DataStore (optional). Якщо тестуєш у Studio без API access — буде fallback без збереження.
local STORE = DataStoreService:GetDataStore("FightingGameData_v1")

local function defaultData()
	local d = {
		Level = 1,
		XP    = 0,
		Coins = 0,
		Kills = 0,

		OwnedWeapons   = { KitchenKnife = true }, -- стартовий
		OwnedAbilities = {},
		EquippedWeapon = "KitchenKnife",
		EquippedAbility = nil,

		KillsPerWeapon = {}, -- [weaponId] = count (для осколків)

		-- ресурси
		RareSoul = 0, EpicSoul = 0, MythicSoul = 0, LegendarySoul = 0,
		LightShard = 0, DarkShard = 0, StealthShard = 0, SpikesShard = 0, ElectroShard = 0,
	}
	return d
end

local function load(player)
	local ok, saved = pcall(function() return STORE:GetAsync("u_" .. player.UserId) end)
	local d = defaultData()
	if ok and type(saved) == "table" then
		for k, v in pairs(saved) do d[k] = v end
	end
	return d
end

local function save(player)
	local data = playerData[player]; if not data then return end
	pcall(function() STORE:SetAsync("u_" .. player.UserId, data) end)
end

local function getData(player) return playerData[player] end

-- === СИНК З КЛІЄНТОМ ===
local function sendUpdate(player)
	local d = getData(player); if not d then return end
	UpdateCoins:FireClient(player, d.Coins)
	UpdatePlayerData:FireClient(player, d)
end

local function addXP(player, amount)
	local d = getData(player); if not d then return end
	d.XP += amount
	while d.XP >= xpForLevel(d.Level) do
		d.XP -= xpForLevel(d.Level)
		d.Level += 1
	end
	-- оновити leaderstats
	player.leaderstats.Level.Value = d.Level
	sendUpdate(player)
end

local function addCoins(player, amount)
	local d = getData(player); if not d then return end
	d.Coins += amount
	player.leaderstats.Coins.Value = d.Coins
	sendUpdate(player)
end

local function addResource(player, key, amount)
	local d = getData(player); if not d then return end
	d[key] = math.max(0, (d[key] or 0) + amount)
	sendUpdate(player)
end

local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"; leaderstats.Parent = player

	local level = Instance.new("IntValue", leaderstats); level.Name = "Level"
	local coins = Instance.new("IntValue", leaderstats); coins.Name = "Coins"
	local kills = Instance.new("IntValue", leaderstats); kills.Name = "Kills"

	local d = load(player)
	level.Value = d.Level
	coins.Value = d.Coins
	kills.Value = d.Kills

	-- Службові аккумулятори (не зберігаються)
	d.damageAccum = 0
	d.kothAccum   = 0
	playerData[player] = d

	task.delay(1, function() sendUpdate(player) end)
end

-- === WEAPON HIT ===
WeaponHit.OnServerEvent:Connect(function(player, targetPlayer)
	-- За фактичний урон тепер відповідає WeaponsManager.
	-- Тут нічого не робимо, крім захисту від старих клієнтів — просто ігноруємо.
end)

-- === ABILITY USED ===
AbilityUsed.OnServerEvent:Connect(function(player, abilityName)
	-- теж обробляється AbilityManager-ом (буде)
end)

-- === KOTH XP ===
AddKothPoints.OnInvoke = function(player, points)
	local d = getData(player); if not d then return end
	d.kothAccum += points
	while d.kothAccum >= 50 do
		d.kothAccum -= 50
		addXP(player, 10)
	end
end

ResetAccum.OnInvoke = function(player)
	local d = getData(player); if not d then return end
	d.damageAccum = 0; d.kothAccum = 0
end

GetPlayerData.OnServerInvoke = function(player)
	return getData(player)
end

-- Урон-трекер (WeaponsManager файрить GiveDamage)
GiveDamage.Event:Connect(function(player, dmg)
	local d = getData(player); if not d then return end
	d.damageAccum += dmg
	while d.damageAccum >= 50 do
		d.damageAccum -= 50
		addXP(player, 10)
		addCoins(player, 10)
	end
	sendUpdate(player)
end)

-- Обробка смерті: XP/монети вбивці + дроп душ + осколки
local function handleDeath(victim, humanoid)
	local creatorTag = humanoid:FindFirstChild("creator")
	if not creatorTag or not creatorTag.Value then return end
	local killer = creatorTag.Value
	if killer == victim then return end

	local killerData = getData(killer); if not killerData then return end

	-- Статистика
	killerData.Kills += 1
	killer.leaderstats.Kills.Value = killerData.Kills

	-- XP + монети
	local xpGain   = ({20, 30, 40, 50})[math.random(1, 4)]
	local coinGain = ({20, 30, 40, 50})[math.random(1, 4)]
	addXP(killer, xpGain)
	addCoins(killer, coinGain)
	KillNotify:FireClient(killer, xpGain, coinGain)

	-- Дроп душі
	local soulId = ResourcesConfig.RollSoul()
	if soulId then addResource(killer, soulId, 1) end

	-- Осколки: рахуємо вбивства з конкретного меча
	local weaponTag = humanoid:FindFirstChild("creatorWeapon")
	local weaponId  = weaponTag and weaponTag.Value
	if weaponId and weaponId ~= "" then
		killerData.KillsPerWeapon[weaponId] = (killerData.KillsPerWeapon[weaponId] or 0) + 1
		local shard = ResourcesConfig.ShardForWeapon(weaponId)
		if shard and killerData.KillsPerWeapon[weaponId] % shard.KillsRequired == 0 then
			addResource(killer, shard.Id, 1)
			KillNotify:FireClient(killer, 0, 0, { ShardEarned = shard.Id })
		end
	end

	sendUpdate(killer)
end

-- === ЦИКЛ ГРАВЦЯ ===
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function() handleDeath(player, hum) end)

		-- Екіпувати вибраний меч на спавні
		local d = getData(player)
		if d then
			local WeaponsManager = require(script.Parent.WeaponsManager)
			WeaponsManager.Equip(player, d.EquippedWeapon or "KitchenKnife")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	save(player)
	playerData[player] = nil
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do save(p) end
end)

-- === PUBLIC API для ShopManager / інших модулів ===
_G.DataAPI = {
	GetSnapshot = function(player)
		local d = getData(player); if not d then return nil end
		-- повертаємо копію щоб не хакали пряме поле
		local copy = {}
		for k, v in pairs(d) do
			if type(v) == "table" then
				local t = {}; for k2, v2 in pairs(v) do t[k2] = v2 end; copy[k] = t
			else
				copy[k] = v
			end
		end
		return copy
	end,
	AddResource = function(player, key, amount) addResource(player, key, amount) end,
	AddCoins    = function(player, amount) addCoins(player, amount) end,
	AddXP       = function(player, amount) addXP(player, amount) end,
	AddWeapon   = function(player, id)
		local d = getData(player); if not d then return end
		d.OwnedWeapons[id] = true; sendUpdate(player)
	end,
	AddAbility  = function(player, id)
		local d = getData(player); if not d then return end
		d.OwnedAbilities[id] = true; sendUpdate(player)
	end,
	SetEquippedWeapon = function(player, id)
		local d = getData(player); if not d then return end
		d.EquippedWeapon = id; sendUpdate(player)
	end,
	SetEquippedAbility = function(player, id)
		local d = getData(player); if not d then return end
		d.EquippedAbility = id; sendUpdate(player)
	end,
}

print("[DataManager] ready")
