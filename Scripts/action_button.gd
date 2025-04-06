extends Button

static var s_is_wating = false;
var is_waiting = false;

@export var display_name : StringName = "LEFT";
@export var action_name : StringName = "move_left";

func _toggled(t_toggled_on : bool) -> void:
	
	if t_toggled_on && !s_is_wating:
		s_is_wating = true;
		is_waiting = true;
	if !t_toggled_on:
		s_is_wating = false;
		is_waiting = false;
	return;

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		var key_event : InputEventKey = event;
		var is_escape = key_event.keycode == KEY_ESCAPE;
		var is_enter = key_event.keycode == KEY_ENTER;
		if is_escape || is_enter:
			button_pressed = false;
			return;
	if is_waiting && event.is_pressed():
		
		InputMap.action_erase_event(action_name, InputMap.action_get_events(action_name)[0]);
		InputMap.action_add_event(action_name, event);
		text = "%s(%s)" % [display_name, event.as_text()];
		button_pressed = false;
		return;
	return;

func refresh():
	
	text = "%s(%s)" % [display_name, InputMap.action_get_events(action_name)[0].as_text()];
	return;

func _ready():
	
	refresh.call_deferred();
	return;

func _physics_process(_delta: float) -> void:
	
	if s_is_wating && !is_waiting:
		disabled = true;
	else:
		disabled = false;
	
	return;
