# Промпт-бриф для арта карт (для внешнего AI-инструмента/художника)

Дополняет ARC-091. История стиля: первый вариант был плоский векторный "щит-медальон" — отклонён
("совсем не то"). Второй — расписанный насыщенный 2D-арт в духе Clash Royale/Hearthstone (яркий
cel-shading, отдельная фоновая сцена за персонажем). На карте «Гоблин» этот вариант конфликтовал с
шаблоном карты (§5 — состаренный пергамент/свиток): иллюстрация со своей сюжетной сценой (лес/небо)
всегда читалась как отдельная фотография-вставка поверх пергамента, а не как рисунок на той же
"бумаге", сколько её край ни растушёвывай программно (см. историю правок в git и GitHub Issues,
ARC-091). По итогам прямого сравнения A/Б на реальной текстуре пергамента — **закреплён третий,
текущий вариант**: монохромная сепийная тушь/гравюра, как в старом бестиарии, без отдельной фоновой
сцены — рисунок читается как часть той же страницы, что и рамка карты, а не вставка на неё.

Индикатор редкости и рамку/печать/ленту по-прежнему рисует движок поверх готового арта (§3, §5) —
иллюстрация того же 3:4 портретного формата, что и раньше, меняется только сама техника/палитра.
Генерировать через Midjourney/ChatGPT Images/Leonardo/Stable Diffusion или отдавать художнику как
техзадание — промпт одинаково читается в обоих случаях.

## 1. Мастер-промпт (стиль, общий для всех карт)

Блок стиля не меняется от карты к карте — меняется только "Subject" (§4). Палитра по ресурсу (§2 —
теперь исторический раздел, см. пометку там) на саму иллюстрацию больше не влияет: цветовое
кодирование ресурса целиком на ленте-баннере и восковой печати (ARC-091), иллюстрация сознательно
монохромна.

```
Monochrome sepia ink illustration in the style of an old illuminated manuscript bestiary,
as if painted or engraved directly onto aged parchment paper — NOT a separate picture
pasted on top of the paper, the parchment's own texture and warm tone should show through
the linework and shading. Bold expressive ink linework with soft sepia-brown wash shading
(like diluted ink or watercolor wash, one or two tones), no flat color, no saturated hues.
Single subject, no background scene at all — just the subject alone on the empty parchment,
loosely bordered by faint ink hatching or a few scattered decorative flourishes that trail
off into nothing (not a hard outline, not a frame). Bold, clean, readable silhouette even
at small thumbnail size. Vertical 3:4 portrait orientation. No text, no card frame, no
watermark, no color, no gore, family-friendly tone.
```

**Негативный промпт** (Stable Diffusion/Leonardo; для Midjourney — через `--no`):
```
text, watermark, signature, logo, card frame, border, UI elements, color, saturated color,
blood, gore, photorealistic, 3d render, low quality, blurry subject, extra limbs, deformed hands,
background scene, environment
```

## 2. Палитра по типу ресурса (историческая — на иллюстрацию больше не влияет)

Эта таблица относилась к прежнему насыщенно-цветному варианту стиля (сцена/фон за персонажем красились
по типу ресурса). После перехода на монохромную сепию (§1) иллюстрация ресурс больше не кодирует —
только лента-баннер и восковая печать (`card.gd::update_ui()`, `resource_tint`). Таблица оставлена как
референс для этих двух узлов, не для Subject-промптов §4:

| Тип | Акцентный цвет (лента + печать, не иллюстрация) |
| :--- | :--- |
| Кирпичи (красный) | `Color(1.0, 0.35, 0.3)` — терракота/кирпич. |
| Гемы (синий) | `Color(0.35, 0.5, 1.0)` — сапфир/электрик-синий. |
| Звери (зелёный) | `Color(0.35, 1.0, 0.35)` — мшисто-зелёный. |

## 3. Модификатор редкости (влияет на позу/детализацию, не на цвет рамки — рамку рисует движок)

