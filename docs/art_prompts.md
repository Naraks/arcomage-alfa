# Промпт-бриф для арта карт (для внешнего AI-инструмента/художника)

Дополняет ARC-091. Ранний вариант стиля был плоский векторный "щит-медальон" — по фидбэку не подошёл
("совсем не то"), поэтому здесь другое направление: **расписанный 2D-арт в духе Clash Royale /
Hearthstone**, как и требует GDD §11.1, без щита/кольца редкости внутри самой иллюстрации (рамку и
индикатор редкости рисует движок поверх готового арта — см. §3 ниже, и §5 про сам шаблон карты).
Генерировать через Midjourney/ChatGPT Images/Leonardo/Stable Diffusion или отдавать художнику как
техзадание — промпт одинаково читается в обоих случаях.

## 1. Мастер-промпт (стиль, общий для всех карт)

Блок стиля не меняется от карты к карте — меняется только "Subject" (§4) и палитра по ресурсу (§2).

```
Stylized 2D fantasy trading card game illustration, painterly digital art in the style of
Clash Royale and Hearthstone card art. Bold, clean, readable silhouette even at small
thumbnail size. Warm painterly rendering with soft cel-shaded lighting, semi-realistic but
slightly exaggerated cartoonish proportions, rich saturated colors. Single subject centered
as the hero of the frame, filling 70-80% of the composition. Dramatic rim light separating
the subject from a soft, blurred, simplified background (shallow depth of field) so the
background never competes with the subject. Vertical 3:4 portrait orientation, camera at a
slight low angle. No text, no logos, no watermark, no card frame or border, no gore or blood,
family-friendly / all-ages tone.
```

**Негативный промпт** (Stable Diffusion/Leonardo; для Midjourney — через `--no`):
```
text, watermark, signature, logo, card frame, border, UI elements, blood, gore, photorealistic,
3d render, low quality, blurry subject, extra limbs, deformed hands
```

## 2. Палитра по типу ресурса (GDD §5.1/11.2 — не менять свободно)

| Тип | Палитра сцены/освещения |
| :--- | :--- |
| Кирпичи (красный) | Тёплый каменно-кирпичный — терракота, охра, серый камень; фон — пыль/строительная площадка. |
| Гемы (синий) | Холодный магический — сапфир, электрик-синий, фиолетовые отсветы; фон — мерцающая аура/руны. |
| Звери (зелёный) | Природный — мшисто-зелёный, коричневый, янтарный; фон — лес/пещера/логово. |

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
Stylized 2D fantasy trading card game illustration, painterly digital art in the style of
Clash Royale and Hearthstone card art, bold clean readable silhouette, warm painterly
cel-shaded lighting, rich saturated colors, single subject centered filling 70-80% of frame,
dramatic rim light against a soft blurred forest background, vertical portrait orientation,
slight low camera angle, no text, no frame, no gore, family-friendly ::
a small scrawny goblin, mottled sickly-green skin, oversized pointed ears, mischievous
crooked grin, one eye squinted, crouched mid-lunge gripping a small rusty jagged dagger,
ragged leather scraps and burlap loincloth, no armor, quick and sneaky body language, not
heroic or powerful, mossy green and brown natural palette, soft dark forest background blur
--ar 3:4 --style raw --no text, watermark, frame, blood, extra limbs
```

**Тот же промпт для DALL-E/ChatGPT Images/Firefly (обычным текстом, без `--` параметров):**
```
Create a stylized 2D fantasy trading card illustration in the painterly style of Clash Royale
and Hearthstone card art. Bold, clean, readable silhouette. Warm cel-shaded lighting, rich
saturated colors, vertical 3:4 portrait composition, subject centered and filling most of the
frame, soft blurred forest background with dramatic rim lighting separating the subject from
it. No text, no card frame, no watermark, no gore, family-friendly tone.

Subject: a small, scrawny goblin with mottled sickly-green skin, oversized pointed ears, a
mischievous crooked grin with one eye squinted. It's crouched in a mid-lunge pose, gripping a
small rusty jagged dagger, wearing only ragged leather scraps and a burlap loincloth, no
armor. Its body language should read as quick and sneaky, not powerful or heroic — this is a
cheap, low-tier minion, not a boss monster. Natural mossy green and brown palette.
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
