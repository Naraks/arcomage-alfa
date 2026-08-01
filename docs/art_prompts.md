# Промпт-бриф для арта карт (для внешнего AI-инструмента/художника)

Дополняет `docs/art_style_guide.md` (ARC-091). Ранний вариант стиля был плоский векторный
"щит-медальон" — по фидбэку не подошёл ("совсем не то"), поэтому здесь другое направление:
**расписанный 2D-арт в духе Clash Royale / Hearthstone**, как и требует GDD §11.1, без щита/кольца
редкости внутри самой иллюстрации (рамку и индикатор редкости рисует движок поверх готового арта —
см. §3 ниже). Генерировать через Midjourney/ChatGPT Images/Leonardo/Stable Diffusion или отдавать
художнику как техзадание — промпт одинаково читается в обоих случаях.

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