| Редкость | Модификатор |
| :--- | :--- |
| Common | Скромный, приземлённый дизайн — без свечения/магических эффектов, простое снаряжение, слабый/небольшой на вид персонаж. |
| Uncommon | Чуть больше детализации в снаряжении/позе, лёгкий акцент освещения, ощущение "уже не самый слабый". |
| Rare | Драматичная поза, элемент магии/свечения по сюжету карты, что-то одно запоминающееся (шрам, уникальное оружие, огромный размер). |

## 4. Карты — Subject-промпты

### Гоблин (`beast_3.tres`, Звери, Common, cost 1, «Наносит 2 урона врагу»)

Small, scrawny common-tier goblin minion — cheap, weak attacker, so the pose reads as quick and
sneaky rather than powerful.

**Subject:**
```
A small, scrawny goblin, mottled sickly-green skin, oversized pointed ears, bared crooked
teeth in a mischievous grin, one eye squinted. Crouched mid-lunge pose, gripping a small
rusty jagged dagger in one clawed hand, wearing ragged leather scraps and a burlap
loincloth, no armor. Body language reads as darting and opportunistic, not heroic or
powerful — a low-tier minion, not a boss.
```

**Готовый промпт для Midjourney (пример):**
```
Monochrome sepia ink illustration in the style of an old illuminated manuscript bestiary,
painted or engraved directly onto aged parchment paper, bold expressive ink linework, soft
sepia-brown wash shading, no flat color, no saturated hues, no background scene, subject
alone on empty parchment with faint ink flourishes trailing off, bold clean readable
silhouette, vertical portrait orientation, no text, no frame, no gore, family-friendly ::
a small scrawny goblin, oversized pointed ears, mischievous crooked grin, one eye squinted,
crouched mid-lunge gripping a small jagged dagger, ragged leather scraps and burlap
loincloth, no armor, quick and sneaky body language, not heroic or powerful
--ar 3:4 --style raw --no text, watermark, frame, color, blood, extra limbs
```

**Тот же промпт для DALL-E/ChatGPT Images/Firefly (обычным текстом, без `--` параметров):**
```
Create a monochrome sepia ink illustration in the style of an old illuminated manuscript
bestiary, as if painted or engraved directly onto aged parchment paper — not a separate
picture pasted on top of the paper. Bold expressive ink linework with soft sepia-brown wash
shading, no flat color, no saturated hues. No background scene at all — just the subject
alone on the empty parchment, loosely bordered by faint ink hatching or decorative
flourishes trailing off into nothing. Bold, clean, readable silhouette. Vertical 3:4
portrait orientation. No text, no card frame, no watermark, no gore, family-friendly tone.

Subject: a small, scrawny goblin with oversized pointed ears, a mischievous crooked grin
with one eye squinted. It's crouched in a mid-lunge pose, gripping a small jagged dagger,
wearing only ragged leather scraps and a burlap loincloth, no armor. Its body language
should read as quick and sneaky, not powerful or heroic — a cheap, low-tier minion.
```

**Решение по стилю (закрыто).** Прогнали через генератор оба кандидата на "убрать фон и лучше
вписать в пергамент" — вариант A (монохром/сепия, гравюра на пергаменте, промпт выше) и вариант B
(цветной, без фона, живописный "истекающий" край). Сравнили визуально прямо на реальной текстуре
`art/card_frame/parchment_bg.png` (не на абстрактном фоне): у A край практически не читается — тон
сепии настолько близок к пергаменту, что даже простая программная растушёвка даёт бесшовный результат.
У B генератор дал не чистый белый, а кремовый фон с цветными разводами по краю, и вырезание по порогу
яркости оставляло заметный светлый ореол вокруг персонажа, спорящий с более тёмным пергаментом —
решаемо, но требует куда больше возни и даёт менее гарантированный результат. **Выбран вариант A** —
им теперь и является мастер-промпт §1, старый насыщенно-цветной Clash Royale/Hearthstone стиль (§2
исторический) для иллюстраций больше не используется. Отдельно пробовали цветной арт прямо на текстуре
пергамента (без белого фона у генерации) как ещё одну альтернативу для самого Гоблина — тоже неплохо
блендился, но автор тикета решил стиль не менять, сепия остаётся канонической (см.
GitHub Issue ARC-091).

---

### Зверолов (`beast_1.tres`, Звери, Common, cost 1, «Увеличивает добычу зверей на 1»)

