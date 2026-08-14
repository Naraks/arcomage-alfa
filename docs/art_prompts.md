# Визуальный гайд и библиотека промтов

Этот файл — обязательная отправная точка для любой последующей генерации арта игры. Перед генерацией
нужно определить тип ассета, взять соответствующий мастер-промт ниже, добавить предметный блок и
сверить результат с указанными референсами из репозитория. Новый арт не должен вводить отдельный стиль.

## 1. Художественная ДНК игры

Мир — мрачное, но семейное сказочное фэнтези о башнях магов, старых руинах, ремесле, алхимии и
приручённых чудовищах. Визуальная основа сочетает:

- глубокие чернильно-синие и фиолетовые тени;
- тёплое золото, медь, воск, огонь и пергамент как контраст;
- ручную фактуру: тушь, гравюра, живописные мазки, камень, дерево, металл;
- крупный читаемый силуэт и один главный фокус;
- стилизацию уровня качественной 2D fantasy-игры, без фотореализма и без пластиковой 3D-гладкости;
- волшебство через руны, частицы, тонкое свечение и энергию, а не через визуальный шум.

Канонические референсы:

| Назначение | Референс | Что сохранять |
| :--- | :--- | :--- |
| Карты | `art/cards/goblin.png`, `art/cards/beast_hunter.png` | Сепийная тушь прямо на старом пергаменте, один субъект, без сцены. |
| Фоны | `art/battle/background_battlefield.png` | Ночная сине-фиолетовая палитра, эпический простор, свободное место под UI. |
| Предметы | `art/rest/magic_source.png`, `art/rest/tower_foundation.png` | Чистый силуэт, золото/медь, насыщенное магическое свечение, прозрачный фон. |
| Малые иконки | `art/map/nodes/*.png`, `art/hud/*.png` | Один символ, толстые формы, золотой контур, читаемость в 28–64 px. |
| Брендинг | `art/branding/app_icon.png`, `loading_splash.png` | Башня/магическая дуэль, тёмный фон, золото и фиолетовое свечение. |

## 2. Общие правила генерации

1. Сначала прочитать связанный `.tres`, экран и назначение ассета. Иллюстрация передаёт функцию, а не
   только буквальное название.
2. Не генерировать текст, цифры, логотипы, рамки и элементы интерфейса внутри изображения. Их рисует Godot.
3. Оставлять безопасные поля под кадрирование и UI. Главный объект не касается краёв.
4. Генерировать минимум четыре варианта; выбирать по силуэту и читаемости в целевом размере.
5. Проверять уменьшенную копию в реальном интерфейсе. Красивый полный кадр может быть плохой иконкой.
6. Не перерисовывать канонические ассеты без отдельной задачи. Новый арт наследует их язык форм и палитру.
7. Исходник хранить отдельно; в `art/` или `assets/` класть только подготовленный игровой файл.

Универсальный негативный блок:

```text
text, letters, numbers, caption, watermark, signature, logo, user interface, card frame,
photorealism, photography, glossy plastic 3D render, modern objects, science fiction,
anime, chibi, flat corporate vector art, excessive bloom, visual clutter, muddy silhouette,
low contrast focal subject, cropped subject, gore, blood, horror, extra limbs, malformed hands
```

## 3. Карточные иллюстрации

### 3.1 Мастер-промт

Карты используют сепию как основной режим. Полноцветная сюжетная сцена внутри карты запрещена: она
выглядит вклеенной фотографией и конфликтует с `art/card_frame/parchment_bg.png`. Допускается один
локальный приглушённый цветовой акцент, обозначающий ресурс карты: кирпично-красный для Кирпичей,
сапфирово-синий для Гемов и травянисто-зелёный для Зверей. Акцент занимает примерно 5–12% изображения
и наносится только на смысловые детали субъекта — ткань, руны, минерал, магическую энергию, ремни или
небольшие элементы снаряжения. Фон, пергамент, тени и большая часть субъекта остаются сепийными.

```text
Monochrome sepia ink illustration from an old illuminated manuscript bestiary, drawn and
engraved directly onto warm aged parchment. Expressive dark-brown linework, fine cross-hatching,
soft diluted sepia wash, visible paper grain, one strong central subject, clean readable silhouette,
subtle hand-drawn ornamental flourishes fading into the parchment, no separate background scene,
no horizon, no rectangular picture edge. Medieval fantasy with slightly exaggerated storybook
proportions, detailed but readable at card size, family-friendly. Compact near-horizontal 6:5
composition, with the main subject filling 85–90% of the canvas and all essential details inside safe
margins. No closed ornamental frame, no large empty parchment areas, no text, no card border, no UI.
Predominantly monochrome sepia with one restrained resource-color accent covering about 5–12% of the
image; no other colors.
```

