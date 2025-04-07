class_name Slappy extends CharacterBody3D

const DIVE_RANDOMIZER = preload("res://Sounds/dive_randomizer.tres");
const STEP_RANDOMIZER = preload("res://Sounds/step_randomizer.tres");
const SPLASH_ANIMATOR = preload("res://Scenes/Objects/splash_animator.tscn");

const SCORE_SOUNDS = [preload("res://Sounds/score_1.wav"),
	preload("res://Sounds/score_2.wav"),
	preload("res://Sounds/score_3.wav"),
	preload("res://Sounds/score_4.wav"),
	preload("res://Sounds/score_5.wav")];

const MASK_PLAYER = 1;
const MASK_BIT = 2;
const MASK_WATER = 4;
const MASK_GROUND = 8;
const MASK_UNDERWATER = 16;

const MULTIPLIER_COLORS = [
	Color.LIGHT_GOLDENROD,
	Color.GOLD,
	Color.ORANGE,
	Color.LIGHT_CORAL,
	Color.MEDIUM_PURPLE,
	Color.WEB_PURPLE
];

static var current : Slappy = null;

@onready var animation_player: AnimationPlayer = $AnimationPlayer;
@onready var slappy_footsteps: AudioStreamPlayer3D = $SlappyFootsteps
@onready var slappy_sploosh: AudioStreamPlayer3D = $SlappySploosh
@onready var dive_sound: AudioStreamPlayer3D = $DiveSound
@onready var slappy_breach: AudioStreamPlayer3D = $SlappyBreach
@onready var bubbler: GPUParticles3D = $BubbleParticles
@onready var score_player: AudioStreamPlayer = $ScorePlayer
@onready var trick_player: AudioStreamPlayer = $TrickPlayer
@onready var water_trick_player: AudioStreamPlayer = $WaterTrickPlayer

@export var camera : Camera3D = null;
@export var depth_label : Label = null;
@export var score_label : Label = null;
@export var message_label : Label = null;
@export var timer_label : Label = null;
@export var time_bar : ProgressBar = null;
@export var multiplier_label : Label = null;
@export var timer_bonus : Label = null;
@export var music_player : AudioStreamPlayer = null;
@export var game_end_label : Label = null;
@export var highscore_label : Label = null;

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

static var s_highscore : int = 0;

var is_diving = false;
var has_dived = false;
var is_underwater = false;
var is_tricking = false;

var max_depth = 0.0;
var forward : Vector3 = Vector3(0.0, 0.0, 1.0);
var acceleration : float = 60.0;
var jump_power : float = 10.0;
var jump_speed_boost : float = 1.0;
var air_drag : float = 0.05;
var ground_drag : float = 0.1;
var no_input_timer = 0.0;
var under_water_timer = 0.0;
var out_of_water_tiemr = 0.0;
var swim_boost_timer = 0.0;
var swim_boost_power = 3.0;

var catch_manager : FishManager = null;
var catch_index : int = -1;
var catch_size : int = -1;

var current_score : int = 0;

var max_time : float = 120.0;
var timer : float = 120.0;

var multiplier : int = 0;
var multiplier_timer : float = 0.0;

var music_alpha = 0.0;
var audio_fadein = 1.0;

func ring_boost():
	
	swim_boost_timer = 0.01;
	animation_player.play("swim_trick", 0.2);
	animation_player.queue("swim");
	if !water_trick_player.playing:
		water_trick_player.play();
	return;

func game_end():
	
	var stream : AudioStreamSynchronized = music_player.stream;
	stream.set_sync_stream_volume(0, -10.0);
	stream.set_sync_stream_volume(1, -60.0);
	stream.set_sync_stream_volume(2, -60.0);
	if current_score > s_highscore:
		
		game_end_label.text = "NEW HIGHSCORE!";
		s_highscore = current_score;
		highscore_label.text = "%06d" % s_highscore;
		highscore_label.wiggle();
		highscore_label.modulate = Color.GOLD;
	else:
		game_end_label.text = "GAME OVER!";
	
	return;

