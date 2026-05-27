shader_type canvas_item;
render_mode unshaded;

// TEXTURE  = terrain colour map  (set via TextureRect.texture)
// fog_tex  = live fog ImageTexture from FogOfWar (updates every reveal)
uniform sampler2D fog_tex : filter_nearest, repeat_disable;

void fragment() {
	vec4  terrain = texture(TEXTURE, UV);
	float fog     = texture(fog_tex, UV).r;

	if (fog < 0.1) {
		// Never explored — solid black
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else if (fog < 0.9) {
		// Visited but not currently in sight — dim memory tint
		COLOR = vec4(terrain.rgb * 0.38, 1.0);
	} else {
		// Currently visible — slightly brightened terrain colour
		COLOR = vec4(terrain.rgb * 1.12, 1.0);
	}
}
