extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer;

@export var camera : Camera3D = null;

var is_diving = false;

var input_prev = {
	"move": Vector2.ZERO,
	"look": Vector2.ZERO,
	"jump": false,
	"dive": false
};
var input_curr = {
	"move": Vector2.ZERO,
	"look": Vector2.ZERO,
	"jump": false,
	"dive": false
};
var forward : Vector3 = Vector3(0.0, 0.0, 1.0);
var acceleration : float = 60.0;
var jump_power : float = 10.0;
var jump_speed_boost : float = 1.0;
var air_drag : float = 0.05;
var ground_drag : float = 0.1;
var no_input_timer = 0.0;

func handle_forces(t_delta : float):
	
	if !is_on_floor():
		velocity += get_gravity() * t_delta;
	var speed = velocity.length();
	if speed > 0.0:
		var drag = speed * speed * (ground_drag if is_on_floor() else air_drag);
		velocity -= velocity.normalized() * drag * t_delta;
	
	return;

func control_diving(t_delta : float) -> void:
	
	return;

func control_running(t_delta : float) -> void:
	
	if camera == null:
		return;
	
	if input_curr.move.length() > 0.1:
		
		no_input_timer = 0.0;
		var modified_input = camera.transform.basis * Vector3(input_curr.move.x, 0.0, -input_curr.move.y);
		modified_input.y = 0.0;
		var dir = modified_input.normalized();
		forward = dir;
		
		velocity += modified_input * acceleration * t_delta * (1.0 if is_on_floor() else 0.5);
		if is_on_floor():
			animation_player.play("run");
	else:
		no_input_timer += t_delta;
		
		if is_on_floor():
			animation_player.play("idle");
	
	if is_on_floor() && Input.is_action_just_pressed("jump"):
		
		var boost = velocity.length();
		velocity.y = jump_power + boost * jump_speed_boost;
		animation_player.play("jump");
	
	global_basis = global_basis.slerp(Basis(Vector3.UP.cross(forward), Vector3.UP, forward), 8.0 * t_delta);
	return;

func _physics_process(t_delta: float) -> void:
	
	for property in input_curr:
		input_prev[property] = input_curr[property];
	input_curr.move = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_back", "move_fore"));
	input_curr.jump = Input.is_action_pressed("jump");
	input_curr.dive = Input.is_action_pressed("dive");
	
	handle_forces(t_delta);
	if is_diving:
		control_diving(t_delta);
	else:
		control_running(t_delta);
	
	move_and_slide();
	return;


func process_camera(t_delta : float) -> void:
	
	# part 1
	
	var new_basis = Basis.looking_at((global_position + global_basis * Vector3(0.0, 1.0, 10.0)) - camera.global_position);
	if no_input_timer > 3.0:
		camera.global_basis = camera.global_basis.slerp(new_basis, t_delta * 4.0);
	else:
		camera.global_basis = camera.global_basis.slerp(new_basis, t_delta * 0.5);
	
	var dir = camera.global_basis * -Vector3.FORWARD;
	var dist = camera.global_position.distance_to(global_position);
	var target_pos = global_position + Vector3.UP + dir * 10.5;
	if dist < 2.0:
		camera.global_position = global_position + dir * 2.0;
	elif dist > 20.0:
		camera.global_position = global_position + dir * 20.0;
	else:
		camera.global_position = camera.global_position.lerp(target_pos, t_delta * 4.0);
	
	return;

func _process(t_delta: float) -> void:
	
	process_camera(t_delta);
	return;