func try_catch(t_manager : FishManager, t_index : int) -> bool:
	
	var size = t_manager.sizes[t_index];
	if size > catch_size:
		if catch_manager != null && catch_index >= 0:
			catch_manager.spawn(catch_index);
			add_time(1.0);
		catch_manager = t_manager;
		catch_index = t_index;
		catch_size = size;
		return true;
	return false;

func score():
	
	if catch_manager == null || catch_index < 0 || catch_size < 0:
		return;
	
	const COLOR = [
		Color.WHITE,
		Color.LIGHT_YELLOW,
		Color.GREEN_YELLOW,
		Color.DARK_TURQUOISE,
		Color.WEB_PURPLE
	];
	
	add_time(5.0);
	set_multiplier(multiplier + 1);
	score_player.stream = SCORE_SOUNDS[catch_size];
	score_player.play();
	
	var message = "???";
	match catch_size:
		0: message = "OK " + catch_manager.fish_name + "!";
		1: message = "NICE " + catch_manager.fish_name + "!";
		2: message = "GREAT " + catch_manager.fish_name + "!";
		3: message = "AMAZING " + catch_manager.fish_name + "!";
		4: message = "TASTY " + catch_manager.fish_name + "!!!";
	var worth = floori(catch_manager.base_score * FishManager.SIZE_CHART[catch_size]);
	
	current_score += worth * multiplier;
	
	score_label.text = "SCORE:%06d" % current_score;
	score_label.wiggle();
	message_label.text = message;
	message_label.modulate = COLOR[catch_size];
	message_label.scaler();
	message_label.wiggle();
	message_label.fade();
	
	catch_manager.impulse();
	catch_manager.spawn(catch_index);
	catch_manager = null;
	catch_index = -1;
	catch_size = 0;
	
	return;

func handle_forces(t_delta : float):
	
	if !is_on_floor() && !is_underwater:
		velocity += get_gravity() * t_delta;
	var speed = velocity.length();
	if speed > 0.0:
		var drag = speed * speed * (ground_drag if is_on_floor() else air_drag);
		velocity -= velocity.normalized() * drag * t_delta;
	
	return;

func splash():
	
	var node = SPLASH_ANIMATOR.instantiate();
	get_parent().add_child(node);
	node.global_position = Vector3(global_position.x, 0.0, global_position.z);
	return;

func control_diving(t_delta : float) -> void:
	
	if camera == null:
		return;
	
	var is_inputting = false;
	var modified_input = Vector3.ZERO;
	
	if input_curr.move.length() > 0.1:
		
		no_input_timer = 0.0;
		is_inputting = true;
		modified_input = camera.transform.basis * Vector3(input_curr.move.x, 0.0, -input_curr.move.y);
		modified_input.y = 0.0;
	else:
		no_input_timer += t_delta;
	is_underwater = global_position.y < 0.0;
	
	if is_underwater:
		
		if !has_dived:
			splash();
			animation_player.play("swim", 0.5);
			slappy_sploosh.stream = DIVE_RANDOMIZER;
			slappy_sploosh.play();
			dive_sound.volume_db = lerp(-40.0, 0.0, clamp(smoothstep(-4.0, -20.0, velocity.y), 0.0, 1.0));
			dive_sound.play(0.33);
			has_dived = true;
			is_tricking = false;
			swim_boost_timer = 0.0;
		
		if swim_boost_timer <= 0.0:
			if Input.is_action_just_pressed("jump"):
				swim_boost_timer = t_delta;
				animation_player.play("swim_trick", 0.2);
				animation_player.queue("swim");
				dive_sound.volume_db = -5.0;
				dive_sound.play(0.4);
		else:
			swim_boost_timer += t_delta;
			var speed = velocity.length();
			velocity += Vector3(velocity.x, 0.0, velocity.y).normalized() * speed * swim_boost_power * t_delta * max(0.0, 1.0 - swim_boost_timer);
		
		var bubbler_alpha = clamp(1.0 - swim_boost_timer, 0.0, 1.0) if swim_boost_timer > 0.0 else 0.0;
		var bubbler_mat : ParticleProcessMaterial = bubbler.process_material;
		bubbler_mat.initial_velocity_min = lerp(0.0, 10.0, bubbler_alpha);
		bubbler_mat.initial_velocity_max = lerp(5.0, 15.0, bubbler_alpha);
		
		under_water_timer += t_delta;
		if is_inputting:
			velocity += modified_input * acceleration * t_delta * 0.5;
		if global_position.y < max_depth:
			max_depth = global_position.y;
		var dive_mod = min(1.0, 0.015 * under_water_timer) if input_curr.dive else 1.0;
		velocity += Vector3(0.0, 12.0, 0.0) * max(1.0, abs(max_depth) * dive_mod) * t_delta;
		
	elif has_dived:
		breach();
	else:
		velocity += get_gravity() * (8.0 if is_tricking else 4.0) * t_delta;
	
	var dir = velocity.normalized();
	global_basis = global_basis.slerp(Basis.looking_at(-dir), 8.0 * t_delta);
	return;

