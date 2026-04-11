shader_type spatial;

uniform sampler2D noise: repeat_enable;
void vertex() {
	VERTEX.x += sin(TIME + VERTEX.y);
	VERTEX.y += sin(TIME + VERTEX.x);
}

void fragment() {
	ALBEDO = texture(noise, UV + TIME / 10.0).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