Не боец — вспомогательная карта (эффект `mod_dungeon +1`, свой территория/добыча, а не атака). Common,
дешёвая (cost 1), поэтому персонаж должен читаться как обычный практичный следопыт, а не как герой:
никакой магии/свечения, простое снаряжение (§3 — модификатор редкости Common).

**Subject:**
```
A rugged, weathered beast hunter and trapper, plain human, practical worn leather and fur
clothing, a simple fur-trimmed hood or cap. Carries humble trapping gear — a coil of rope
or snare wire slung over one shoulder, a small skinning knife at the belt, a couple of
animal pelts draped across the other shoulder. Crouched low as if reading tracks on the
ground, alert and watchful posture, weathered face with rough stubble. No magic, no glow,
no fine armor or ornate weapons — a common, humble tracker going about his trade, not a
heroic warrior.
```

**Готовый промпт для Midjourney (пример):**
```
Monochrome sepia ink illustration in the style of an old illuminated manuscript bestiary,
painted or engraved directly onto aged parchment paper, bold expressive ink linework, soft
sepia-brown wash shading, no flat color, no saturated hues, no background scene, subject
alone on empty parchment with faint ink flourishes trailing off, bold clean readable
silhouette, vertical portrait orientation, no text, no frame, no gore, family-friendly ::
a rugged weathered beast hunter and trapper, practical worn leather and fur clothing,
fur-trimmed hood, coil of snare rope over one shoulder, small skinning knife at the belt,
animal pelts draped over the other shoulder, crouched low reading tracks on the ground,
alert watchful posture, weathered stubbled face, no magic, no glow, no fine armor, humble
tracker not a heroic warrior
--ar 3:4 --style raw --no text, watermark, frame, color, blood, extra limbs
```

**Тот же промпт для DALL-E/ChatGPT Images/Firefly (обычным текстом, без `--` параметров):**
```
Create a monochrome sepia ink illustration in the style of an old illuminated manuscript
bestiary, as if painted or engraved directly onto aged parchment paper — not a separate
picture pasted on top of the paper. Bold expressive ink linework with soft sepia-brown wash
shading, no flat color, no saturated hues. No background scene at all — just the subject
alone on the empty parchment, loosely bordered by faint ink hatching or decorative
flourishes trailing off into nothing. Bold, clean, readable silhouette. Vertical 3:4
portrait orientation. No text, no card frame, no watermark, no gore, family-friendly tone.

Subject: a rugged, weathered beast hunter and trapper, plain human, practical worn leather
and fur clothing, a simple fur-trimmed hood or cap. He carries humble trapping gear — a
coil of rope or snare wire slung over one shoulder, a small skinning knife at the belt, a
couple of animal pelts draped across the other shoulder. He's crouched low as if reading
tracks on the ground, alert and watchful posture, weathered face with rough stubble. No
magic, no glow, no fine armor or ornate weapons — a common, humble tracker going about his
trade, not a heroic warrior.
```

---

*(Дальше в этот файл добавляются Subject-промпты для остальных 65 карт по мере генерации —
формат один в один как у «Гоблина» выше: цитата из `.tres` для контекста, Subject-блок, готовый
промпт под Midjourney и под текстовые генераторы.)*

---

## 5. Шаблон карты (рамка) — зафиксированное решение

Обсуждено и зафиксировано (не реализовано в коде — это план на будущий тикет, отдельный от
иллюстраций §1-4 выше). Карта — не иллюстрация сама по себе, а разыгрываемое магическое приказание
(вписывается в тон GDD «маги-подмастерья»: даже «Каменоломня» или «Дракон» — это свиток-заклинание,
которое отдаёт игрок, а не буквальный предмет/существо).

> **Раздел ниже — исходный план ДО реализации, частично устарел.** По факту реализовано в
> `entities/card/card.tscn`/`card.gd` (см. хронологию правок в git и GitHub Issue ARC-091) —
> расходится с планом в двух местах: (1) лента-баннер для имени карты сделана и затем убрана — не
> вписывалась в пергамент, тем более после перехода иллюстраций на сепию; имя теперь рисуется прямо на
> пергаменте стилизованным "чернильным" текстом (`curved_label.gd`, дрожание почерка через
> `jitter_position`/`jitter_rotation_degrees`), без отдельной подложки; (2) цветовой подтон самой
> бумаги (упомянут ниже) не сделан — цветовое кодирование ресурса в итоге только на восковой печати
> (`SealBadge`), не дублируется больше нигде. Остальное (пергамент фона, печать вместо числового
> бейджа, материал печати = редкость) реализовано близко к плану.

