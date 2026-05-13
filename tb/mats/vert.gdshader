shader_type spatial;

render_mode cull_back;
uniform sampler2D tex: filter_nearest, repeat_enable, source_color;
uniform float light_steps = 5.0;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(tex, UV).rgb * COLOR.rgb;
	SPECULAR = 1.0;
	METALLIC = 0.0;
	ROUGHNESS = 0.0;
}

void light() {
	float light = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	light = ceil(light * light_steps) / light_steps;
	DIFFUSE_LIGHT += light * (LIGHT_COLOR / PI) * ATTENUATION;
	float rim =  1.0 - dot(NORMAL, VIEW);
	rim *= light;
	rim = round(rim * light_steps) / light_steps;
	rim = rim * rim;
	DIFFUSE_LIGHT += rim * ATTENUATION * LIGHT_COLOR / PI;
}
