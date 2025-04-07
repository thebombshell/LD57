extends Button

const GAME_SCENE_PATH = "res://Scenes/Maps/game.tscn";
@export var is_main_menu = false;

func _pressed() -> void:
	
	if is_main_menu:
		get_tree().change_scene_to_file(GAME_SCENE_PATH);
	else:
		get_tree().paused = false;
		$"../../..".visible = false;
		Slappy.current.reset_game();
	return;
