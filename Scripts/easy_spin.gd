extends Node3D

@export var speed = 0.1;
var my_rot = 0.0;

func _physics_process(t_delta: float) -> void:
	
	my_rot += t_delta * speed;
	basis = Basis(Vector3.UP, my_rot);
	
	return;
