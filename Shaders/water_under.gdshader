shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;

uniform vec3 color : source_color;

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
	
	float dist = length(CAMERA_POSITION_WORLD - world_position);
	
	ALBEDO *= color;
	ALPHA = max(0.5, dist / 250.0);
}