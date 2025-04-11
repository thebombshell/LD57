shader_type spatial;

#include "bayer.gdshaderinc"

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
	
	float bayer = bayer_sample(SCREEN_UV, VIEWPORT_SIZE) * 32.0;
	
	if (x > bayer || sin(v_world_position.y + atan(v_world_position.x, v_world_position.z) * 100.0) < 0.0)
		discard;
	
	ALBEDO = vec3(1.0, 0.5, 0.0);
}
