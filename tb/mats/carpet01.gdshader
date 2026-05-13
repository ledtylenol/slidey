shader_type spatial;

uniform sampler2D noise: repeat_enable;
void vertex() {
	float n = texture(noise, UV + TIME / 10.0 + VERTEX.yx).r * 3.14;
	VERTEX.x += sin(n);
	VERTEX.y += cos(n);
	VERTEX.z += sin(cos(n));
}

void fragment() {
	ALBEDO = texture(noise, UV + TIME / 10.0).rgb * COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
