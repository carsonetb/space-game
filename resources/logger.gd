class_name CustomLogger
extends Object

const colors: Array[Color] = [Color("#D8DDEF"), Color("#A0A4B8"), Color("#7293A0"), Color("#45B69C"), Color("#21D19F")]
const error := Color("#b30000ff")
const warning := Color("#fffb25ff")

static func log(text: Variant, trace=false, custom_color: Color = Color(0, 0, 0)) -> void:
	var last_function: Dictionary = get_stack()[1]
	if "logger.gd" in last_function["source"]:
		last_function = get_stack()[2]
	var source_hash = hash(last_function["source"])
	var rng := RandomNumberGenerator.new()
	rng.seed = source_hash
	var color := colors[rng.randi_range(0, colors.size() - 1)]
	print_rich(
		"[color=#%s][%s] [%s:%d] %s %s[/color]" % 
		[
			color.to_html() if custom_color.r == 0 else custom_color.to_html(), 
			Time.get_datetime_string_from_system(), 
			last_function["source"], 
			last_function["line"], 
			text,
			"| Stack trace below:" if trace else ""
		]
	)
	if trace:
		print_stack()

static func info(text: String) -> void:
	CustomLogger.log(text)

static func err(text: String) -> void:
	CustomLogger.log("[ERROR] %s" % text, false, error)

static func trace(text: String) -> void:
	CustomLogger.log("[ERROR] %s" % text, true, error)

static func warn(text: String) -> void:
	CustomLogger.log("[WARNING] %s" % text, false, warning)