func control_running(t_delta : float) -> void:
	
	if camera == null:
		return;
	
	out_of_water_tiemr += t_delta;
	if out_of_water_tiemr > 1.5:
		score();
	
	var is_inputting = false;
	var modified_input = Vector3.ZERO;
	var input_direction = Vector3.FORWARD;
	
	if input_curr.move.length() > 0.1:
		
		no_input_timer = 0.0;
		is_inputting = true;
		modified_input = camera.transform.basis * Vector3(input_curr.move.x, 0.0, -input_curr.move.y);
		modified_input.y = 0.0;
		input_direction = modified_input.normalized();
	else:
		no_input_timer += t_delta;
	
	if is_on_floor():
		if is_inputting:
			velocity += modified_input * acceleration * t_delta * 1.0;
			animation_player.play("run");
			animation_player.speed_scale = Vector3(velocity.x, 0.0, velocity.z).length() / 10.0;
			forward = input_direction;
		else:
			animation_player.play("idle");
			
	else:
		if is_inputting:
			velocity += modified_input * acceleration * t_delta * 0.5;
			forward = forward.slerp(input_direction, t_delta * 2.0);
		animation_player.play("jump");
		animation_player.pause();
		animation_player.seek(smoothstep(10.0, -10.0, velocity.y), true);
	
	if is_on_floor() && Input.is_action_just_pressed("jump"):
		
		var boost = velocity.length();
		velocity.y = jump_power + boost * jump_speed_boost;
		slappy_footsteps.stream = STEP_RANDOMIZER;
		slappy_footsteps.play();
		slappy_footsteps.play(0.05);
	global_basis = global_basis.slerp(Basis(Vector3.UP.cross(forward), Vector3.UP, forward), 8.0 * t_delta);
	return;

func dive():
	
	score();
	max_depth = 0.0;
	under_water_timer = 0.0;
	is_diving = true;
	has_dived = false;
	if velocity.y > -2.0 && velocity.y < 2.0:
		
		velocity.y = 40.0;
		animation_player.play("jump_trick", 0.5);
		animation_player.queue("dive");
		trick_player.play();
		is_tricking = true;
	else:
		animation_player.play("dive", 0.5);
	collision_mask &= ~MASK_WATER;
	collision_mask |= MASK_UNDERWATER;
	return;

func breach():
	
	slappy_breach.play();
	out_of_water_tiemr = 0.0;
	is_diving = false;
	collision_mask |= MASK_WATER;
	collision_mask &= ~MASK_UNDERWATER;
	if velocity.y > 10.0:
		splash();
	return;

