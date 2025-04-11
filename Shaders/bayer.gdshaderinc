
const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 5.0));

float bayer_sample(vec2 t_screen_uv, vec2 t_viewport_size) {
	
	vec2 suv = t_screen_uv * t_viewport_size;
	return BAYER[int(mod(suv.x, 4.0))][int(mod(suv.y, 4.0))] / 16.0;
}