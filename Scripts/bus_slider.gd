extends HSlider

@export var bus : StringName = "Master";

func _ready():
	
	value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus));
	return;

func _value_changed(t_new_value: float) -> void:
	
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), t_new_value);
	return;
