extends RefCounted

static var LEVELS: Array = [
	{
		"name": "1 — Easy slope",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250), Vector2(300, 280), Vector2(500, 320),
			Vector2(700, 380), Vector2(900, 450), Vector2(1100, 540), Vector2(1180, 560),
		]),
		"no_draw_zones": [],
	},
	{
		"name": "2 — Around the wall",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250), Vector2(300, 280), Vector2(450, 200),
			Vector2(700, 200), Vector2(850, 460), Vector2(1100, 540), Vector2(1180, 560),
		]),
		"no_draw_zones": [
			Rect2(500, 300, 250, 280),
		],
	},
	{
		"name": "3 — Squeeze",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250), Vector2(280, 320), Vector2(460, 360),
			Vector2(640, 380), Vector2(820, 420), Vector2(1000, 480),
			Vector2(1100, 530), Vector2(1180, 560),
		]),
		"no_draw_zones": [
			Rect2(700, 350, 180, 350),
			Rect2(380, 100, 200, 320),
		],
	},
	{
		"name": "4 — Pinned posts",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250),
			Vector2(330, 280),
			Vector2(500, 200),
			Vector2(700, 380),
			Vector2(900, 280),
			Vector2(1050, 480),
			Vector2(1180, 560),
		]),
		"locked_indices": [0, 2, 4, 6],
		"no_draw_zones": [],
	},
	{
		"name": "5 — Gentle waves",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250),
			Vector2(280, 200),
			Vector2(460, 320),
			Vector2(640, 200),
			Vector2(820, 320),
			Vector2(1000, 200),
			Vector2(1180, 560),
		]),
		"locked_indices": [0, 3, 6],
		"no_draw_zones": [
			Rect2(360, 380, 160, 320),
			Rect2(720, 380, 160, 320),
		],
	},
	{
		"name": "6 — Boulder dodge",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250),
			Vector2(300, 300),
			Vector2(500, 320),
			Vector2(700, 380),
			Vector2(900, 460),
			Vector2(1100, 540),
			Vector2(1180, 560),
		]),
		"locked_indices": [0, 6],
		"no_draw_zones": [],
		"boulders": [
			Rect2(620, 300, 100, 100),
			Rect2(900, 380, 100, 100),
		],
	},
	{
		"name": "7 — Three concepts",
		"start": Vector2(130, 100),
		"goal": Vector2(1180, 540),
		"default_track": PackedVector2Array([
			Vector2(100, 250),
			Vector2(280, 220),
			Vector2(460, 300),
			Vector2(640, 240),
			Vector2(820, 320),
			Vector2(1000, 260),
			Vector2(1180, 560),
		]),
		"locked_indices": [0, 3, 6],
		"no_draw_zones": [
			Rect2(180, 360, 160, 340),
			Rect2(840, 100, 140, 200),
			Rect2(500, 345, 580, 355),
		],
		"boulders": [
			Rect2(500, 215, 90, 90),
			Rect2(740, 245, 90, 90),
			Rect2(990, 255, 90, 90),
		],
	},
	{
		"name": "8 — A bouncy object",
		"start": Vector2(160, 60),
		"goal": Vector2(1230, 430),
		"default_track": PackedVector2Array([
			Vector2(80, 600),
			Vector2(320, 660),
			Vector2(1200, 660),
		]),
		"locked_indices": [0, 1, 2],
		"no_draw_zones": [],
		"boulders": [
			Rect2(420, 540, 90, 90),
			Rect2(820, 540, 90, 90),
		],
		"springs": [
			Vector2(280, 640),
			Vector2(660, 640),
			Vector2(1080, 640),
		],
	},
]
