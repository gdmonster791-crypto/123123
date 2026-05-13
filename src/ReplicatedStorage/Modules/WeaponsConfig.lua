-- ReplicatedStorage > Modules > WeaponsConfig (ModuleScript)
-- Конфіг усіх мечів: стати, заряди, спец-абілки, ціна.
-- Сюди додавай нові мечі в одному місці.

local WeaponsConfig = {}

-- Порядок у магазині
WeaponsConfig.Order = {
	"KitchenKnife", "Cleaver", "SamuraiKatana",
	"SpikedBlade", "ElectroHammer", "CloneSword",
}

WeaponsConfig.KitchenKnife = {
	Id            = "KitchenKnife",
	DisplayName   = "Кухонний ніж",
	Rarity        = "Common",
	Damage        = 8,
	AttackSpeed   = 0.8,
	MaxCharges    = 5,
	ChargeCooldown = 2,
	Ability = {
		Id          = "Backstab",
		DisplayName = "Бешенство",
		Cooldown    = 15,
		Duration    = 10,
		HitDamage   = 8,          -- урон за 1 удар під час способки
		MaxHitsPerTarget = 2,      -- макс. скільки разів можна бити 1 ціль
		SpeedMultiplier  = 1.1,
		AppliesEffects   = { "Vulnerability", "TearWound" },
		Description = "Всі підсвічені. Ти бистріший на 10%%. 2 удари на ціль, накладає Уязвимість і Рвану рану.",
	},
	Cost = nil, -- стартовий меч
}

WeaponsConfig.Cleaver = {
	Id            = "Cleaver",
	DisplayName   = "Тесак",
	Rarity        = "Rare",
	Damage        = 12,
	AttackSpeed   = 1.0,
	MaxCharges    = 5,
	ChargeCooldown = 1.5,
	Ability = {
		Id          = "Throw",
		DisplayName = "Кидання",
		Cooldown    = 10,
		Damage      = 40,
		AppliesEffects  = { "Weakness" },
		EffectDuration  = 7,
		Description = "Кидаєш меч у напрямку погляду. Попадання: 40 урона + Слабкість на 7с.",
	},
	Cost = {
		Coins        = 2000,
		RareSoul     = 1,
		EpicSoul     = 1,
		LightShard   = 1,
	},
}

WeaponsConfig.SamuraiKatana = {
	Id            = "SamuraiKatana",
	DisplayName   = "Катана самурая",
	Rarity        = "Epic",
	Damage        = 6,
	AttackSpeed   = 0.4,
	MaxCharges    = 5,
	ChargeCooldown = 1.0,
	Ability = {
		Id          = "Stealth",
		DisplayName = "Стелс",
		Cooldown    = 20,
		Duration    = 10,
		Damage      = 0,
		Transparency = 0.8,
		HitDamageMultiplier = 2,           -- подвійний урон зі стелсу
		OnHitAppliesToSelf = { Effect = "Haste", Duration = 3 },
		Description = "На 10с стаєш на 80% прозорим. Удар зі стелсу = x2 урон, +3с Спешки.",
	},
	Cost = {
		Coins      = 5000,
		RareSoul   = 3,
		EpicSoul   = 3,
		DarkShard  = 1,
	},
}

WeaponsConfig.SpikedBlade = {
	Id            = "SpikedBlade",
	DisplayName   = "Шипований клинок",
	Rarity        = "Epic",
	Damage        = 4,                 -- база
	DamagePerHitStack = 1,              -- +1 за кожен послідовний удар по одній цілі
	AttackSpeed   = 0.5,
	MaxCharges    = 7,
	ChargeCooldown = 1.5,
	AppliesEffects = { "Spikes" },     -- завжди накладає шипи на удар
	Ability = {
		Id          = "Spike",
		DisplayName = "Шип",
		Cooldown    = 20,
		Damage      = 10,
		EffectDuration = 5,
		Description = "Якщо ціль вже має Шипи — знімаєш 10 хп + оновлюєш Шипи на 5с.",
	},
	Cost = {
		Coins         = 7500,
		RareSoul      = 3,
		MythicSoul    = 1,
		StealthShard  = 1,
		DarkShard     = 1,
		LightShard    = 1,
	},
}

WeaponsConfig.ElectroHammer = {
	Id            = "ElectroHammer",
	DisplayName   = "Електричний молот",
	Rarity        = "Legendary",
	Damage        = 10,
	AttackSpeed   = 0.8,
	MaxCharges    = 8,
	ChargeCooldown = 2.0,
	AppliesEffects   = { "ElectroMark" },
	ElectroMark = {
		DamagePerSecond = 1,
		Duration        = 8,
		ChainRadius     = 8,        -- studs
		ChainDamage     = 5,
	},
	Ability = {
		Id          = "ElectroShock",
		DisplayName = "Електричний-Шок",
		Cooldown    = 20,
		Duration    = 3,
		Damage      = 0,
		RequiresMark   = true,
		AppliesEffects = { "Stun", "Blindness" },
		Description = "Станить усіх з ElectroMark + накладає Сліпоту на 3с.",
	},
	Cost = {
		Coins         = 10000,
		SpikesShard   = 1,
		RareSoul      = 5,
		MythicSoul    = 3,
		LegendarySoul = 1,
	},
}

WeaponsConfig.CloneSword = {
	Id            = "CloneSword",
	DisplayName   = "Клоновий меч",
	Rarity        = "Legendary",
	Damage        = 1,
	AttackSpeed   = 0.1,
	MaxCharges    = 1,
	ChargeCooldown = 7,
	Ability = {
		Id          = "Clone",
		DisplayName = "Клон",
		Cooldown    = 25,           -- між телепортами
		MaxClonesActive = 3,
		MaxClonesPerMatch = 6,
		CloneTransparency = 0.5,
		Description = "Ставиш клонів — телепортуєшся між ними. Клон зникає при телепорті.",
	},
	Cost = {
		Coins         = 20000,
		LegendarySoul = 5,
		MythicSoul    = 10,
	},
}

function WeaponsConfig.Get(id)
	return WeaponsConfig[id]
end

return WeaponsConfig