Дополнительный негативный блок карт:

```text
full-color painting, colored background, colored sky, landscape, room, scenic background, white cutout
background, hard rectangular edge, large colored aura, multiple accent colors, neon saturation,
modern comic book, photorealistic skin, card template
```

Техническая цель: исходник 6:5 не меньше 1200×1000 для игровой области около 126×103. Арт должен
вписываться целиком без дополнительного кропа: главный субъект занимает 85–90% кадра, пустые поля
минимальны, лицо, руки, оружие и главный символ не подходят вплотную к краям. Для персонажей
предпочтительны погрудные и поясные композиции, для механизмов — крупный план действия. Рамку, имя,
стоимость, ресурс и редкость добавляет движок.

### 3.2 Как составлять предметный блок карты

```text
Subject: [кто или что], [характерный силуэт и поза], [один главный предмет], [материал/одежда],
[визуальное действие, соответствующее эффекту карты]. [Ограничение силы по редкости].
```

- Кирпичи: каменщики, стены, башни, осадные машины, молоты, руны кладки. Формы тяжёлые и устойчивые;
  локальный акцент — приглушённый кирпично-красный или терракотовый.
- Гемы: маги, кристаллы, молнии, порталы, заклинания. Формы тонкие, дугообразные, направленные;
  локальный акцент — сапфирово-синий или холодный сине-фиолетовый.
- Звери: существа, охотники, стаи, когти, клыки. Формы живые, диагональные, динамичные;
  локальный акцент — приглушённый травянисто-зелёный или изумрудный.
- Common: простое снаряжение и ясное действие, без величия.
- Uncommon: более уверенная поза и одна необычная деталь.
- Rare: монументальный силуэт, драматичный жест и один уникальный магический мотив, но всё ещё сепия.

### 3.3 Канонические предметные блоки

**Гоблин — дешёвый быстрый урон:**

```text
Subject: a small scrawny goblin with oversized pointed ears, a crooked opportunistic grin and one
squinting eye, crouched in a quick forward lunge. He grips one chipped jagged dagger and wears only
ragged leather scraps tied with rope. Low-tier minion, nimble and treacherous rather than heroic or
powerful, both hands and the complete dagger clearly visible.
```

**Зверолов — прирост добычи зверей:**

```text
Subject: a weathered human trapper in practical worn leather and fur, crouched while reading tracks.
A coil of snare rope crosses one shoulder, a small knife hangs at the belt and two modest pelts rest
on the other shoulder. Alert profile, humble working equipment, no magic, no ornate armor, common
craftsman rather than heroic warrior.
```

Для остальных карт предметный блок строится из `card_name`, `description`, `type`, `rarity` и эффектов
в `data/cards/*.tres`. Не повторять один общий значок ресурса: каждая карта должна иметь собственный
сюжетный символ. Например, `build_wall` показывает возведение или укрепление стены, `damage` — момент
атаки, `mod_magic` — настройку магического источника, `steal_resource` — явное похищение сосуда или
энергии, а `draw_card` — раскрывающийся гримуар или веер свитков.

## 4. Артефакты

Артефакт — одиночный коллекционный предмет на прозрачном фоне. По технике он цветной и ближе к
`art/rest/magic_source.png`, а не к карточной сепии.

### 4.1 Мастер-промт артефакта

```text
Single enchanted medieval-fantasy relic, centered product-icon composition on transparent background.
Hand-painted 2D game art, strong clean silhouette, ornate but readable craftsmanship, aged gold, bronze,
dark iron, carved stone and jewel materials, deep violet and sapphire magical glow, warm amber rim light,
subtle runes and a few controlled energy particles. Three-quarter view, no pedestal unless integral to
the object, no environment, no cast-off props, family-friendly, premium collectible item, readable at
96 pixels, no text, no frame, no UI. Square composition with 12 percent transparent padding.
```

Предметные блоки всех текущих артефактов:

