shader_type spatial;
render_mode alpha_to_coverage;
instance uniform float alpha = 1.0;
instance uniform vec2 offset = vec2(0, 0);
uniform sampler2D noise: repeat_enable;
uniform sampler2D tex: repeat_enable;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float n = texture(noise, UV + offset).r;
	ALBEDO = texture(tex, UV).rgb;
	if (step(n, alpha) == 0.0) discard;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
