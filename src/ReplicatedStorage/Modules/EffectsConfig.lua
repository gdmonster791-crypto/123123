-- ReplicatedStorage > Modules > EffectsConfig (ModuleScript)
-- Всі статус-ефекти гри. Модифікатори читає EffectsManager.

local EffectsConfig = {}

-- type:
--   "Buff"  — позитивний
--   "Debuff" — негативний
-- stack:
--   "Refresh" — при повторному накладанні оновлюється таймер
--   "Stack"   — кілька штук одночасно (сума урона)
-- Modifiers (усі опційні, множники)
--   SpeedMult       — на WalkSpeed
--   DamageOutMult   — наносить
--   DamageInMult    — получає
--   BlockHeal       — не може хілитись
--   Stunned         — ні рух, ні удар, ні абілки
-- Ticks (опційно) — періодичні події:
--   DamagePerSecond — DOT
--   HealPerSecond   — HOT

EffectsConfig.Haste = {
	Id = "Haste", DisplayName = "Спешка", Type = "Buff", Stack = "Refresh",
	SpeedMult = 1.10,
	Color = Color3.fromRGB(100, 255, 255),
}

EffectsConfig.Weakness = {
	Id = "Weakness", DisplayName = "Слабкість", Type = "Debuff", Stack = "Refresh",
	SpeedMult = 0.8, DamageOutMult = 0.8,
	Color = Color3.fromRGB(120, 120, 120),
}

EffectsConfig.Vulnerability = {
	Id = "Vulnerability", DisplayName = "Уязвимість", Type = "Debuff", Stack = "Refresh",
	DamageInMult = 1.3,
	Color = Color3.fromRGB(255, 120, 0),
}

EffectsConfig.Blindness = {
	Id = "Blindness", DisplayName = "Сліпота", Type = "Debuff", Stack = "Refresh",
	Radius = 10, -- клієнт читає цей параметр для затемнення
	Color = Color3.fromRGB(20, 20, 20),
}

EffectsConfig.Stun = {
	Id = "Stun", DisplayName = "Оглушення", Type = "Debuff", Stack = "Refresh",
	Stunned = true, SpeedMult = 0,
	Color = Color3.fromRGB(255, 255, 0),
}

EffectsConfig.Regeneration = {
	Id = "Regeneration", DisplayName = "Регенерація", Type = "Buff", Stack = "Refresh",
	HealPerSecond = 2, -- 1 хп / 0.5с
	Color = Color3.fromRGB(0, 255, 120),
}

EffectsConfig.Spikes = {
	Id = "Spikes", DisplayName = "Шипи", Type = "Debuff", Stack = "Refresh",
	DamagePerSecond = 2,
	Color = Color3.fromRGB(180, 80, 80),
}

EffectsConfig.TearWound = {
	Id = "TearWound", DisplayName = "Рвана рана", Type = "Debuff", Stack = "Refresh",
	BlockHeal = true,
	Color = Color3.fromRGB(160, 0, 0),
}

-- Спец-ефект електромолота (не статус в класичному сенсі — ElectroHammer читає його окремо,
-- але ми все одно тримаємо тут щоб GUI міг відобразити)
EffectsConfig.ElectroMark = {
	Id = "ElectroMark", DisplayName = "Електромітка", Type = "Debuff", Stack = "Refresh",
	DamagePerSecond = 1,
	Color = Color3.fromRGB(120, 200, 255),
}

-- Похідні від абілок гравця
EffectsConfig.Shield = {
	Id = "Shield", DisplayName = "Щит", Type = "Buff", Stack = "Refresh",
	DamageInMult = 0,
	Color = Color3.fromRGB(100, 200, 255),
}

EffectsConfig.Rage = {
	Id = "Rage", DisplayName = "Злість", Type = "Buff", Stack = "Refresh",
	DamageOutMult = 1.2,
	Color = Color3.fromRGB(255, 80, 80),
}

function EffectsConfig.Get(id)
	return EffectsConfig[id]
end

return EffectsConfig
