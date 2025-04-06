shader_type spatial;

uniform float WIGGLE_SPEED = 1.0;
uniform float WIGGLE_INTENSITY = 1.0;
uniform float WIGGLE_LENGTH = 5.0;

uniform vec3 base_color : source_color;
uniform vec3 head_color : source_color;

varying float height;

void vertex() {
	
	height  = VERTEX.y * 0.5;
	
	float body = (VERTEX.y) / WIGGLE_LENGTH;
	float time = TIME * WIGGLE_SPEED;
	VERTEX.x += body * cos(time + body);
	float twist_angle = body * cos(time + body) * WIGGLE_INTENSITY;
	mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));
	VERTEX.xz = twist_matrix * VERTEX.xz;
}

void fragment() {
	
	ALBEDO = mix(base_color, head_color, height);
}