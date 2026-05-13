---
inclusion: always
---

# Fighting Game — структура проекту

## Мова
- Використовуй українську мову в коментарях і print-логах (як у користувача).

## Архітектура Roblox
- Всі скрипти з `src/ServerScriptService/` → **ServerScriptService** в Studio
- `DataManager`, `GameManager`, `AbilityManager`, `ShopManager` — це **Script** (.Script)
- `WeaponsManager`, `EffectsManager` — це **ModuleScript**
- `src/ReplicatedStorage/Modules/*` → **ReplicatedStorage.Modules** (ModuleScript-и)
- `src/StarterPlayer/StarterPlayerScripts/*` → **StarterPlayer.StarterPlayerScripts** (LocalScript)
- `src/StarterPlayer/StarterCharacterScripts/*` → **StarterPlayer.StarterCharacterScripts** (LocalScript, всередині персонажа)

## Конвенції
- Remote events створюються **автоматично** в ReplicatedStorage через `ensureRemote`. Не створюй їх вручну.
- Авторитет на сервері: клієнт шле тільки тригер, сервер валідує.
- `EffectsManager` керує ефектами через атрибути гравця (`SpeedMult`, `DamageOutMult`, `DamageInMult`, `Stunned`, `BlockHeal`).
- `MovementController` ЧИТАЄ `SpeedMult`/`Stunned` з атрибутів. НЕ пиши WalkSpeed в EffectsManager — буде конфлікт.

## Існуючі Remote Events в ReplicatedStorage (створені користувачем)
- `BackstabEvent` — сервер→клієнт, сповіщає про початок/кінець Backstab
- `FadeEvent`, `FadeScreen` (GameRemotes) — для переходів між лобі/грою
- `UpdateCooldownEvent` — сервер→клієнт, (type, cooldown) де type = "Ability" | "Weapon"
- `WinnerEvent` — оголошення переможця
- `SaveSettingsEvent`, `GravityToggleEvent` — налаштування
- `PlayerAddedTimer` — таймер при під'єднанні

## Remote Events що створює WeaponsManager/AbilityManager/DataManager
- `WeaponHit`, `SpecialUsed` — клієнт→сервер
- `AbilityUsed` — клієнт→сервер
- `ApplyEffect` — сервер→клієнт (візуал ефектів)
- `UpdateCoins`, `UpdatePlayerData`, `KillNotify` — сервер→клієнт
- `GetPlayerData` — RemoteFunction
- `BuyAbility`, `EquipAbility` — RemoteFunction

## GUI (вже існує у користувача)
- `ChargesGui/ChargesTemplate/ChargesText` — показує заряди меча
- `PlayerAbilityGui` з `CooldownText` — кулдаун абілки Q
- `GUI1` з `Text`, `Time` — HUD з режимом і таймером
- `BlackScreen/FadeFrame` — фейд-переходи
- `ValuesGui/CoinsText` — кількість монет
- `ShopGui` — магазин мечів і абілок
- `LevelsGui`, `XPTemplate`, `LevelTemplate` — рівень/XP

## Мінімальний реліз
Для першого релізу — ТІЛЬКИ:
1. Kitchen Knife (8 урон, 5 зарядів по 2с, 0.8 швидкість)
2. Backstab спец-абілка (E) — 10с підсвітка + Haste, 2 удари на ціль, Vulnerability + TearWound
3. Shield абілка гравця (Q) — 5с імунітет, кд 20с, ціна 500 монет
4. 4 карти + лобі (є у користувача)
5. Deathmatch + KOTH (є)
6. Магазин (тільки Shield)

НЕ роби поки: інші мечі, інші абілки, перки, осколки, душі, DataStore-збереження ресурсів.
