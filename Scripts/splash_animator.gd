extends Node3D

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var gpu_particles_3d_2: GPUParticles3D = $GPUParticles3D2

func _ready() -> void:
	
	gpu_particles_3d.finished.connect(queue_free);
	gpu_particles_3d.restart();
	gpu_particles_3d_2.restart();
	return;
