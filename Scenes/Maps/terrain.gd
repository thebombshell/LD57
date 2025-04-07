extends MeshInstance3D

const SEAWEED = preload("res://Scenes/Objects/seaweed.tscn");
const REDWEED = preload("res://Scenes/Objects/redweed.tscn");
const RADIAL_NOISE = preload("res://Textures/radial_noise.png");

const CLUTTER = [
	preload("res://Scenes/Objects/rock_a.tscn"),
	preload("res://Scenes/Objects/rock_b.tscn"),
	preload("res://Scenes/Objects/coral_1.tscn"),
	preload("res://Scenes/Objects/coral_2.tscn"),
	preload("res://Scenes/Objects/coral_3.tscn"),
	preload("res://Scenes/Objects/coral_4.tscn")
];

#@onready var seaweed: MultiMeshInstance3D = $Seaweed;

var radial_noise : Image = null;
var height_map_scale : float = 0.0;
var height_map_depth : float = 0.0;

func _ready() -> void:
	
	radial_noise = RADIAL_NOISE.get_image();
	var mat : ShaderMaterial = mesh.surface_get_material(0);
	height_map_scale = mat.get_shader_parameter("height_map_scale");
	height_map_depth = mat.get_shader_parameter("height_map_depth");
	generate_seaweed();
	return;

func generate_seaweed(t_count : int = 256):
	
	for i in t_count:
		var dist = sqrt(float(i) / float(t_count)) * 350.0;
		var angle = randf() * PI * 2.0;
		var t_rotation = randf() * PI * 2.0;
		var uv = Vector2(cos(angle), sin(angle)) * dist;
		
		var basis = Basis(Vector3.UP, t_rotation) * randf_range(2.0, 6.0);
		var position = Vector3(uv.x, sample_at_point(uv) * height_map_depth, uv.y);
		var node = SEAWEED.instantiate();
		add_child(node);
		node.basis = basis;
		node.position = position;
		
	for i in t_count:
		var dist = 1.0 + sqrt(float(i) / float(t_count)) * 350.0;
		var angle = randf() * PI * 2.0;
		var t_rotation = randf() * PI * 2.0;
		var uv = Vector2(cos(angle), sin(angle)) * dist;
		
		var basis = Basis(Vector3.UP, t_rotation) * randf_range(1.5, 4.0);
		var position = Vector3(uv.x, sample_at_point(uv) * height_map_depth, uv.y);
		var node = REDWEED.instantiate();
		add_child(node);
		node.basis = basis;
		node.position = position;
		
	for i in t_count * 2:
		var dist = 1.0 + sqrt(float(i) / float(t_count)) * 350.0;
		var angle = randf() * PI * 2.0;
		var t_rotation = randf() * PI * 2.0;
		var uv = Vector2(cos(angle), sin(angle)) * dist;
		
		var basis = Basis(Vector3.UP, t_rotation) * randf_range(0.5, 2.0);
		var position = Vector3(uv.x, sample_at_point(uv) * height_map_depth, uv.y);
		var node = CLUTTER.pick_random().instantiate();
		add_child(node);
		node.basis = basis;
		node.position = position;
	return;

func sample_at_point(t_position : Vector2) -> float:
	
	var uv = (Vector2(t_position.x, t_position.y) / height_map_scale) + Vector2(0.5, 0.5);
	var size = radial_noise.get_size();
	var suv = uv * Vector2(size);
	var iuv = Vector2i(floori(suv.x), floori(suv.y));
	var muv = Vector2(suv.x - iuv.x, suv.y - iuv.y);
	
	var tl = radial_noise.get_pixel(
		clamp(iuv.x + 0, 0, size.x - 1), clamp(iuv.y + 0, 0, size.y - 1)).r;
	var t_tr = radial_noise.get_pixel(
		clamp(iuv.x + 1, 0, size.x - 1), clamp(iuv.y + 0, 0, size.y - 1)).r;
	var bl = radial_noise.get_pixel(
		clamp(iuv.x + 0, 0, size.x - 1), clamp(iuv.y + 1, 0, size.y - 1)).r;
	var br = radial_noise.get_pixel(
		clamp(iuv.x + 1, 0, size.x - 1), clamp(iuv.y + 1, 0, size.y - 1)).r;
	
	var t = lerp(tl, t_tr, muv.x);
	var b = lerp(bl, br, muv.x);
	
	return lerp(t, b, muv.y);
