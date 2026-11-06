class_name Daily
extends RefCounted
## The daily run: one seed per UTC day, the same for everyone, so the board, every
## wave's formation and the order of reel outcomes match. Run #1 is launch day.

const EPOCH := "2026-11-06"
const SECONDS_PER_DAY := 86400


static func today_key() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()))


static func number_for(date_key: String) -> int:
	var day := Time.get_unix_time_from_datetime_string(date_key) / SECONDS_PER_DAY
	var epoch := Time.get_unix_time_from_datetime_string(EPOCH) / SECONDS_PER_DAY
	return int(day - epoch) + 1


static func today_number() -> int:
	return number_for(today_key())


## Seconds until the next UTC midnight, for the "next run in" countdown.
static func seconds_until_next() -> int:
	var now := int(Time.get_unix_time_from_system())
	return SECONDS_PER_DAY - now % SECONDS_PER_DAY


static func seed_for(number: int) -> int:
	return Sim.mix(number, 0xDA1)


static func create(number: int) -> Sim:
	return Sim.create(seed_for(number))