| Артефакт | Subject-блок |
| :--- | :--- |
| Кирка Гнома | A compact masterwork dwarven pickaxe, short dark-oak handle, broad rune-etched steel head, chips of glowing red ore caught along the edge; sturdy working tool, not a weapon. |
| Рог Изобилия | A curved ancient horn overflowing with three restrained magical streams symbolizing brick-red ore, sapphire gems and emerald beast energy; bronze bands and woven cord. |
| Книга Мудрости | A thick closed grimoire with worn burgundy leather, brass corner guards, six subtle page markers and one luminous eye-shaped clasp; knowledge and expanded capacity. |
| Сфера Маны | A levitating sapphire-violet crystal orb held by three delicate golden prongs, a single spiral of blue mana returning into the sphere. |
| Счастливая Монета | One thick antique gold coin turning in the air, smiling crescent on one face, faint probability runes and a restrained lucky glint; no pile of coins. |
| Шипастая Стена | A compact crenellated stone wall fragment reinforced with black iron spikes, one spike glowing from reflected impact; defensive and retaliatory. |
| Благословение Основателя | A small golden foundation stone bearing the first tower rune, protected by a translucent warm shield that also traces a tiny tower silhouette. |
| Клык Хищника | One large curved predator fang bound in dark leather and bronze, emerald beast-energy scratches following its curve; primal but clean, no blood. |

Экспорт: квадратный PNG, предпочтительно 512×512, прозрачный фон, без искусственной тени до края.

## 5. Иллюстрации событий

События — небольшие кинематографичные сцены путешествия. Они должны совпадать по атмосфере с ночным
полем боя, но иметь тёплый локальный источник света и ясный выбор/опасность в одном кадре.

### 5.1 Мастер-промт события

```text
Atmospheric hand-painted 2D dark-fantasy storybook scene for a game event, wide 3:2 composition.
Midnight indigo and violet environment, ancient stone and weathered wood, one warm amber or magical
light source guiding the eye, painterly texture, slightly exaggerated readable shapes, mysterious but
family-friendly. One clear narrative focal point in the central 60 percent, foreground framing shapes,
depth through mist and layered silhouettes, restrained rune glow, no interface, no text, no border,
no photorealism. Keep all essential figures fully visible and leave calm dark margins for contain scaling.
```

Сцены текущих событий:

| Событие | Subject-блок |
| :--- | :--- |
| Заброшенный склад | A leaning roadside warehouse with a broken door, two dimly gleaming chests visible beyond rotten floorboards, danger shown by a fresh crack crossing the entrance. |
| Древний алтарь | A ruined moonlit altar with two offering bowls, rough stone on the left and clear crystal on the right, dormant runes waiting between them. |
| Звериный аукцион | A nomad night market with one proud caged battle beast and one suspicious cheap egg on a rug, merchants gesturing toward both choices. |
| Звериное логово | A shadowed ravine den, several pairs of watchful eyes around a bait bundle in the foreground, tension without attack or gore. |
| Обрушившаяся шахта | A mine entrance blocked by timber and stones, warm lantern light and tiny sparks of pickaxes visible through a narrow gap. |
| Игра костей | A weathered tavern table under one hanging lamp, two sets of dice and two coin stakes, ordinary and dangerously high, with shadowed players around it. |
| Караван гномов | A richly built dwarven wagon stuck axle-deep in a flooded road, merchants offering a rolled blueprint and a small coin chest. |
| Загадка горгулий | Two living stone gargoyles guarding a narrow bridge, one holding a rune tablet and the other an open payment bowl. |
| Учения у мастера | An old martial mage in a quiet ruin presenting a safe training circle beside a harsher obstacle course lit by sparks. |
| Магическая буря | A road beneath a twisting violet mana storm, a grounded copper rod on one side and a mage attempting to channel the torrent on the other. |
| Лунный колодец | An ancient circular well whose water reflects a possible tower-filled future instead of the sky, offering runes carved into the rim. |
| Разорённая мастерская | A ruined siege workshop, moonlight on surviving tools and one half-built mechanism among broken beams. |
| Рунный каменщик | A broad dwarven mason at a roadside bench, carving a tower-foundation rune while a finished glowing slab rests beside him. |
| Карточный шулер | A sly hooded cardsharp beside a campfire, holding three sealed face-down parchment cards in a fan, six coins on the blanket. |
| Раненый путник | A wounded armored traveler resting against a milestone, reaching toward a small supply satchel, hopeful rather than graphic. |

Экспорт: PNG 3:2, минимум 1200×800. Текущий экран использует contain, поэтому важная сцена не должна
зависеть от обрезки по краям.

## 6. Фоны экранов и боевой арены

### Мастер-промт фона

```text
Epic wide hand-painted 2D fantasy environment at night, 16:9. Vast ancient magical wasteland under a
deep indigo and violet starry sky, distant mountains and ruined arches, subtle arcane circles embedded
in clouds and cracked stone, painterly game-background finish, dark navy foreground, sparse purple
glints, restrained atmospheric perspective. No characters, no towers in the central play area, no text.
The center and lower-middle remain low-detail and low-contrast for cards and HUD; visual landmarks stay
near the outer thirds. Seamless full-bleed composition, family-friendly, no photorealism.
```

