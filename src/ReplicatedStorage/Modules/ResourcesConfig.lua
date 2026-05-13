-- ReplicatedStorage > Modules > ResourcesConfig (ModuleScript)
-- Душі, осколки, шанси дропу.

local ResourcesConfig = {}

-- Душі падають при вбивстві (перевіряти по порядку, бере перше що випаде — щоб хоча б щось).
-- Якщо треба «максимум 1 душа на вбивство» — порядок важить.
ResourcesConfig.Souls = {
	{ Id = "LegendarySoul", DisplayName = "Легендарна душа", DropChance = 0.05 },
	{ Id = "MythicSoul",    DisplayName = "Міфічна душа",    DropChance = 0.15 },
	{ Id = "EpicSoul",      DisplayName = "Епічна душа",     DropChance = 0.30 },
	{ Id = "RareSoul",      DisplayName = "Рідка душа",      DropChance = 0.50 },
}

-- Осколки: 10 вбивств з конкретного меча → 1 осколок (накопичувач KillsPerWeapon в DataManager)
ResourcesConfig.Shards = {
	LightShard     = { Id = "LightShard",     DisplayName = "Осколок світла",      KillsRequired = 10, WeaponId = "KitchenKnife" },
	DarkShard      = { Id = "DarkShard",      DisplayName = "Осколок тьми",        KillsRequired = 10, WeaponId = "Cleaver" },
	StealthShard   = { Id = "StealthShard",   DisplayName = "Осколок незамітності", KillsRequired = 10, WeaponId = "SamuraiKatana" },
	SpikesShard    = { Id = "SpikesShard",    DisplayName = "Осколок шипів",       KillsRequired = 10, WeaponId = "SpikedBlade" },
	ElectroShard   = { Id = "ElectroShard",   DisplayName = "Електро-осколок",     KillsRequired = 10, WeaponId = "ElectroHammer" },
}

-- Усі ресурсні поля, які треба ініціалізувати в даних гравця
ResourcesConfig.AllResourceKeys = {
	"RareSoul", "EpicSoul", "MythicSoul", "LegendarySoul",
	"LightShard", "DarkShard", "StealthShard", "SpikesShard", "ElectroShard",
}

-- Визначає яка душа випала при вбивстві (або nil)
function ResourcesConfig.RollSoul()
	for _, soul in ipairs(ResourcesConfig.Souls) do
		if math.random() < soul.DropChance then
			return soul.Id
		end
	end
	return nil
end

-- Повертає осколок, який треба нагородити, коли KillsPerWeapon досягло 10
-- Викликається з DataManager після інкременту лічильника
function ResourcesConfig.ShardForWeapon(weaponId)
	for _, shard in pairs(ResourcesConfig.Shards) do
		if shard.WeaponId == weaponId then
			return shard
		end
	end
	return nil
end

return ResourcesConfig
