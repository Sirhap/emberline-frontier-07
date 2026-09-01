shader_type canvas_item;
render_mode unshaded, blend_mix;

// Catalog hold/pickup as a cyan/white hologram silhouette.
// High tint so gold/red metal (sword) does not survive; scan + flicker stay light.
uniform float scan_density : hint_range(16.0, 140.0, 1.0) = 64.0;
uniform float scan_strength : hint_range(0.0, 0.5, 0.01) = 0.04;
uniform float scan_speed : hint_range(0.0, 4.0, 0.01) = 0.40;
uniform float flicker_strength : hint_range(0.0, 0.2, 0.01) = 0.015;
uniform float tint_amount : hint_range(0.0, 1.0, 0.01) = 0.92;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	// Dark = cyan from Sprite2D.modulate, bright = near-white. Not Color.WHITE metal.
	vec3 hol = mix(COLOR.rgb * 0.82, vec3(0.94, 0.99, 1.0), luma);
	vec3 tinted = mix(tex.rgb, hol, tint_amount);
	float scan = 1.0 - scan_strength * (0.5 + 0.5 * sin((UV.y * scan_density + TIME * scan_speed) * 6.283185));
	float flicker = 1.0 - flicker_strength * (0.5 + 0.5 * sin(TIME * 19.0));
	COLOR = vec4(tinted * scan * mix(0.97, 1.0, flicker), tex.a * COLOR.a);
}
