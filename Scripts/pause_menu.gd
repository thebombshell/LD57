extends Control

func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("pause") && Slappy.current.timer > 0.0:
		if visible:
			visible = false;
			get_tree().paused = false;
		else:
			visible = true;
			get_tree().paused = true;
	if Slappy.current.timer <= 0.0 && !visible:
		Slappy.current.game_end();
		visible = true;
		get_tree().paused = true;
	return;
