class_name ResponsiveLayout
extends RefCounted

## Двухпанельные экраны (event/rest) переключаются по соотношению сторон.
const WIDE_ASPECT_THRESHOLD := 1.35

## Однопанельные экраны с сеткой/боковой панелью переключаются по ширине.
const NARROW_WIDTH_THRESHOLD := 760.0
const SHOP_NARROW_WIDTH_THRESHOLD := 800.0


static func is_wide_by_aspect(
	viewport_size: Vector2, min_aspect: float = WIDE_ASPECT_THRESHOLD
) -> bool:
	if viewport_size.y <= 0:
		return false
	return viewport_size.x / viewport_size.y >= min_aspect


static func is_narrow_by_width(
	viewport_size: Vector2, threshold: float = NARROW_WIDTH_THRESHOLD
) -> bool:
	return viewport_size.x < threshold
