shader_type spatial;

const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 5.0));

render_mode unshaded, skip_vertex_transform;

varying vec3 v_world_position;

void vertex() {
	
	v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

void fragment() {
	
	float x = distance(v_world_position, CAMERA_POSITION_WORLD) * 0.1;
	
	vec2 suv = (SCREEN_UV * vec2(948, 533));
	float bayer = BAYER[int(mod(suv.x, 4.0))][int(mod(suv.y, 4.0))];
	
	if (x > bayer || sin(v_world_position.y + v_world_position.x) < 0.0)
		discard;
	
	ALBEDO = vec3(1.0, 0.5, 0.0);
}
