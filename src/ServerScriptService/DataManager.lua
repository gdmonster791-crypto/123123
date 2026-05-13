-- ServerScriptService > DataManager (Script)
-- Дані гравця: leaderstats, XP/рівень, монети, вбивства.
-- Інтегрується з WeaponsManager через GiveDamage BindableEvent.
-- DataStore для збереження між сесіями.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- === XP ФОРМУЛА ===
local function xpForLevel(level) return 100 + (level - 1) * 50 end

-- === REMOTES ===
local function ensure(parent, class, name)
	local ex = parent:FindFirstChild(name)
	if ex then return ex end
	local o = Instance.new(class); o.Name = name; o.Parent = parent
	return o
end

local dataRemotes = ensure(ReplicatedStorage, "Folder", "DataRemotes")
local GiveDamage    = ensure(dataRemotes, "BindableEvent",    "GiveDamage")
local GiveKill      = ensure(dataRemotes, "BindableEvent",    "GiveKill")
local AddKothPoints = ensure(dataRemotes, "BindableFunction", "AddKothPoints")
local ResetAccum    = ensure(dataRemotes, "BindableFunction", "ResetAccum")

local UpdateCoins      = ensure(ReplicatedStorage, "RemoteEvent",    "UpdateCoins")
local UpdatePlayerData = ensure(ReplicatedStorage, "RemoteEvent",    "UpdatePlayerData")
local GetPlayerData    = ensure(ReplicatedStorage, "RemoteFunction", "GetPlayerData")
local KillNotify       = ensure(ReplicatedStorage, "RemoteEvent",    "KillNotify")

-- === DATASTORE ===
local STORE_OK, STORE = pcall(function()
	return DataStoreService:GetDataStore("FightingGame_v2")
end)
if not STORE_OK then STORE = nil end

-- === DATA ===
local playerData = {}

local function defaultData()
	return {
		Level = 1,
		XP    = 0,
		Coins = 0,
		Kills = 0,
		OwnedWeapons    = { KitchenKnife = true },
		OwnedAbilities  = {},
		EquippedWeapon  = "KitchenKnife",
		EquippedAbility = nil,
	}
end

local function load(player)
	local d = defaultData()
	if STORE then
		local ok, saved = pcall(function() return STORE:GetAsync("u_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do d[k] = v end
		end
	end
	return d
end

local function save(player)
	local d = playerData[player]; if not d or not STORE then return end
	-- Не зберігаємо рантайм-поля
	local toSave = {}
	for k, v in pairs(d) do
		if k ~= "damageAccum" and k ~= "kothAccum" then
			toSave[k] = v
		end
	end
	pcall(function() STORE:SetAsync("u_" .. player.UserId, toSave) end)
end

local function getData(player) return playerData[player] end

-- === СИНК ===
local function sendUpdate(player)
	local d = getData(player); if not d then return end
	UpdateCoins:FireClient(player, d.Coins)
	UpdatePlayerData:FireClient(player, {
		Level = d.Level,
		XP    = d.XP,
		Coins = d.Coins,
		Kills = d.Kills,
	})
end

local function addXP(player, amount)
	local d = getData(player); if not d then return end
	d.XP += amount
	while d.XP >= xpForLevel(d.Level) do
		d.XP -= xpForLevel(d.Level)
		d.Level += 1
	end
	player.leaderstats.Level.Value = d.Level
	sendUpdate(player)
end

local function addCoins(player, amount)
	local d = getData(player); if not d then return end
	d.Coins += amount
	player.leaderstats.Coins.Value = d.Coins
	sendUpdate(player)
end

-- === LEADERSTATS ===
local function setupLeaderstats(player)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	local level = Instance.new("IntValue", ls); level.Name = "Level"
	local coins = Instance.new("IntValue", ls); coins.Name = "Coins"
	local kills = Instance.new("IntValue", ls); kills.Name = "Kills"

	local d = load(player)
	level.Value = d.Level
	coins.Value = d.Coins
	kills.Value = d.Kills
	d.damageAccum = 0
	d.kothAccum   = 0
	playerData[player] = d

	task.delay(1, function() sendUpdate(player) end)
end

-- === KOTH ===
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

-- === GET DATA (клієнт) ===
GetPlayerData.OnServerInvoke = function(player)
	local d = getData(player); if not d then return nil end
	return {
		Level          = d.Level,
		XP             = d.XP,
		Coins          = d.Coins,
		Kills          = d.Kills,
		OwnedWeapons   = d.OwnedWeapons,
		OwnedAbilities = d.OwnedAbilities,
		EquippedWeapon = d.EquippedWeapon,
		EquippedAbility= d.EquippedAbility,
	}
end

-- === УРОН-ТРЕКЕР (з WeaponsManager) ===
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

-- === KILL (з серверу) ===
GiveKill.Event:Connect(function(player)
	local d = getData(player); if not d then return end
	d.Kills += 1
	player.leaderstats.Kills.Value = d.Kills
	local xpGain   = ({20, 30, 40, 50})[math.random(1, 4)]
	local coinGain = ({20, 30, 40, 50})[math.random(1, 4)]
	addXP(player, xpGain)
	addCoins(player, coinGain)
	KillNotify:FireClient(player, xpGain, coinGain)
	sendUpdate(player)
end)

-- === СМЕРТЬ ===
local function handleDeath(victim, humanoid)
	local tag = humanoid:FindFirstChild("creator")
	if not tag or not tag.Value then return end
	local killer = tag.Value
	if killer == victim then return end
	if not killer.Parent then return end -- вийшов з гри

	local dataRemotesFolder = ReplicatedStorage:FindFirstChild("DataRemotes")
	local giveKill = dataRemotesFolder and dataRemotesFolder:FindFirstChild("GiveKill")
	if giveKill then giveKill:Fire(killer) end
end

-- === ЦИКЛ ГРАВЦЯ ===
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function() handleDeath(player, hum) end)

		-- Екіпуємо меч на спавні
		task.wait(0.2)
		local d = getData(player)
		if d then
			local WeaponsManager = require(script.Parent:WaitForChild("WeaponsManager"))
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

-- === PUBLIC API (для ShopManager) ===
_G.DataAPI = {
	GetSnapshot = function(player)
		local d = getData(player); if not d then return nil end
		return {
			Level          = d.Level,
			XP             = d.XP,
			Coins          = d.Coins,
			Kills          = d.Kills,
			OwnedWeapons   = d.OwnedWeapons,
			OwnedAbilities = d.OwnedAbilities,
			EquippedWeapon = d.EquippedWeapon,
			EquippedAbility= d.EquippedAbility,
		}
	end,
	AddCoins = function(player, amount) addCoins(player, amount) end,
	AddXP    = function(player, amount) addXP(player, amount) end,
	AddWeapon = function(player, id)
		local d = getData(player); if not d then return end
		d.OwnedWeapons[id] = true; sendUpdate(player)
	end,
	AddAbility = function(player, id)
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
	SpendCoins = function(player, amount)
		local d = getData(player); if not d then return false end
		if d.Coins < amount then return false end
		d.Coins -= amount
		player.leaderstats.Coins.Value = d.Coins
		sendUpdate(player)
		return true
	end,
}

print("[DataManager] ready")
