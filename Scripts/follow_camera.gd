extends Camera3D

@onready var underwater_effect: MeshInstance3D = $UnderwaterEffect

var is_position_underwater : bool:
	get: return global_position.y < Water.current.height_at_point(global_position) + 4.0;

func _ready() -> void:
	
	if Water.current == null:
		return;
	
	var mat : ShaderMaterial = underwater_effect.mesh.surface_get_material(0);
	mat.set_shader_parameter("water_map_scale", Water.current.height_map_scale);
	mat.set_shader_parameter("water_map_height", Water.current.height_map_height);
	
	return;

func _phycis_process(t_delta: float) -> void:
	
	if Water.current == null:
		return;
	
	var filter : AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Master"), 0);
	filter.cutoff_hz = lerp(filter.cutoff_hz, 2000.0 if global_position.y < 0.0 else 20500.0, 4.0 * t_delta);
	
	return;
