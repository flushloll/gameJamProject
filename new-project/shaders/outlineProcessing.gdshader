shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled;

group_uniforms outline;
uniform vec4 outlineColor: source_color = vec4(0.0, 0.0, 0.0, 0.78);
uniform float depth_threshold = 0.025;
uniform float normal_threshold : hint_range(0.0, 1.5) = 0.5;
uniform float normal_smoothing : hint_range(0.0, 1.0) = 0.25;

group_uniforms thickness;
uniform float max_thickness: hint_range(0.0, 5.0) = 1.3;
uniform float min_thickness = 0.5;
uniform float max_distance = 75.0;
uniform float min_distance = 2.0;

group_uniforms grazing_prevention;
uniform float grazing_fresnel_power = 5.0;
uniform float grazing_angle_mask_power = 1.0;
uniform float grazing_angle_modulation_factor = 50.0;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear, repeat_disable;

// =============================
// Compatibility: always reconstruct normals from depth
// =============================
varying flat mat4 model_view_matrix;

struct UVNeighbors {
	vec2 center; 
	vec2 left;     vec2 right;     vec2 up;          vec2 down;
	vec2 top_left; vec2 top_right; vec2 bottom_left; vec2 bottom_right;
};

struct NeighborDepthSamples {
	float c_d; 
	float l_d;  float r_d;  float u_d;  float d_d; 
	float tl_d; float tr_d; float bl_d; float br_d;
};

UVNeighbors getNeighbors(vec2 center, float width, float aspect) {
	vec2 h_offset = vec2(width * aspect * 0.001, 0.0);
	vec2 v_offset = vec2(0.0, width * 0.001);
	UVNeighbors n;
	n.center = center;
	n.left   = center - h_offset;
	n.right  = center + h_offset;
	n.up     = center - v_offset;
	n.down   = center + v_offset;
	n.top_left     = center - (h_offset - v_offset);
	n.top_right    = center + (h_offset - v_offset);
	n.bottom_left  = center - (h_offset + v_offset);
	n.bottom_right = center + (h_offset + v_offset);
	return n;
}

float getLinearDepth(float depth, vec2 uv, mat4 inv_proj) {
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

NeighborDepthSamples getLinearDepthSamples(UVNeighbors uvs, sampler2D depth_tex, mat4 invProjMat) {
	NeighborDepthSamples result;
	result.c_d  = getLinearDepth(texture(depth_tex, uvs.center).r, uvs.center, invProjMat);
	result.l_d  = getLinearDepth(texture(depth_tex, uvs.left).r  , uvs.left  , invProjMat);
	result.r_d  = getLinearDepth(texture(depth_tex, uvs.right).r , uvs.right , invProjMat);
	result.u_d  = getLinearDepth(texture(depth_tex, uvs.up).r    , uvs.up    , invProjMat);
	result.d_d  = getLinearDepth(texture(depth_tex, uvs.down).r  , uvs.down  , invProjMat);
	result.tl_d = getLinearDepth(texture(depth_tex, uvs.top_left).r, uvs.top_left, invProjMat);
	result.tr_d = getLinearDepth(texture(depth_tex, uvs.top_right).r, uvs.top_right, invProjMat);
	result.bl_d = getLinearDepth(texture(depth_tex, uvs.bottom_left).r, uvs.bottom_left, invProjMat);
	result.br_d = getLinearDepth(texture(depth_tex, uvs.bottom_right).r, uvs.bottom_right, invProjMat);
	return result;
}

float remap(float v, float from1, float to1, float from2, float to2) {
	return (v - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float getGrazingAngleModulation(vec3 pixel_normal, vec3 view) {
	float x = clamp(((fresnel(grazing_fresnel_power, pixel_normal, view) - 1.0) / grazing_angle_mask_power) + 1.0, 0.0, 1.0);
	return (x + grazing_angle_modulation_factor) + 1.0;
}

float detectEdgesDepth(NeighborDepthSamples depth_samples, vec3 pixel_normal, vec3 view) {
	float n_total = 
		depth_samples.l_d + 
		depth_samples.r_d + 
		depth_samples.u_d + 
		depth_samples.d_d + 
		depth_samples.tl_d + 
		depth_samples.tr_d + 
		depth_samples.bl_d + 
		depth_samples.br_d;
	float t = depth_threshold * getGrazingAngleModulation(pixel_normal, view);
	return step(t, n_total - (depth_samples.c_d * 8.0));
}

// ===== Normal Reconstruction =====
vec3 reconstructWorldPosition(float depth, mat4 model_view, mat4 inv_proj, vec2 screen_uv, mat4 world, mat4 inv_cam){
  vec4 pos = inverse(model_view) * inv_proj * vec4((screen_uv*2.0-1.0), depth*2.0-1.0, 1.0);
  pos.xyz /= pos.w;
  return (pos * inv_cam).xyz + world[3].xyz;
}

vec3 reconstructWorldNormal(sampler2D depth_tex, mat4 model_view, mat4 inv_proj, vec2 screen_uv, mat4 world, mat4 inv_cam, vec2 viewport_size){
	vec2 e = vec2(1.0 / viewport_size);
	vec3 c  = reconstructWorldPosition(texture(depth_tex, screen_uv).r, model_view, inv_proj, screen_uv, world, inv_cam);
	vec3 cx = reconstructWorldPosition(texture(depth_tex, screen_uv + vec2(e.x,0)).r, model_view, inv_proj, screen_uv + vec2(e.x,0), world, inv_cam);
	vec3 cy = reconstructWorldPosition(texture(depth_tex, screen_uv + vec2(0,e.y)).r, model_view, inv_proj, screen_uv + vec2(0,e.y), world, inv_cam);
	return normalize(cross(cx-c, cy-c));
}

float detectEdgesNormalReconstructed(UVNeighbors uvs, sampler2D depth_tex, mat4 model_view, mat4 inv_proj, vec2 screen_uv, mat4 world, mat4 inv_cam, vec2 viewport_size){
	vec3 n_u  = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.up,           world, inv_cam, viewport_size);
	vec3 n_d  = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.down,         world, inv_cam, viewport_size);
	vec3 n_l  = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.left,         world, inv_cam, viewport_size);
	vec3 n_r  = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.right,        world, inv_cam, viewport_size);
	vec3 n_tl = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.top_left,     world, inv_cam, viewport_size);
	vec3 n_tr = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.top_right,    world, inv_cam, viewport_size);
	vec3 n_bl = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.bottom_left,  world, inv_cam, viewport_size);
	vec3 n_br = reconstructWorldNormal(depth_tex, model_view, inv_proj, uvs.bottom_right, world, inv_cam, viewport_size);
	
	vec3 normalFiniteDifference0 = n_tr - n_bl;
	vec3 normalFiniteDifference1 = n_tl - n_br;
	vec3 normalFiniteDifference2 = n_l - n_r;
	vec3 normalFiniteDifference3 = n_u - n_d;
	
	float edgeNormal = sqrt(
		dot(normalFiniteDifference0, normalFiniteDifference0) + 
		dot(normalFiniteDifference1, normalFiniteDifference1) + 
		dot(normalFiniteDifference2, normalFiniteDifference2) + 
		dot(normalFiniteDifference3, normalFiniteDifference3)
	) * 0.5;
	
	return smoothstep(normal_threshold - normal_smoothing, normal_threshold + normal_smoothing, edgeNormal);
}

