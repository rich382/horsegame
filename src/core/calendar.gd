class_name Calendar
extends Resource

const Enums := preload("res://src/core/enums.gd")

@export var year: int = 1
@export var season: int = Enums.Season.SPRING
@export var week: int = 1 ## 1..4
@export var weekday: int = Enums.Weekday.MON
@export var phase: int = Enums.Phase.MORNING


func abs_day() -> int:
	return (year - 1) * 112 + int(season) * 28 + (week - 1) * 7 + int(weekday)


func to_dict() -> Dictionary:
	return {
		"year": year,
		"season": int(season),
		"week": week,
		"weekday": int(weekday),
		"phase": int(phase),
	}


static func from_dict(d: Dictionary) -> Calendar:
	var c := Calendar.new()
	c.year = int(d.get("year", 1))
	c.season = int(d.get("season", 0))
	c.week = int(d.get("week", 1))
	c.weekday = int(d.get("weekday", 0))
	c.phase = int(d.get("phase", 0))
	return c


## Returns true if a season (or year) boundary was crossed.
func advance_to_next_morning() -> bool:
	phase = Enums.Phase.MORNING
	var s: int = int(weekday) + 1
	if s <= int(Enums.Weekday.SUN):
		weekday = s
		return false
	weekday = Enums.Weekday.MON
	week += 1
	if week <= 4:
		return false
	week = 1
	var next_season: int = int(season) + 1
	if next_season > int(Enums.Season.WINTER):
		season = Enums.Season.SPRING
		year += 1
	else:
		season = next_season
	return true


func phase_label() -> String:
	match phase:
		Enums.Phase.MORNING:
			return "Morning"
		Enums.Phase.AFTERNOON:
			return "Afternoon"
		Enums.Phase.EVENING:
			return "Evening"
		_:
			return "?"


func weekday_label() -> String:
	const NAMES: PackedStringArray = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	return NAMES[int(weekday)]


func season_label() -> String:
	const NAMES: PackedStringArray = ["Spring", "Summer", "Fall", "Winter"]
	return NAMES[int(season)]


func hud_text() -> String:
	return "Year %d  %s  Week %d  %s  %s" % [year, season_label(), week, weekday_label(), phase_label()]
