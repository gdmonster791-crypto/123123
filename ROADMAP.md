# Fighting Game — Мінімальний реліз

## Що готове в коді

- [x] Kitchen Knife: 8 урон, 5 зарядів, 0.8с між ударами, 2с відновлення заряду
- [x] Backstab (E): підсвітка ворогів, +10% швидкості, 2 удари на ціль, Vulnerability + TearWound
- [x] Shield (Q): 5с імунітет, кд 20с, ціна 500 монет
- [x] Магазин — покупка Shield через `BuyAbility:InvokeServer("Shield")`
- [x] XP/рівні/монети/leaderstats
- [x] Інтеграція з існуючими remote events (BackstabEvent, UpdateCooldownEvent)
- [x] EffectsManager не конфліктує з MovementController

## Куди кидати файли в Roblox Studio

### ReplicatedStorage → створи Folder "Modules"
| Файл | Тип | Куди |
|------|-----|------|
| `WeaponsConfig.lua` | ModuleScript | ReplicatedStorage/Modules |
| `EffectsConfig.lua` | ModuleScript | ReplicatedStorage/Modules |

### ServerScriptService
| Файл | Тип |
|------|-----|
| `DataManager.lua` | Script |
| `GameManager.lua` | Script |
| `AbilityManager.lua` | Script |
| `ShopManager.lua` | Script |
| `WeaponsManager.lua` | **ModuleScript** |
| `EffectsManager.lua` | **ModuleScript** |

### StarterPlayer/StarterPlayerScripts (LocalScript-и)
- `WeaponClient.client.lua` — ЛКМ удар, E способка
- `AbilityClient.client.lua` — Q абілка + кулдаун GUI
- `ChargesClient.client.lua` — заряди в GUI
- `BackstabClient.client.lua` — підсвітка ворогів при Backstab

### StarterPlayer/StarterCharacterScripts
- `MovementController.client.lua` — твій рух, оновлений щоб читати ефекти

## Контроли в грі

| Клавіша | Дія |
|--------|-----|
| ЛКМ    | Удар мечем |
| E      | Backstab (спец-абілка меча) |
| Q      | Shield (абілка гравця) |
| V      | Toggle курсор (з твого camera скрипта) |
| LCtrl  | Chill mode (з твого camera скрипта) |
| LShift | Біг |

## Що потрібно зробити в Studio (вручну)

1. **Kitchen Knife Tool** — назви його `KitchenKnife` (саме так, без пробілу). У тебе він у StarterPack → `Kitchen Knife` — переіменуй.
2. **ShopGui.KitchenKnifeFolder.KitchenKnife.BuyButton** — прив'яжи до:
   ```lua
   local BuyAbility = game.ReplicatedStorage:WaitForChild("BuyAbility")
   script.Parent.MouseButton1Click:Connect(function()
       local ok, err = BuyAbility:InvokeServer("Shield")
       if not ok then warn("Не куплено:", err) end
   end)
   ```
   (Якщо кнопка для покупки Shield — не KitchenKnife, бо KitchenKnife безкоштовний.)
3. **Енабл API access** у Game Settings → Security → Enable Studio Access to API Services (для DataStore).

## Як працює все разом

```
Гравець натискає ЛКМ
  ↓
WeaponClient raycast з центра екрана → знаходить ціль
  ↓
WeaponHit:FireServer(target)
  ↓
WeaponsManager перевіряє: заряди, кд, відстань, стан Stun
  ↓
EffectsManager.GetDamageOutMult/DamageInMult → множники
  ↓
Tool:SetAttribute("CurrentAmmo", new) → ChargesClient бачить зміну
  ↓
hum:TakeDamage → якщо 0хп → DataManager.handleDeath → XP + монети
```

## Що далі (після релізу)

- [ ] Додати Cleaver (тесак) — для першої "обнови"
- [ ] Додати Rage/Runner абілки
- [ ] Додати дроп душ / осколки
- [ ] Додати перки
- [ ] Додати анімацію удару для Tool
