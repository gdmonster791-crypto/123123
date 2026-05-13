-- ReplicatedStorage > Modules > PerksConfig (ModuleScript)
-- Перки: пасивні постійні, активні — зрабатують за умовою.

local PerksConfig = {}

PerksConfig.Order = { "LastMoment", "SilentHunter", "BadFeeling" }

PerksConfig.LastMoment = {
	Id          = "LastMoment",
	DisplayName = "В останній момент!",
	Type        = "Active",             -- активується автоматично при тригері
	Trigger     = "HealthBelow",
	Threshold   = 0.35,                  -- <35% hp
	Duration    = 5,
	SpeedMult   = 1.10,
	DamageOutMult = 1.2,
	UsesPerRound = 1,
	Description = "При <35% хп: 10% спешки + x1.2 урон на 5с. 1 раз за раунд.",
}

PerksConfig.SilentHunter = {
	Id          = "SilentHunter",
	DisplayName = "Тихий мисливець",
	Type        = "Active",              -- гравець сам активує, коли назбирав жетонів
	StillnessSecondsToStart = 5,          -- почне збирати жетони після 5с без руху
	TokensRequired = 10,                  -- треба 10 жетонів
	Duration    = 5,                      -- скільки триває бафф
	SpeedMult   = 1.10,
	DamageOutMult = 1.2,
	Description = "Стій 5с — починаєш збирати жетони, дивлячись на бійців. На 10 жетонах — x1.2 урон + 10% спешки.",
}

PerksConfig.BadFeeling = {
	Id          = "BadFeeling",
	DisplayName = "Погане предчуствіє",
	Type        = "Active",
	UsesPerMatch = 1,
	ArmTime = 0.5,                        -- вікно, поки перк «зведений»
	RequiredHealthBelow = 0.25,
	SpeedMult   = 1.25,
	HealBoostMult = 1.75,                 -- +75% регени
	Duration    = 10,
	Description = "1 раз за гру. При <25% хп активуй; якщо тебе вдарять у ту ж секунду — 25% спешки + x1.75 регени.",
}

function PerksConfig.Get(id)
	return PerksConfig[id]
end

return PerksConfig
