shader_type spatial;

render_mode unshaded;

#include "bayer.gdshaderinc"

uniform sampler2D wave_texture : repeat_disable;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float alpha_range : hint_range(0.01, 0.5) = 0.1;
uniform vec3 color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	float x = texture(wave_texture, UV).r;
	float bayer = bayer_sample(SCREEN_UV, VIEWPORT_SIZE) * alpha_range;
	if (x + bayer < alpha_cutoff)
		discard;
	ALBEDO = color;
}