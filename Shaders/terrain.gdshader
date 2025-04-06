shader_type spatial;

uniform vec3 peak_color : source_color;
uniform vec3 dip_color : source_color;
uniform sampler2D height_map : repeat_disable;
uniform float height_map_scale = 500.0;
uniform float height_map_depth = 50.0;

varying float height;

void vertex() {
	
	float x = texture(height_map, (vec2(VERTEX.x, VERTEX.z) / height_map_scale) + 0.5).r;
	VERTEX.y = x * height_map_depth;
	height = x;
}

void fragment() {
	
	ALBEDO = mix(dip_color, peak_color, height);
}