shader_type spatial;

global uniform float wind_scale;
global uniform float wind_speed;
global uniform float wind_strength;
global uniform vec3 wind_direction;
global uniform vec3 playerpos;
global uniform sampler2D wind_noise: filter_linear_mipmap;

instance uniform vec4 color: source_color;
uniform sampler2D alpha;
uniform float alpha_affect = 0.4;
instance uniform float leaf_scale = 1.0;
instance uniform float alpha_value = 1.0;
instance uniform float distance_threshold = 5.0;
uniform float light_steps = 5.0;
uniform float bend_amount = 1.0;

varying vec4 view_pos;

varying vec4 world_pos;
void vertex() {
	world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	COLOR.a = smoothstep(distance_threshold, distance_threshold + 1.0, distance(world_pos.xyz, playerpos)) * alpha_affect + (1.0 - alpha_affect);
	COLOR.a *= smoothstep(distance_threshold, distance_threshold + 1.0, distance(world_pos.xyz, CAMERA_POSITION_WORLD)) * alpha_affect + (1.0 - alpha_affect);
	float speed = TIME * wind_speed;
	float noise_texture = textureLod(wind_noise, (world_pos.xz * wind_scale) - (speed * wind_direction.xz), 1.0).r;
	
	noise_texture = (noise_texture * 2. - 1.) * (wind_strength * bend_amount) ;

	vec4 new_pos = vec4(UV.y, UV.x, 0.0, 1.0);
	new_pos += noise_texture * vec4(1.0, 0.0, 0.0, 0.0) * (UV.x * 2. - 1.)
		- noise_texture * vec4(0.0, 1.0, 0.0, 0.0) * (UV.y * 2. - 1.0);

	new_pos = new_pos * 2. - 1.;
	new_pos = normalize(new_pos);
	new_pos *= leaf_scale;
	new_pos *= MODELVIEW_MATRIX;
	view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

	VERTEX += new_pos.xyz;
}

float bayer8(vec2 frag) {
	int x = int(mod(frag.x, 8.0));
	int y = int(mod(frag.y, 8.0));

	int index = x + y * 8;

	int matrix[64] = int[](
		0, 32,  8, 40,  2, 34, 10, 42,
		48, 16, 56, 24, 50, 18, 58, 26,
		12, 44,  4, 36, 14, 46,  6, 38,
		60, 28, 52, 20, 62, 30, 54, 22,
		3, 35, 11, 43,  1, 33,  9, 41,
		51, 19, 59, 27, 49, 17, 57, 25,
		15, 47,  7, 39, 13, 45,  5, 37,
		63, 31, 55, 23, 61, 29, 53, 21
	);
	return float(matrix[index]) / 64.0;
}
float bayer4(vec2 frag) {
	int x = int(mod(frag.x, 4.0));
	int y = int(mod(frag.y, 4.0));

	int index = x + y * 4;

	int matrix[16] = int[](
		0,  8,  2, 10,
		12,  4, 14,  6,
		3, 11,  1,  9,
		15,  7, 13,  5
	);

	return float(matrix[index]) / 16.0;
}
void fragment() {
	ALPHA_SCISSOR_THRESHOLD = 0.1;
	LIGHT_VERTEX = view_pos.xyz;
	ALBEDO = color.rgb;
	float alpha_val = texture(alpha, UV).r * alpha_value * COLOR.a;
	ALPHA = step(bayer4(FRAGCOORD.xy) + 0.01, alpha_val);
	if(alpha_val < 0.1) discard;
	ROUGHNESS = 0.0;
	SPECULAR = 0.0;
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
