class_name SafeDraw
extends RefCounted

static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, tag: String = "") -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		if OS.get_environment("YORU_DEBUG") != "":
			print("BAD POLY ", ci.get_script().resource_path, " ", tag, " ", pts)
		return
	ci.draw_colored_polygon(pts, col)
