shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;

uniform vec3 shallow_color : source_color;
uniform vec3 deep_color : source_color;
uniform float shallow_depth = 200.0;
uniform float deep_depth = 500.0;

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	vec3 ndc = vec3(SCREEN_UV, texture(depth_texture, SCREEN_UV).x) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	float dist = log2(length(CAMERA_POSITION_WORLD - world_position));

	ALBEDO *= mix(shallow_color, deep_color, smoothstep(shallow_depth, deep_depth, dist));
	ALPHA = max(0.35, dist / shallow_depth);
}