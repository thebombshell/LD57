extends Camera3D

@onready var underwater_effect: MeshInstance3D = $UnderwaterEffect

func _process(t_delta: float) -> void:
	
	underwater_effect.visible = global_position.y < 0.0;
	var filter : AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Master"), 0);
	filter.cutoff_hz = lerp(filter.cutoff_hz, 2000.0 if global_position.y < 0.0 else 20500.0, 4.0 * t_delta);
	
	return;