**Решение:** карта остаётся прямоугольной (150×220, та же сетка/якоря/тач-зоны, что и сейчас —
ничем не рискуем в раскладке руки/магазина/награды), но одета как состаренный пергамент/свиток, а не
как плоская заливка цветом ресурса:

* **Фон карты** — текстура старой бумаги (лёгкие потёртости/подпалины по краю внутри рамки), а не
  сплошной `Color` по типу ресурса, как сейчас (`entities/card/card.gd::update_ui()`,
  `background.modulate`).
* **Имя карты** — на подвешенной ленте-баннере сверху, а не в обычном `Label` на однородном фоне.
* **Стоимость** — восковая печать в углу вместо круглого числового бейджа.
* **Цветовое кодирование ресурса** (GDD §11.2, менять нельзя — единственный невербальный ориентир)
  переезжает с фона на акценты: цвет воска печати + цвет нити/ленты банта. Плюс лёгкий цветной подтон
  самой бумаги (слабый, чтобы не убить текстуру), чтобы ресурс читался и боковым зрением, не только по
  печати.
* **Редкость** — материал печати/ленты, не отдельное кольцо на весь фон: простая бечёвка (Common),
  серебряная лента (Uncommon), золотая печать с гербом и лёгким свечением (Rare). Та же логика
  "материал = редкость", что уже обсуждали для векторного варианта, просто перенесена с рамки всей
  карты на печать/бант.
* **Иллюстрация** (§1-4 выше) — без изменений, тот же расписанный арт в area `IconTexture`.

### Как это лечь в код (план, не выполнено)

`entities/card/card.tscn`/`card.gd` не переписываются с нуля — только замена того, чем рисуются
существующие узлы, имена/логика в `card.gd` (`update_ui()`) остаются те же:

* `Background` (`ColorRect`) → `NinePatchRect` с текстурой пергамента; `patch_margin_*` подобраны так,
  чтобы потрёпанный край не растягивался, а середина — тянулась под 150×220. Ресурсный подтон — через
  `modulate` на этом же `NinePatchRect` (слабый множитель, не полная заливка, как сейчас).
* Новый узел `SealBadge` (`TextureRect`) вместо/поверх `CostLabel` — текстура печати (одна форма/орнамент
  на редкость, 3 текстуры: бечёвка/серебро/золото), сам номер стоимости — `Label` поверх, по центру.
  Цвет воска — `modulate` на печати по типу ресурса (те же 3 текстуры печати переиспользуются на все три
  ресурса, не 9 отдельных файлов).
* Новый узел `NameBanner` (`TextureRect`) позади `NameLabel` — текстура ленты-баннера, один вариант на
  все карты (не зависит от типа/редкости, чтобы не плодить комбинации).
* `Border` (`ReferenceRect`) скорее всего становится не нужен — потрёпанный край уже даёт пергамент;
  либо остаётся как тонкая по-редкости обводка поверх, если после реализации визуально не хватает
  чёткой границы на боевом экране/в руке.
* Все новые текстуры — растровые (не плоский SVG-вектор, как в отклонённом варианте): бумажная фактура,
  воск, лента — органика, которую вектором рисовать вручную не имеет смысла. Значит нужен реальный
  растровый арт (AI-генерация/художник, тот же пайплайн, что и для иллюстраций §1) — три новых промпта
  ниже, а не что-то, что можно сгенерировать программно, как пробовали в первой (отклонённой) версии.

### Промпты для новых текстур (тот же мастер-стиль §1, но это пропсы/текстуры, не персонажи)

