shader_type canvas_item;
uniform vec2 test[144];
void fragment() {
	COLOR.a = 1.0-test[int(UV.x*144.0*8.0)][int(UV.y*81.0*8.0)]/255.0;
}
