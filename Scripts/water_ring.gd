extends Area3D

func _physics_process(_delta: float) -> void:
	
	for body in get_overlapping_bodies():
		
		if body is Slappy:
			body.ring_boost();
	return;
