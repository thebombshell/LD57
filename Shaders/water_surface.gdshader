shader_type spatial;

render_mode skip_vertex_transform, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;

uniform vec3 color : source_color;
uniform float noise_scaling = 128.0;
uniform sampler2D noise;

varying vec3 v_world_position;

void vertex() {
	v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

vec3 sample_at_offset(vec2 t_uv, float t_offset) {
	
	float l = texture(noise, t_uv - vec2(t_offset, 0.0)).x;
	float r = texture(noise, t_uv + vec2(t_offset, 0.0)).x;
	float t = texture(noise, t_uv - vec2(0.0, t_offset)).x;
	float b = texture(noise, t_uv + vec2(0.0, t_offset)).x;
	return normalize(vec3(0.0, 0.01, 0.0) + vec3(r - l, 0.0, 0.0) + vec3(0.0, 0.0, t - b));
}

vec3 find_normal(vec3 t_pos) {
	
	vec2 uv = vec2(t_pos.x, t_pos.z) + vec2(TIME * 0.01, TIME * 0.011);
	return mix(sample_at_offset(uv, 0.01), sample_at_offset(uv, 0.05), 0.5);
}

void fragment() {
	
	vec3 ndc = vec3(SCREEN_UV, texture(depth_texture, SCREEN_UV).x) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	float dist = length(v_world_position - world_position);
	vec3 scaled_world = v_world_position * noise_scaling;
	vec3 normal = find_normal(v_world_position * noise_scaling);
	
	vec3 R = reflect(vec3(0.0, 1.0, 0.0), normal);
	vec3 V = v_world_position - CAMERA_POSITION_WORLD;
	float lamb = max(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0);
	float spec = pow(max(dot(R, V), 0.0), 3.0);
	
	ALBEDO *= color + lamb + spec;
	ALPHA = max(0.5, dist / 250.0) + spec;
}