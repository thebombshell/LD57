extends Button

@onready var intro: VBoxContainer = $".."
@onready var settings: VBoxContainer = $"../../Settings"
@onready var play_button: Button = $"../../Settings/Button"

func _ready() -> void:
	
	grab_focus.call_deferred();
	return;

func _pressed() -> void:
	
	intro.visible = false;
	settings.visible = true;
	play_button.grab_focus.call_deferred();
	return;
