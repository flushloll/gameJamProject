shader_type spatial;

global uniform vec2 player_on_screen_position;
global uniform sampler2D dither_texture: filter_nearest;
const float PLAYER_TRANSPARENCY_SIZE = 50.0;

void fragment() {
	float value = clamp(
		(
			(FRAGCOORD.x - player_on_screen_position.x) * (FRAGCOORD.x - player_on_screen_position.x) +
			(FRAGCOORD.y - player_on_screen_position.y) * (FRAGCOORD.y - player_on_screen_position.y)
		)/ (PLAYER_TRANSPARENCY_SIZE * 100.0) - 0.5,
		0.0,
		1.0
	);
	
	float dither = texture(dither_texture, vec2(FRAGCOORD.xy) / vec2(textureSize(dither_texture, 0))).r;
	if (value < dither){
		ALPHA = 0.0;
	}
	if (value >= 1.0){
		discard;
	}
	//if (value >= dither){
		//discard;
	//}
}