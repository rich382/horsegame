extends Node
## Cross-system signals. No game state lives here.

signal horse_selected(uid: String)
signal phase_action_done(uid: String, action: StringName)
signal show_trip_finished(result: Variant)
signal cash_changed(new_cash: int, entry: Variant)
signal toast(text: String)
signal phase_ended(phase)
signal phase_started(phase)
signal day_started(cal)
signal season_started(season)
signal clock_changed
