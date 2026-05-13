# Fighting Game — Roadmap

## Куди кидати файли в Roblox Studio

```
ReplicatedStorage/
  Modules/                (Folder)
    WeaponsConfig          (ModuleScript)
    EffectsConfig          (ModuleScript)
    AbilitiesConfig        (ModuleScript)
    PerksConfig            (ModuleScript)
    ResourcesConfig        (ModuleScript)

ServerScriptService/
  DataManager              (Script)      — оновлений
  GameManager              (Script)      — оновлений (виправлено дубль kothSharedPoints)
  WeaponsManager           (ModuleScript)
  EffectsManager           (ModuleScript)
  AbilityManager           (Script)
  ShopManager              (Script)

StarterPlayer/StarterPlayerScripts/
  WeaponClient             (LocalScript) — mouse1 = удар, E = способка
  AbilityClient            (LocalScript) — Q = основна способність гравця
  ChargesClient            (LocalScript) — апдейт ChargesGui
  EffectsClient            (LocalScript) — іконки ефектів, сліпота
```

## Що працює зараз (перший релізабельний зріз)

- 6 мечів у конфігу (уроне, заряди, кд).
- Сервер-авторитетні удари з перевіркою відстані та зарядів.
- Ефекти: Haste, Weakness, Vulnerability, Blindness, Stun, Regeneration, Spikes,
  TearWound, ElectroMark, Shield, Rage.
- Базовий шоп (BuyWeapon / EquipWeapon + BuyAbility / EquipAbility).
- Дроп душ з шансами + автоматичні осколки кожні 10 вбивств відповідним мечем.
- DataStore для збереження.
- Абілки гравця: Shield, Rage, Runner (частково — дивись TODO).

## Що зроблено частково / як каркас

- **CloneSword.Clone** — треба окремий модуль з логікою розстановки/телепортів.
- **Backstab** — підсвітка противників на карті (клієнт ще не малює).
- **SilentHunter, LastMoment, BadFeeling** — конфіг є, менеджера перків ще нема.
- **Throw** — працює простим raycast-ом; нема візуалу меча, що летить.
- **Stealth** — міняє Transparency серверно, але треба ще LocalTransparencyModifier
  на клієнті чужим гравцям щоб вони бачили напівпрозорого.

## Наступні кроки (рекомендований порядок)

1. Створити Tool-моделі мечів у `ServerStorage/Weapons/<Id>` (назва Tool = ID з конфігу).
2. Перевірити що `WeaponsManager.Equip` видає Tool у `Backpack` (зараз він лише оновлює state; видачу Tool-а я поки не зробив — хочеш, додам).
3. Зробити PerksManager (коли будуть моделі і UI).
4. Доробити CloneSword (окремий модуль `CloneAbility`).
5. Реалізувати візуал Backstab (highlight усіх противників на клієнті).

## Важливі інваріанти

- **Авторитет на сервері.** Клієнт шле лише тригер (WeaponHit/SpecialUsed). Сервер перевіряє заряди, кулдаун, відстань.
- **Ефекти читаються централізовано.** Будь-який модуль, який хоче модифікатор, бере з `player:GetAttribute("DamageOutMult")` або `EffectsManager.GetDamageOutMult(player)`.
- **Шоп бере ціну з конфігу.** Не дублюй ціни в UI — читай з `WeaponsConfig.Get(id).Cost`.
```