**Пергамент (фон карты):**
```
Seamless aged parchment paper texture, warm cream and light brown tones, subtle fiber
grain, soft stains and light burn marks concentrated near the edges, worn and slightly
crumpled but still fully legible in the center, painterly digital texture matching a
stylized 2D fantasy card game (Clash Royale / Hearthstone art direction) — not
photorealistic scan, no text, no visible border/frame drawn on it, no watermark. Vertical
3:4 orientation, edges are the busiest part, center is calm and clean for text/art overlay.
```

**Лента-баннер (для имени карты):**
```
A short decorative fantasy ribbon banner, painterly 2D game-art style matching Clash
Royale / Hearthstone, aged parchment-brown ribbon with slightly frayed cloth edges,
gently draped/curved as if pinned at both ends, empty (no text on it) so a game title can
be overlaid on top, warm neutral tones so it works over any card color-coding, no
watermark, no background (isolated on transparent).
```

**Восковые печати, по редкости (3 отдельные текстуры, форма — не цвет; цвет ресурса накладывается
`modulate` в движке, поэтому сама печать должна быть в нейтральном/светлом воске на референсе).**

Первая попытка вышла неудачной: печати сгенерировались как 3D-рендер предмета под углом (перспектива
сверху-сбоку, объёмная "подушка", глянцевые блики, длинная тень) — смотрится как иконка инвентаря ролевой
игры, а не как плоский элемент карты в том же стиле, что остальной арт. Промпт ниже явно требует плоский
вид строго анфас и минимум деталей (эта иконка в игре отображается совсем маленькой — badge стоимости в
углу карты, ~20×20px):

```
Flat 2D icon of a wax seal, viewed straight-on / top-down (orthographic front view, NOT a
3D-rendered object, NOT at an angle, NOT isometric, no perspective tilt), painted in the
same painterly 2D style as the rest of the card game's art (Clash Royale / Hearthstone UI
icon style) but drastically simplified — bold flat silhouette, minimal shading, only 1-2
tones of shadow, no glossy highlights, no drop shadow, no glow, no rim light. Perfectly
circular outer silhouette, isolated on transparent background, no text/no number on it (a
number will be overlaid separately). Must stay clearly readable as a simple round icon at
very small size (roughly 20x20 pixels on screen) — three variants needed, generate
separately, each as simple as possible:
1) Common: a flat round wax circle with a simple twine string laid across it in a flat X,
   humble, rough uneven outer edge, minimal detail.
2) Uncommon: a flat round wax circle with a thin flat silver ring around the rim, minimal
   detail, no other ornament.
3) Rare: a flat round wax circle with a thin flat gold ring around the rim and ONE small
   simple flat symbol in the center (a single plain shape, not a detailed crest), minimal
   detail.
Neutral pale wax color (so in-engine tinting can recolor it per resource type), flat even
lighting, no gore, no watermark.
```

**Пергамент фона — версия с рваными краями ("развёрнутый свиток").** По просьбе автора тикета — текущий
`parchment_bg.png` (прямоугольная текстура, потёртость только цветом/тенью у края, растягивается через
`NinePatchRect`) заменяется на текстуру с НАСТОЯЩЕЙ рваной альфа-кромкой (вырез по неровному контуру, а
не просто цвет). `NinePatchRect` для неровного силуэта не годится — растягиваемая середина исказит рваный
край, если он попадёт в зону растяжения. Как только текстура готова, `Background` в `card.tscn`
переключается с `NinePatchRect` обратно на обычный `TextureRect` (тот же приём, что уже у ленты/печатей) —
без 9-slice, просто масштабируется под размер карты целиком.

```
A single sheet of aged parchment paper, unrolled flat, viewed straight-on / top-down (NOT
at an angle, NOT a 3D-rendered object). Painterly 2D texture matching a stylized fantasy
card game (Clash Royale / Hearthstone art direction), warm cream and light brown tones,
subtle fiber grain, soft stains and light burn marks concentrated near the edges, worn but
still fully legible and clean in the center for text/art overlay. The paper's outer edge
must be genuinely torn and ragged all the way around — irregular hand-torn notches, small
frayed fiber wisps sticking out unevenly, NOT a clean rectangle and NOT a uniform scalloped
pattern, each side torn differently. Vertical portrait orientation, taller than wide
(roughly matching a tarot/playing card silhouette). Everything outside the torn paper
shape must be transparent (isolated cutout on alpha channel, not a background color) — the
ragged silhouette itself IS the edge of the image content. No text, no drawn border/frame
line on top of it, no watermark.
```

