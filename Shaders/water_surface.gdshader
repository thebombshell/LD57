shader_type spatial;

render_mode unshaded, fog_disabled, blend_mix, depth_draw_never;

#include "water_helper.gdshaderinc"

const float CAMERA_FOV = PI * .5;
const vec3 CAMERA_UP_WORLD = vec3(0.0, 1.0, 0.0);

uniform sampler2D depth_texture : hint_depth_texture;

varying vec3 v_world_position;


void vertex() {
	
	VERTEX.y = sample_water(VERTEX.xz);
}

void fragment() {
	
	vec3 world_position = find_depth_world_position(SCREEN_UV, depth_texture, INV_VIEW_MATRIX, INV_PROJECTION_MATRIX);
	vec3 pixel_direction = normalize(world_position - CAMERA_POSITION_WORLD);
	vec3 pixel_position = find_camera_pixel_position(CAMERA_POSITION_WORLD, pixel_direction);
	float pixel_water_height = sample_water(pixel_position.xz);
	float is_surface_hit = 0.0;
	vec3 surface_position = march_to_water(pixel_position, pixel_direction, is_surface_hit);
	float is_pixel_below_water = step(pixel_position.y, pixel_water_height);
	
	float distance_to_ground_from_above = (distance(surface_position.xyz, world_position));
	float distance_to_ground_from_below = min(distance(pixel_position, world_position), distance(pixel_position, surface_position));
	float distance_to_ground = mix(
		distance_to_ground_from_above,
		distance_to_ground_from_below,
		is_pixel_below_water);
	float distance_to_water_surface = (distance(pixel_position, surface_position.xyz));
	float surface_line =
		step(world_position.y, surface_position.y) *
		smoothstep(surface_position.y - 1.0, surface_position.y, world_position.y);
	vec3 normal = find_normal(surface_position.xz);

	vec3 R = normalize(reflect(vec3(0.0, 1.0, 0.0), normal));
	vec3 V = normalize(pixel_direction);
	float fresnel = max(dot(normal, V) + 1.0, 0.0);
	float lamb = max(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0);
	float spec = pow(fresnel, 40.0);
	
	float can_see_surface = step(distance_to_water_surface, distance_to_ground);
	float water_alpha = clamp(distance_to_ground / shallow_depth, 0.5, 1.0);
	vec3 depth_color = mix(shallow_color, deep_color, smoothstep(0.0, deep_depth, min(distance_to_water_surface, distance_to_ground)));
	vec3 surface_color = lamb * depth_color + spec * shallow_color;
	float surface_alpha = clamp((water_alpha + spec) * (is_surface_hit * can_see_surface), 0.0, 1.0);
	float depth_alpha = water_alpha;
	ALBEDO = clamp(mix(surface_color, depth_color, is_pixel_below_water), 0.0, 1.0) + pow(surface_line, 2.0);
	ALPHA = clamp(mix(surface_alpha, depth_alpha, is_pixel_below_water), 0.0, 1.0) + surface_line;
}