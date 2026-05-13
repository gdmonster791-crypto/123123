-- ReplicatedStorage > Modules > EffectsConfig (ModuleScript)
-- Статус-ефекти. Мінімальний набір для релізу.

local EffectsConfig = {}

EffectsConfig.Haste = {
	Id = "Haste", DisplayName = "Спешка", Type = "Buff",
	SpeedMult = 1.10,
	Color = Color3.fromRGB(100, 255, 255),
}

EffectsConfig.Vulnerability = {
	Id = "Vulnerability", DisplayName = "Уязвимість", Type = "Debuff",
	DamageInMult = 1.3,
	Color = Color3.fromRGB(255, 120, 0),
}

EffectsConfig.TearWound = {
	Id = "TearWound", DisplayName = "Рвана рана", Type = "Debuff",
	BlockHeal = true,
	Color = Color3.fromRGB(160, 0, 0),
}

EffectsConfig.Shield = {
	Id = "Shield", DisplayName = "Щит", Type = "Buff",
	DamageInMult = 0,
	Color = Color3.fromRGB(100, 200, 255),
}

function EffectsConfig.Get(id)
	return EffectsConfig[id]
end

return EffectsConfig