---

## 6. Иконки ресурсов (HUD боя)

`ui/battle/battle_screen.gd`/`.tscn` — счётчики ресурсов сейчас просто текст (`"Bricks: 5 (+1)"`,
`%BricksLabel`/`%GemsLabel`/`%BeastsLabel` и зеркальные `%Enemy*Label`), без иконок. План — заменить
слово на иконку ресурса перед числом (`"5 (+1)"` рядом с картинкой вместо `"Bricks: 5 (+1)"`).

Это HUD-элемент, не иллюстрация карты — рядом нет пергамента (обычные `Label` в `HBoxContainer` на
дефолтной теме), и по GDD §11.2 цвет — единственный невербальный ориентир ресурса, так что, в отличие
от иллюстраций карт (§1, сознательно монохромные), эти иконки ЦВЕТНЫЕ: та же палитра, что уже
используется для акцентов ленты/печати на картах (§2, исторический для иллюстраций, но актуальный
именно как справочник цвета) — терракотовый красный / сапфировый синий / мшисто-зелёный. Стиль —
тот же язык упрощённой плоской иконки, что уже утверждён для восковых печатей §5 (жирный плоский
силуэт, минимум деталей, читается совсем маленьким), а не полноценная иллюстрация §1.

Один запрос — три иконки в одном изображении рядом (тот же приём, что и с печатями §5: одна генерация,
дальше нарезка по альфа-каналу программно), не три отдельных прогона:

```
Three separate flat 2D game UI icons for a fantasy resource-management card game,
arranged in a row side by side with clear empty space between each one so they can be
cropped apart individually. Each icon: bold, clean, simplified silhouette, painterly but
drastically reduced detail (only 1-2 tones of shading, no glossy highlights, no drop
shadow, no glow), viewed straight-on / orthographic (NOT a 3D render, NOT isometric, NOT
at an angle). Must stay clearly readable as a small UI icon at very small size (roughly
24x24 pixels on screen). Isolated on a transparent background, no text, no numbers, no
watermark, no card frame, family-friendly tone.

1) Bricks resource: a small stack of 2-3 roughly-hewn terracotta/clay bricks, warm
   brick-red and rust-orange tones, faint mortar lines.
2) Gems resource: a single faceted crystal gem, sapphire blue with one bright highlight
   facet, simple geometric cut.
3) Beasts resource: a single animal paw print (or a small simplified wolf/beast head
   silhouette, whichever reads clearer at tiny size), mossy green and warm brown tones.

Style matches a painterly 2D fantasy card game art direction (Clash Royale / Hearthstone
UI icon style), simplified for small-size HUD use, not a detailed illustration.
```

После генерации — та же обработка, что уже применялась к печатям (GitHub Issues,
ARC-091): нарезать по альфа-каналу на 3 отдельных файла (`art/hud/icon_bricks.png`,
`icon_gems.png`, `icon_beasts.png` — путь предварительный, можно поменять), подключить как
`TextureRect` рядом с каждым `Label`/вместо текста "Bricks"/"Gems"/"Beasts" в `battle_screen.tscn`,
число оставить обычным `Label` рядом с иконкой (`"%d (+%d)"`, без названия ресурса словом).

---

## 7. Макеты фона боевого экрана (`ui/battle/battle_screen.tscn`)

Сейчас `Background` боевого экрана — сплошной `ColorRect` (`Color(0.15, 0.15, 0.2)`), без арта.

**Раскладка — правка автора тикета, расходится с текстом GDD §10.3.** Текст GDD описывает зеркальную
раскладку "противник сверху, игрок снизу", но **фактическая раскладка в игре и то, что нужно для
макетов — башня игрока СЛЕВА, башня противника СПРАВА**, растут навстречу друг другу к центру (это и
подтверждает реальный код/скриншоты `PlayerStats`/`EnemyStats` в `battle_screen.tscn` — они уже
horizontal, не vertical). Это стоит когда-нибудь поправить и в самом тексте GDD §10.3, отдельно от
этого арт-брифа — не делаю сейчас, чтобы не смешивать правку документации с подготовкой промпта.

