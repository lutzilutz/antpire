extends Node2D

var pos_x
var pos_y
var intensity
var time_deposited: int = -1

func initialize(tmp_x, tmp_y, tmp_intensity):
	#pos_x = tmp_x
	#pos_y = tmp_y
	#intensity = tmp_intensity
	time_deposited = Time.get_ticks_msec()
	#print("aijsbdijbasidjbasi")
	position.x = tmp_x * 8 + 4
	position.y = tmp_y * 8 + 4

func decay():
	intensity = max(0, intensity-1)
	modulate.a = intensity / 200.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
