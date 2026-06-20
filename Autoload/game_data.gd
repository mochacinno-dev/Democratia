extends Node

var player_first_name : String = ""
var player_last_name  : String = ""
var player_party      : String = ""

var current_year      : int   = 2025
var current_month     : int   = 1
var approval_rating   : float = 50.0

var seats : Dictionary = {
	"Green Alliance Party":  randi_range(45, 70),
	"Centre Compass Party":  randi_range(45, 70),
	"Fair Nationalism Party": randi_range(45, 70),
	"Rose Democracy Party":   randi_range(45, 70),
	"Liberal Society Party":  randi_range(45, 70),
}

const TOTAL_SEATS : int = 300

func player_full_name() -> String:
	return player_first_name + " " + player_last_name

func player_seat_count() -> int:
	return seats.get(player_party, 0)

func majority_threshold() -> int:
	return int(float(TOTAL_SEATS) / 2.0) + 1

func has_majority() -> bool:
	return player_seat_count() >= majority_threshold()

func advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1

func month_name() -> String:
	var names = ["January","February","March","April","May","June",
				 "July","August","September","October","November","December"]
	return names[current_month - 1]