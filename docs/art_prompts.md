# Промпт-бриф для арта карт (для внешнего AI-инструмента/художника)

Дополняет ARC-091. История стиля: первый вариант был плоский векторный "щит-медальон" — отклонён
("совсем не то"). Второй — расписанный насыщенный 2D-арт в духе Clash Royale/Hearthstone (яркий
cel-shading, отдельная фоновая сцена за персонажем). На карте «Гоблин» этот вариант конфликтовал с
шаблоном карты (§5 — состаренный пергамент/свиток): иллюстрация со своей сюжетной сценой (лес/небо)
всегда читалась как отдельная фотография-вставка поверх пергамента, а не как рисунок на той же
"бумаге", сколько её край ни растушёвывай программно (см. историю правок в `docs/dev_plan_tickets.md`,
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
исторический) для иллюстраций больше не используется.

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
> `entities/card/card.tscn`/`card.gd` (см. хронологию правок в `docs/dev_plan_tickets.md`, ARC-091) —
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