Референс — `art/battle/background_battlefield.png`. Для нового экрана сохранять 16:9 и заранее описывать
зоны UI: где нужны пустота, затемнение и безопасная область. Фоны меню могут повторно использовать мир
арены; нельзя генерировать интерьер, если по смыслу на сцене одновременно должны стоять две башни.

## 7. Карта мира и иконки узлов

### Мастер-промт иконки узла

```text
Single medieval-fantasy map symbol, centered transparent-background game icon, hand-painted 2D,
chunky readable silhouette, warm antique gold and bronze outline, dark inner shadow, one restrained
red, violet or blue accent, slightly embossed storybook craftsmanship, front or simple three-quarter
view, no environment, no text, no frame, readable at 28 pixels, square composition.
```

Символы: бой — скрещённое оружие; элита — усиленный шлем/череп без жестокости; магазин — мешок или
лавка; отдых — костёр; событие — запечатанный свиток; босс — корона/рогатая башня. Не менять метафору
уже существующих `art/map/nodes/*.png` без изменения UI и тестов.

## 8. HUD, ресурсы и функциональные пиктограммы

### Мастер-промт HUD-иконки

```text
Single resource emblem for a fantasy strategy game, centered on transparent background, bold rounded
silhouette, hand-painted 2D with crisp edges, dark navy shadow, warm gold rim, controlled saturated
material color, minimal internal detail, no particles beyond the silhouette, readable at 24 pixels,
square icon, no text, no frame, no photorealism.
```

- Кирпичи: компактная кладка из 2–3 терракотовых блоков.
- Гемы: один синий огранённый кристалл.
- Звери: зелёная лапа или коготь, не голова случайного животного.
- Отдых/прокачка: предметная иконка как `magic_source.png` и `tower_foundation.png`, но с ещё более
  простым силуэтом для малых размеров.

## 9. Рамки, печати и UI-текстуры

UI-материалы должны выглядеть физическими: старый пергамент, воск, потёртая бронза, тёмный камень.
Генерировать их без текста и без запечённых теней от несуществующих элементов.

```text
Isolated medieval fantasy UI material asset, hand-painted 2D, aged parchment / carved dark stone /
antique bronze / sealing wax as specified, tactile wear and subtle asymmetry, clean silhouette,
orthographic front view, transparent background where applicable, evenly lit, no text, no symbols
unless explicitly requested, no mockup, no surrounding interface, suitable for nine-slice scaling.
```

Пергаментная рамка карты уже определена `parchment_bg.png`; печати редкости — `seal_common.png`,
`seal_uncommon.png`, `seal_rare.png`. Цвет ресурса накладывает движок, поэтому новые печати должны быть
нейтральными по базовой окраске.

## 10. Брендинг, иконка приложения и загрузочный экран

### Иконка приложения

```text
Iconic magical tower duel emblem, two opposing stylized tower silhouettes framing one luminous violet
arcane spark, antique gold edges on a near-black indigo background, premium hand-painted 2D fantasy
game icon, bold symmetrical composition, very large simple shapes, readable at 32 pixels, no words,
no tiny details, no border outside the safe circle, square 1:1.
```

### Загрузочный экран

```text
Cinematic 16:9 night panorama of two distant wizard towers facing each other across an ancient magical
battlefield, deep indigo sky, violet arcane currents and warm gold windows, painterly 2D fantasy game
art, strong central negative space reserved for the game logo added later by UI, dark calm lower area
for loading indication, no text rendered into the image, no characters in close-up.
```

Иконка должна переживать уменьшение до 144, 180 и 32 px. Splash — 1280×720 или больше в 16:9; текст
и индикатор загрузки всегда добавляются отдельно.

## 11. Контроль качества и приёмка

Перед добавлением изображения в репозиторий проверить:

- выбран правильный мастер-промт и указан канонический референс;
- изображение соответствует функции ресурса/экрана;
- нет текста, водяных знаков, рамок и случайных UI-элементов;
- силуэт читается при целевом размере;
- важные детали не обрезаются режимом Godot (`contain`, `cover`, `keep aspect`);
- палитра согласована с соответствующей ветвью стиля;
- прозрачный фон действительно содержит alpha, а не белую/чёрную подложку;
- файл назван `snake_case`, лежит в правильной папке и подключён к ресурсу или сцене;
- исходник и отклонённые варианты не попали в игровую папку;
- результат проверен на реальном экране игры, а не только отдельно.

При любой будущей генерации в запросе к генератору нужно явно писать: «Следовать
`docs/art_prompts.md`, раздел N; визуальные референсы: ...». Если новая категория арта не покрыта этим
гайдом, сначала дополнить файл и только потом генерировать ассеты.
