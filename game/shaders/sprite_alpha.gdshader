shader_type canvas_item;
// Generated sheets contain low-opacity background residue. Remove it at render
// time, before node modulation, so hit flashes and death fades still work.
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	texel.a *= smoothstep(0.08, 0.20, texel.a);
	COLOR = texel * vertex_tint;
}