**Не арена, а сами башни — с визуализацией размера и ресурсов.** Не общий вид поля боя, а именно две
конкретные башни как главный визуальный объект: у каждой должно быть видно, ЧТО она растёт из
блоков (уже реализовано в коде отдельным слоем — `PlayerTowerBar`/`EnemyTowerBar`, растущая стопка —
GDD §10.3, "фирменная фишка визуализации", сохранить), и рядом с базой каждой башни — небольшие кучки
трёх ресурсов (кирпичи/самоцветы/звериные шкуры), чтобы экономика читалась не только числом в HUD, но
и на глаз, боковым зрением, прямо в арт-фоне.

**Важная оговорка по инструменту.** ChatGPT/Midjourney не умеют надёжно рисовать реальный
функциональный UI (точный текст, числа, кнопки на нужных местах, тем более ДИНАМИЧЕСКИ меняющийся
размер башни по ходу боя) — просить "весь экран боя с цифрами и текстом" бессмысленно, получится
каша из нечитаемых символов. Промпты ниже просят только **фоновую иллюстрацию/окружение** (одно
статичное референсное состояние башен и куч ресурсов, задающее стиль, не сам работающий механизм
роста) — сам HUD (иконки ресурсов §6, счётчики, рука карт, растущие блоки башни, кнопки) остаётся
настоящими нодами Godot поверх этого фона, как уже сделано.

Три варианта направления, чтобы было из чего выбирать.

**Решение (предварительное, до генерации/визуальной проверки).** Обсудили все три — вариант 1
(сепия по всему экрану) рискует читаемостью: белый HUD-текст на светлом пергаменте почти не виден
(пришлось бы перекрашивать весь текстовый HUD в тёмные чернила), и цветные partиклы урона/стройки
(GDD §11.4, должны быть "сочными") будут спорить по тону со старой бумагой. Вариант 3 (яркая арена) —
та же насыщенная цветная эстетика, от которой уже сознательно ушли для иллюстраций карт. **Выбран
вариант 2** — тёмный/мистический, даёт нужный контраст под HUD и партиклы, не спорит с сепийными
картами (светлый пергамент карты на тёмном фоне — естественный контраст, карта "выступает" вперёд),
и по духу ближе к сеттингу GDD ("маги-подмастерья"). Не реализовано — ждём генерацию и визуальную
проверку перед тем как трогать `battle_screen.tscn`.

**Уточнение по скоупу — правка автора тикета.** Промпты ниже (все три варианта) изначально просили
нарисовать САМИ башни как часть фона — это неверно: башни (растущая стопка блоков, `PlayerTowerBar`/
`EnemyTowerBar`) уже отдельный динамический слой поверх фона, который реагирует на розыгрыш карт
(растёт/меняется в реальном времени) — если запечь башни в статичный фоновый арт, будет два
конфликтующих изображения башни одновременно. **`Background` — это только атмосфера/окружение, без
башен и без куч ресурсов у их основания** (ту идею с кучками ресурсов тоже отменяет — они были
привязаны к базам башен, которых в фоне больше нет).

**Правка после первой генерации — «помещение» не годится.** Первая версия промпта (см. историю ниже)
вышла как интерьер мастерской (каменный зал, арки, колонны) — стилистически хорошая, но по смыслу не
работает: башни физически не могут стоять внутри помещения, а игра именно про две башни, растущие
навстречу друг другу. Актуальный промпт — та же тёмная мистическая палитра и настроение, но открытое
пространство (ночное небо, а не потолок и стены):

```
A wide 16:9 background illustration for a fantasy card game battle screen — atmosphere and
environment only, no towers, no buildings, no characters, no piles of objects, nothing in
the foreground. An open-air, moody twilight/night magical battlefield: a dim cracked stone
or earthen ground stretching from the left edge of the frame to the right, open dark night
sky above with faint stars and soft magical aurora-like glow near the horizon, faint
floating magic runes and glowing particles drifting in the air just above the ground,
distant silhouettes of low ruins or mountains fading into haze near the horizon line (not
overhead architecture — nothing should read as a ceiling or indoor space). Deep indigo and
muted purple palette, painterly 2D game-art style (Clash Royale-adjacent but darker and
moodier), no gore, no text, no watermark. The entire image — left, right, and especially
the center and lower two-thirds — must stay dark, low-contrast and visually calm/empty,
since game towers, cards, and UI will be placed on top of it afterward.
```

