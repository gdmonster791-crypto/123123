-- ServerScriptService > ShopManager (Script)
-- Обробляє покупку мечів і абілок. Ціна описана у WeaponsConfig / AbilitiesConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsConfig   = require(ReplicatedStorage.Modules.WeaponsConfig)
local AbilitiesConfig = require(ReplicatedStorage.Modules.AbilitiesConfig)

-- Lazy-load DataManager API (він кладе себе в _G при старті)
local function waitForDataAPI()
	local t = 0
	while not _G.DataAPI and t < 10 do
		task.wait(0.1); t += 0.1
	end
	return _G.DataAPI
end

local function ensureRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local BuyWeapon   = ensureRemote("BuyWeapon",   "RemoteFunction")
local BuyAbility  = ensureRemote("BuyAbility",  "RemoteFunction")
local EquipWeapon = ensureRemote("EquipWeapon", "RemoteFunction")
local EquipAbility= ensureRemote("EquipAbility","RemoteFunction")

local function canAfford(data, cost)
	if not cost then return true end
	for key, amount in pairs(cost) do
		if (data[key] or 0) < amount then
			return false, "Не вистачає: " .. key
		end
	end
	return true
end

local function chargeCost(api, player, cost)
	if not cost then return end
	for key, amount in pairs(cost) do
		api.AddResource(player, key, -amount)
	end
end

BuyWeapon.OnServerInvoke = function(player, weaponId)
	local cfg = WeaponsConfig.Get(weaponId)
	if not cfg then return false, "Немає такого меча" end
	local api = waitForDataAPI(); if not api then return false, "Data not ready" end
	local data = api.GetSnapshot(player)
	if data.OwnedWeapons[weaponId] then return false, "Вже куплено" end

	local ok, err = canAfford(data, cfg.Cost)
	if not ok then return false, err end

	chargeCost(api, player, cfg.Cost)
	api.AddWeapon(player, weaponId)
	return true
end

BuyAbility.OnServerInvoke = function(player, abilityId)
	local cfg = AbilitiesConfig.Get(abilityId)
	if not cfg then return false, "Немає такої абілки" end
	local api = waitForDataAPI(); if not api then return false, "Data not ready" end
	local data = api.GetSnapshot(player)
	if data.OwnedAbilities[abilityId] then return false, "Вже куплено" end

	local ok, err = canAfford(data, cfg.Cost)
	if not ok then return false, err end

	chargeCost(api, player, cfg.Cost)
	api.AddAbility(player, abilityId)
	return true
end

EquipWeapon.OnServerInvoke = function(player, weaponId)
	local api = waitForDataAPI(); if not api then return false end
	local data = api.GetSnapshot(player)
	if not data.OwnedWeapons[weaponId] then return false, "Не куплено" end
	api.SetEquippedWeapon(player, weaponId)
	-- Сповіщаємо WeaponsManager
	local WeaponsManager = require(script.Parent.WeaponsManager)
	WeaponsManager.Equip(player, weaponId)
	return true
end

EquipAbility.OnServerInvoke = function(player, abilityId)
	local api = waitForDataAPI(); if not api then return false end
	local data = api.GetSnapshot(player)
	if abilityId ~= nil and not data.OwnedAbilities[abilityId] then
		return false, "Не куплено"
	end
	api.SetEquippedAbility(player, abilityId)
	return true
end
