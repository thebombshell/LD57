class_name FishManager extends MultiMeshInstance3D

const SIZE_CHART = [
	0.1,
	0.2,
	0.33,
	0.5,
	1.0
];

var map : Dictionary[Vector2i, Array] = {};

var velocities : PackedVector3Array = [];
var positions : PackedVector3Array = [];
var sizes : PackedInt32Array = [];

@export var COUNT = 600;
@export var COLOR_CHART : Array[Color] = [
	Color.HOT_PINK,
	Color.DARK_SALMON,
	Color.ORANGE,
	Color.DARK_BLUE,
	Color.WEB_PURPLE
];

@export var base_score = 100;
@export var fish_name = "FLATTER";

@export var separation_range : float = 20.0;
@export var separation: float = 0.5;
@export var alignment : float = 1.0;
@export var cohesion : float = 1.0;

@export var top : float = -4.0;
@export var bot : float = -20.0;
@export var height_adherence : float = 3.0;
@export var top_speed : float = 20.0;

var impulse_timer = 0.0;
var caught = -1;

func impulse():
	
	impulse_timer = 10.0;
	
	return;

func space_hash(t_position : Vector3) -> Vector2i:
	return Vector2i(floori(t_position.x / 25.0), floori(t_position.z / 25.0));

func map_remove(t_index : int):
	
	var t_hash : Vector2i = space_hash(positions[t_index]);
	if map.has(t_hash):
		var i = map[t_hash].find(t_index);
		if i >= 0:
			map[t_hash].remove_at(i);
	return;

func map_push(t_index : int):
	
	var t_hash : Vector2i = space_hash(positions[t_index]);
	if !map.has(t_hash):
		map[t_hash] = [];
	map[t_hash].push_back(t_index);
	return;

func map_get_nearby(t_index : int) -> Array[int]:
	
	var output : Array[int] = [];
	
	var hash = space_hash(positions[t_index]);
	for x in range(hash.x - 1, hash.x + 1):
		for y in range(hash.y - 1, hash.y + 1):
			var key = Vector2i(x, y);
			if map.has(key):
				output.append_array(map[key]);
	return output;

func spawn(t_index):
	
	if t_index >= COUNT:
		push_error("index out of range");
	
	map_remove(t_index);
	
	if t_index == caught:
		caught = -1;
	
	positions[t_index] = Vector3(randf_range(-250.0, 250.0), randf_range(bot, top), randf_range(-250.0, 250.0));
	velocities[t_index] = Vector3(randf(), 0.0, randf()).normalized() * 20.0;
	sizes[t_index] = randi_range(0, 4);
	
	map_push(t_index);
	
	return;

func update(t_index : int, t_delta : float):
	
	if t_index >= COUNT:
		push_error("index out of range");
	
	if t_index == caught:
		
		var skele : Skeleton3D = Slappy.current.find_child("Skeleton3D");
		var tsfrm = skele.global_transform * skele.get_bone_global_pose(skele.find_bone("head"));
		positions[t_index] = tsfrm.origin + tsfrm.basis * Vector3.UP;
		velocities[t_index] = (tsfrm.basis * Vector3.RIGHT).normalized();
		return;
	
	var nearby = map_get_nearby(t_index);
	
	map_remove(t_index);
	
	var t_position = positions[t_index];
	var velocity = velocities[t_index];
	var size = SIZE_CHART[sizes[t_index]];
	
	var close = Vector3.ZERO;
	var align = Vector3.ZERO;
	var center = Vector3.ZERO;
	
	if t_position.y > top:
		
		var diff = t_position.y - top;
		velocity.y -= 10.0 * t_delta * diff * diff;
	elif t_position.y < bot:
		
		var diff = bot -  t_position.y;
		velocity.y += 10.0 * t_delta * diff * diff;
	else:
		if Slappy.current != null:
			
			var diff = t_position - Slappy.current.global_position;
			if diff.length() < 25.0 && Slappy.current.global_position.y < -5.0:
				close -= diff * 0.5;
			if diff.length() < 5.0 && Slappy.current.global_position.y < 0.0:
				if Slappy.current.try_catch(self, t_index):
					map_remove(t_index);
					caught = t_index;
					return;
		
		var s_range = separation_range * (5.0 if impulse_timer > 0.0 else 1.0);
		var s_power = separation * (5.0 if impulse_timer > 0.0 else 1.0);
		var x_count = min(4, len(nearby))
		for x in x_count:
			
			var i = nearby[randi_range(0, len(nearby) - 1)];
			if t_position.distance_to(positions[i]) < separation_range:
				close += t_position - positions[i];
			align += velocities[i];
			center += positions[i];
			
		if len(nearby) > 0:
			align /= x_count;
			center /= x_count;
		
		velocity += close * s_power * t_delta;
		velocity += Vector3(0.0, (-top + smoothstep(SIZE_CHART[0], SIZE_CHART[4], size) * (bot + top)) - t_position.y, 0.0) * height_adherence * t_delta;
		velocity += (center - t_position) * cohesion * t_delta;
		velocity = lerp(velocity, align, alignment * t_delta);
		if t_position.length() > 225.0:
			velocity -= t_position.normalized() * top_speed * t_delta;
	
	var speed = velocity.length();
	positions[t_index] += velocity * t_delta;
	velocities[t_index] = (velocity.normalized() * top_speed) if speed > top_speed else velocity;
	
	map_push(t_index);
	
	return;

func _ready() -> void:
	
	visible = true;
	multimesh.use_colors = true;
	multimesh.instance_count = COUNT;
	positions.resize(COUNT);
	velocities.resize(COUNT);
	sizes.resize(COUNT)
	for i in COUNT:
		spawn(i);
	return;

func _physics_process(t_delta: float) -> void:
	
	if impulse_timer > 0.0:
		impulse_timer -= t_delta;
	
	for i in COUNT:
		update(i, t_delta);
	
	for i in COUNT:
		var z = velocities[i].normalized();
		var y = Vector3.UP;
		var x = y.cross(z).normalized();
		var s = SIZE_CHART[sizes[i]];
		multimesh.set_instance_transform(i, Transform3D(Basis(x, y, z).scaled(Vector3(s, s, s)), positions[i]));
		multimesh.set_instance_color(i, COLOR_CHART[sizes[i]]);
	return;