func _physics_process(t_delta: float) -> void:
	
	for property in input_curr:
		input_prev[property] = input_curr[property];
	input_curr.move = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_back", "move_fore"));
	input_curr.jump = Input.is_action_pressed("jump");
	input_curr.dive = Input.is_action_pressed("dive");
	
	if !is_underwater && Input.is_action_just_pressed("dive"):
		if is_on_floor():
			velocity.y = 10.0;
		dive();
	
	handle_forces(t_delta);
	if is_diving:
		control_diving(t_delta);
	else:
		control_running(t_delta);
	
	move_and_slide();
	return;

func set_multiplier(t_multiplier : int):
	
	if multiplier_label == null:
		return;
	
	multiplier = min(t_multiplier, 6);
	multiplier_timer = 15.0;
	if multiplier > 0:
		multiplier_label.modulate = MULTIPLIER_COLORS[multiplier - 1];
	multiplier_label.modulate.a = 0.0 if multiplier <= 0 else 1.0;
	multiplier_label.text = "%1d*" % multiplier;
	multiplier_label.wiggle();
	multiplier_label.scaler();
	return;

func add_time(t_time : float):
	
	if timer_label == null || timer_bonus == null:
		return;
	
	timer += t_time;
	timer_bonus.text = "+%1d" % roundi(t_time);
	timer_bonus.wiggle();
	timer_bonus.scaler();
	timer_bonus.fade();
	return;

func process_ui(t_delta : float) -> void:
	
	const format = "DEPTH:%03.2fM";
	if depth_label != null:
		depth_label.text = format % max_depth;
	
	if timer_label != null:
		var seconds = fmod(timer, 60.0);
		var minutes = (timer - seconds) / 60.0;
		timer_label.text = "%02d:%02d" % [floori(minutes), floori(seconds)];
		
		var col_a = lerp(Color.WHITE, Color.GOLD, clamp(smoothstep(60.0, 30.0, timer), 0.0, 1.0));
		var col_b = lerp(Color.GOLD, Color.RED, clamp(smoothstep(45.0, 15.0, timer), 0.0, 1.0));
		var col_c = lerp(col_a, col_b, clamp(smoothstep(120.0, 15.0, timer), 0.0, 1.0));
		timer_label.modulate = col_c;
	
	if time_bar != null:
		time_bar.max_value = max_time;
		time_bar.value = timer;
	
	if multiplier_label != null:
		
		if music_player != null:
			
			var stream : AudioStreamSynchronized = music_player.stream;
			var alpha = clamp(smoothstep(1, 6, multiplier), 0.0, 1.0);
			if audio_fadein > 0.0:
				audio_fadein -= t_delta;
			var off = -60.0 * max(0.0, audio_fadein);
			music_alpha = lerp(music_alpha, alpha, t_delta);
			stream.set_sync_stream_volume(0, off + -60.0 * pow(music_alpha, 2.0));
			stream.set_sync_stream_volume(1, off + -60.0 * pow(1.0 - music_alpha, 3.0));
			stream.set_sync_stream_volume(2, off + -60.0 * clamp(smoothstep(15.0, 45.0, timer), 0.0, 1.0));
			if !music_player.playing:
				music_player.play();
		
		multiplier_timer -= t_delta * (multiplier * 0.5);
		if multiplier_timer < 0.0:
			multiplier_timer = 15.0;
			set_multiplier(multiplier - 1);
	
	return;

func process_camera(t_delta : float) -> void:
	
	# part 1
	
	var look_target = (global_position + global_basis * Vector3(0.0, 1.0, 10.0));
	if global_position.y > 4.0:
		look_target = Vector3(global_position.x, 0.0, global_position.z);
	var new_basis = Basis.looking_at(look_target - camera.global_position);
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
	
	if (camera.global_position.y < 0.0 && global_position.y > 0.0) || global_position.y > 1.0:
		camera.global_position += Vector3.UP * 4.0 * t_delta;
	
	return;

func _ready():
	
	current = self;
	highscore_label.text = "%06d" % s_highscore;
	return;

func _process(t_delta: float) -> void:
	
	bubbler.emitting = is_underwater;
	
	timer -= t_delta;
	
	process_camera(t_delta);
	process_ui(t_delta);
	return;
