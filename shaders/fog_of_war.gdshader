shader_type canvas_item;
render_mode unshaded;

// One texel = one world tile. R channel:
//   0.0  = never explored  → solid black
//   1.0  = explored         → dim memory (when out of sight) or transparent (in sight)
uniform sampler2D fog_tex       : filter_nearest, repeat_disable;
uniform vec2      player_uv     = vec2(0.5, 0.5);   // player pos in [0,1] UV space
uniform float     vision_uv     = 0.035;             // sight radius in UV space
uniform float     memory_alpha  = 0.72;              // how opaque the "remembered" overlay is

void fragment() {
	float explored = texture(fog_tex, UV).r;
	float d        = length(UV - player_uv);

	// Soft edge at sight boundary (inner 85% hard-clear, outer 15% fade in)
	float edge = smoothstep(vision_uv * 0.82, vision_uv, d);

	if (edge < 0.01) {
		// Fully in sight — transparent so world + torch lighting show through
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (explored > 0.4) {
		// Explored but outside sight — dim bluish-black memory overlay
		COLOR = vec4(0.0, 0.0, 0.04, memory_alpha * edge);
	} else {
		// Never explored — solid black
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
