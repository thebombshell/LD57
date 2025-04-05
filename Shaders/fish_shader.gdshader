shader_type spatial;

uniform float WIGGLE_SPEED = 3.0;
uniform float WIGGLE_INTENSITY = 1.0;
uniform float WIGGLE_LENGTH = 1.0;

void vertex() {
	
	float body = (VERTEX.z + 1.0) / WIGGLE_LENGTH;
	float time = TIME * WIGGLE_SPEED;
	float wave = WIGGLE_LENGTH;
	VERTEX.x += cos(time + body) * wave;
	float twist_angle = cos(time + body) * 0.3 * WIGGLE_INTENSITY;
	mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));
	VERTEX.xy = twist_matrix * VERTEX.xy;
}

void fragment() {
	
	ALBEDO = COLOR.xyz;
}