// ===== Vertex/Fragment =====
void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	model_view_matrix = INV_VIEW_MATRIX;
}

	float getMinimumDepth(NeighborDepthSamples s) {
	float min_d = s.c_d;
	min_d = min(min_d, s.l_d);
	min_d = min(min_d, s.r_d);
	min_d = min(min_d, s.u_d);
	min_d = min(min_d, s.d_d);
	min_d = min(min_d, s.tl_d);
	min_d = min(min_d, s.tr_d);
	min_d = min(min_d, s.bl_d);
	min_d = min(min_d, s.br_d);
	return min_d;
}

void fragment() {
	float aspect = float(VIEWPORT_SIZE.y) / float(VIEWPORT_SIZE.x);
	UVNeighbors n = getNeighbors(SCREEN_UV, max_thickness, aspect);
	NeighborDepthSamples depth_samples = getLinearDepthSamples(n, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	float min_d = getMinimumDepth(depth_samples);
	float thickness = clamp(remap(min_d, min_distance, max_distance, max_thickness, min_thickness), min_thickness, max_thickness);
	float fade_a = clamp(remap(min_d, min_distance, max_distance, 1.0, 0.0), 0.0, 1.0);
	
	n = getNeighbors(SCREEN_UV, thickness, aspect);
	depth_samples = getLinearDepthSamples(n, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	
	vec3 pixel_normal = reconstructWorldNormal(DEPTH_TEXTURE, model_view_matrix, INV_PROJECTION_MATRIX, SCREEN_UV, MODEL_MATRIX, INV_VIEW_MATRIX, VIEWPORT_SIZE.xy);
	float depthEdges = detectEdgesDepth(depth_samples, pixel_normal, VIEW);
	float normEdges  = detectEdgesNormalReconstructed(n, DEPTH_TEXTURE, model_view_matrix, INV_PROJECTION_MATRIX, SCREEN_UV, MODEL_MATRIX, INV_VIEW_MATRIX, VIEWPORT_SIZE.xy);
	
	ALBEDO.rgb = outlineColor.rgb;
	ALPHA = max(depthEdges, normEdges) * outlineColor.a * fade_a;
}
