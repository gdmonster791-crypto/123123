-- ReplicatedStorage > Modules > WeaponsConfig (ModuleScript)
-- Конфіг мечів. Поки що тільки Kitchen Knife для релізу.

local WeaponsConfig = {}

WeaponsConfig.Order = { "KitchenKnife" }

WeaponsConfig.KitchenKnife = {
	Id             = "KitchenKnife",
	DisplayName    = "Кухонний ніж",
	Rarity         = "Common",
	Damage         = 8,
	AttackSpeed    = 0.8,        -- секунд між ударами
	MaxCharges     = 5,
	ChargeCooldown = 2,          -- секунд на відновлення 1 заряду
	Ability = {
		Id               = "Backstab",
		DisplayName      = "Бешенство",
		Cooldown         = 15,
		Duration         = 10,
		HitDamage        = 8,
		MaxHitsPerTarget = 2,
		SpeedMult        = 1.1,     -- +10% швидкості під час способки
		AppliesEffects   = { "Vulnerability", "TearWound" },
		Description      = "Всі підсвічені. +10% швидкості. 2 удари на ціль, накладає Уязвимість і Рвану рану.",
	},
	Cost = nil, -- стартовий меч, безкоштовний
}

function WeaponsConfig.Get(id)
	return WeaponsConfig[id]
end

return WeaponsConfig
