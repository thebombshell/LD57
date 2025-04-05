extends Camera3D

@onready var underwater_effect: MeshInstance3D = $UnderwaterEffect

func _process(_delta: float) -> void:
	
	underwater_effect.visible = global_position.y < 0.0;
	
	return;
