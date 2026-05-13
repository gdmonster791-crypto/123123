-- ServerScriptService > ShopManager (Script)
-- Мінімальний магазин: покупка абілки Shield.
-- Для релізу KitchenKnife безкоштовний і вже є у всіх.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensure(parent, class, name)
	local ex = parent:FindFirstChild(name)
	if ex then return ex end
	local o = Instance.new(class); o.Name = name; o.Parent = parent
	return o
end

local BuyAbility   = ensure(ReplicatedStorage, "RemoteFunction", "BuyAbility")
local EquipAbility = ensure(ReplicatedStorage, "RemoteFunction", "EquipAbility")

-- Ціни абілок
local ABILITY_PRICES = {
	Shield = 500,
}

local function waitForDataAPI()
	local t = 0
	while not _G.DataAPI and t < 10 do
		task.wait(0.1); t += 0.1
	end
	return _G.DataAPI
end

BuyAbility.OnServerInvoke = function(player, abilityId)
	local price = ABILITY_PRICES[abilityId]
	if not price then return false, "Немає такої абілки" end

	local api = waitForDataAPI()
	if not api then return false, "Data not ready" end

	local data = api.GetSnapshot(player)
	if not data then return false, "No data" end
	if data.OwnedAbilities[abilityId] then return false, "Вже куплено" end

	-- Перевіряємо монети
	if data.Coins < price then return false, "Не вистачає монет" end

	-- Списуємо
	local ok = api.SpendCoins(player, price)
	if not ok then return false, "Не вистачає монет" end

	api.AddAbility(player, abilityId)
	api.SetEquippedAbility(player, abilityId)
	return true
end

EquipAbility.OnServerInvoke = function(player, abilityId)
	local api = waitForDataAPI()
	if not api then return false end
	local data = api.GetSnapshot(player)
	if not data then return false end

	if abilityId ~= nil and not data.OwnedAbilities[abilityId] then
		return false, "Не куплено"
	end

	api.SetEquippedAbility(player, abilityId)
	return true
end
