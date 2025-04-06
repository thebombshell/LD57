extends Control

@onready var retry_button: Button = $Panel/VBoxContainer/Button

func unpause():
	
	visible = false;
	get_tree().paused = false;
	return;

func pause():
	
	visible = true;
	get_tree().paused = true;
	retry_button.grab_focus();
	return;

func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("pause") && Slappy.current.timer > 0.0:
		if visible:
			unpause();
		else:
			pause();
	if Slappy.current.timer <= 0.0 && !visible:
		Slappy.current.game_end();
		pause();
	return;
