extends Camera2D

var mouse_start_pos
var screen_start_position
var dragging = false
var mouse_on_gui = false

signal pheromon_displayed(value: bool)

func _ready():
	pheromon_displayed.connect(get_tree().get_root().get_node("World").set_pheromon_displayed)
	Engine.time_scale = $GUI/Speed.value

func _process(delta):
	pass

func _input(event):
	if event.is_action("click") and not mouse_on_gui:
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_position = position
			dragging = true
		else:
			dragging = false
	elif event.is_action("click") and mouse_on_gui:
		if not event.is_pressed():
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) / zoom + screen_start_position
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2(0.2,0.2)
				update_gui()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2(0.2,0.2)
				update_gui()

func update_gui():
	$GUI.scale = Vector2(1/zoom.x, 1/zoom.y)

func _on_speed_mouse_entered():
	mouse_on_gui = true

func _on_speed_mouse_exited():
	mouse_on_gui = false

func _on_pheromon_decay_mouse_entered():
	mouse_on_gui = true

func _on_pheromon_decay_mouse_exited():
	mouse_on_gui = false

func _on_pheromon_display_toggled(button_pressed):
	pheromon_displayed.emit(button_pressed)

func _on_speed_value_changed(value):
	Engine.time_scale = value

func _on_pause_toggled(button_pressed):
	#get_tree().paused = not button_pressed
	pass

func _on_pause_pressed():
	get_tree().paused = not get_tree().paused