Промпты с башнями ниже (все три варианта) и первая (интерьерная) версия скоуп-промпта оставлены как
есть для истории обсуждения — актуальный для генерации сейчас только промпт выше.

**Вариант 1 — "Иллюминированная рукопись".** Максимально созвучно уже принятому стилю карт (§1,
сепийная тушь на пергаменте) — весь экран боя выглядит как разворот старинного гримуара, на котором
разыгрывается бой.

```
A wide 16:9 background illustration for a fantasy card game battle screen, in the same
monochrome sepia ink-and-wash style as an old illuminated manuscript bestiary — as if the
entire scene is drawn directly on a large aged parchment page, not a separate scene pasted
behind the UI. Two opposing towers made of stacked rough-hewn bricks, sketched in the same
bold ink linework: one tower positioned at the LEFT edge of the frame (the player's), one
at the RIGHT edge (the enemy's), facing each other across a calm, mostly empty parchment
gap in the middle reserved for game UI. At the base of each tower, a few small distinct
piles: a modest stack of bricks, a small cluster of faceted gems, and a folded animal pelt
with a paw print nearby — visually representing that tower's stockpiled resources, sketched
in the same ink style, simple and small, not competing with the towers themselves. Faint
decorative ink flourishes and subtle aged stains only near the very edges of the frame. No
text, no numbers, no UI elements, no watermark, no color, family-friendly tone.
```

**Вариант 2 — "Мастерская подмастерья".** По духу сеттинга GDD ("маги-подмастерья") — мистическая
арена/мастерская, темнее и атмосфернее, с магическим свечением.

```
A wide 16:9 background illustration for a fantasy card game battle screen. A moody, twilight
magical dueling scene between two apprentice mages' towers built from stacked stone blocks —
one warm-lit tower at the LEFT edge of the frame (the player's), one cool-lit tower at the
RIGHT edge (the enemy's), facing each other across a shadowy arcane gap in the middle with
faint floating magic runes and soft glowing particles, reserved for game UI. At the base of
each tower, small glowing piles representing that side's resources: a stack of stone bricks,
a cluster of glowing crystal gems, and a folded fur pelt with a paw print — simple, modest in
size, not competing with the towers. Deep indigo and muted purple palette, painterly 2D
game-art style (Clash Royale-adjacent but darker and moodier), no gore. The image must stay
dark, low-contrast and visually calm in the central gap and lower area — reserved for game UI
(cards, counters, buttons) to be placed on top later. No text, no numbers, no UI elements, no
watermark.
```

**Вариант 3 — "Яркая арена".** Ближе к исходному брифу GDD §11.1 (насыщенный, но не мрачный
Clash Royale/Hearthstone стиль) — самый жизнерадостный/"постер"-вариант из трёх.

```
A wide 16:9 background illustration for a fantasy card game battle screen. Two colorful
toy-like stone towers built from stacked bricks, one at the LEFT edge of the frame
(player's) and one at the RIGHT edge (enemy's), facing each other across a bright, sunny
storybook sky with soft clouds in the gap between them, reserved for game UI. At the base of
each tower, small tidy piles representing that side's resources: a stack of red-brown
bricks, a cluster of blue faceted gems, and a green-brown fur pelt with a paw print — simple
shapes, modest size, not competing with the towers. Bold, clean, saturated but not garish
colors, painterly 2D game-art style in the spirit of Clash Royale, no gore, family-friendly.
The central gap and lower area should stay soft, blurred and less detailed — reserved for
game UI (cards, counters, buttons) to be placed on top later. No text, no numbers, no UI
elements, no watermark.
```

После генерации — можно сравнить все три варианта прямо в браузере поверх текущего скриншота боевого
экрана (наложение полупрозрачным слоем) перед тем как выбирать и интегрировать любой из них.
