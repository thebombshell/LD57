extends Label

var fade_timer = 0.0;
var wiggle_timer = 0.0;
var scale_timer = 0.0;

func fade(t_time : float = 3.0):
	
	fade_timer = t_time;

func wiggle(t_time : float = 1.0):
	
	wiggle_timer = t_time;

func scaler(t_time : float = 1.0):
	
	scale_timer = t_time;

func _physics_process(t_delta: float) -> void:
	
	if fade_timer > 0.0:
		
		fade_timer -= t_delta;
		modulate.a = clamp(fade_timer, 0.0, 1.0);
	
	if wiggle_timer > 0.0:
		
		wiggle_timer -= t_delta;
		rotation = sin(wiggle_timer * 20.0) * PI * 0.15 * clamp(wiggle_timer, 0.0, 1.0);
	
	if scale_timer > 0.0:
		
		scale_timer -= t_delta;
		var f = clamp(scale_timer * 0.5, 0.0, 0.5);
		scale = Vector2(1.0, 1.0) + Vector2(f, f);
	
	return;
