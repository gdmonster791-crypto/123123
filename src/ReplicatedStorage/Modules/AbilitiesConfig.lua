-- ReplicatedStorage > Modules > AbilitiesConfig (ModuleScript)
-- Основні способності гравця (купуються в магазині, не залежать від меча).

local AbilitiesConfig = {}

AbilitiesConfig.Order = { "Shield", "Rage", "Runner" }

AbilitiesConfig.Shield = {
	Id          = "Shield",
	DisplayName = "Щит",
	Cooldown    = 20,
	Duration    = 5,
	-- На час дії гравець не получає урон. Реалізується через ефект DamageInMult=0
	-- або просто флажок у EffectsManager.
	Description = "Імунітет до урона на 5 секунд.",
	Cost = { Coins = 500, RareSoul = 1 },
}

AbilitiesConfig.Rage = {
	Id          = "Rage",
	DisplayName = "Злість",
	Cooldown    = 25,
	Duration    = 5,
	DamageOutMult = 1.2,
	Description = "Наносиш x1.2 урона 5 секунд.",
	Cost = { Coins = 1500, RareSoul = 3, LightShard = 1 },
}

AbilitiesConfig.Runner = {
	Id          = "Runner",
	DisplayName = "Бігун",
	Cooldown    = 15,
	Duration    = 3,           -- тривалість спешки після ривка
	DashDistance = 28,          -- studs
	SpeedMult   = 1.2,          -- +20% після ривка
	Description = "Бистрий ривок вперед + 20% спешки на 3 секунди.",
	Cost = { Coins = 2750, RareSoul = 5, EpicSoul = 1, LightShard = 1, DarkShard = 1 },
}

function AbilitiesConfig.Get(id)
	return AbilitiesConfig[id]
end

return AbilitiesConfig
