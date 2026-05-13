@tool
extends CompositorEffect
class_name DeathShader


const template_shader: String = """
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(set = 0, binding = 1) uniform sampler2D depth;
layout(set = 0, binding = 2) uniform sampler2D noise;
layout(set = 0, binding = 3) uniform sampler2D normal_sampler;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	float thres;
	float time;
	float y_stretch;
	float step_offset;
} params;
layout(set=1, binding=0) uniform uniformBuffer {
	mat4 view;
	mat4 proj;
	
	mat4 invview;
	mat4 invproj;
	

	} mat;
// The code we want to execute in each invocation
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
vec3 get_cam_pos(vec2 uv, float depth){
	vec4 upos = mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 cp = upos.xyz / upos.w;
	return cp;
	
	}

vec3 get_world_pos(vec2 uv, float depth){
	vec4 upos = mat.view * mat.invproj * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 pp = upos.xyz / upos.w;
	return pp;
	
	}
vec3 get_world_normal(vec2 fuv){
	vec4 normal = texture(normal_sampler, fuv); 
	mat3 nmv = mat3(
		mat.view
		);	
	vec3 wn =  normalize( nmv * (normal.xyz - 0.5) );
	return wn;
	}
vec3 get_view_normal(vec2 fuv){
	vec4 normal = texture(normal_sampler, fuv); 
	
	vec3 wn =   (normal.xyz - 0.5) ;
	return wn;
	}

vec2 slide_uv(vec2 uv, vec3 normal, float depth) {
	vec3 v = normalize(-get_cam_pos(uv, depth));
	float l = length(normal);
	vec3 proj = (dot(v, normal)/(l * l) )* normal;
	vec3 slid = v - proj;
	return slid.xy;
}
vec2 slide_vec(vec2 uv, vec3 normal, vec3 v, float depth) {
	float l = length(normal);
	vec3 proj = (dot(v, normal)/(l * l) )* normal;
	vec3 slid = v - proj;
	return slid.xy;
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
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);
	
	vec2 uv_norm = vec2(uv + 0.5) / size;
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv);

	#COMPUTE_CODE

	imageStore(color_image, uv, color);
}
"""
@export_multiline var shader_code: String = "":
	set(value):
		mutex.lock()
		shader_code = value
		shader_is_dirty = true
		mutex.unlock()

@export var thres := 50000.0
@export var noise: NoiseTexture2D
var y_stretch := 1.0
@export var step_offset := 20.0
var noise_image: RID
@export var time := 0.0
var cam_tr: Transform3D
var view_proj: Projection
var set_mats := true
var rd: RenderingDevice
var shader: RID
var pipeline: RID
var mat_buffer : RID
var mutex: Mutex = Mutex.new()
var shader_is_dirty: bool = true
var sampler: RID
var depth_sampler: RID
var normal_sampler: RID

var s_uniform: RDUniform
var matrices_uniform: RDUniform
var d_uniform: RDUniform
var uniform: RDUniform
var normal_uniform: RDUniform
func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()
	var sampler_state := RDSamplerState.new()
	sampler_state.repeat_u =RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_state.repeat_v =RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler = rd.sampler_create(sampler_state)
	depth_sampler = rd.sampler_create(sampler_state)
	normal_sampler = rd.sampler_create(sampler_state)
	mat_buffer =  rd.uniform_buffer_create(256, PackedByteArray())
	
	s_uniform = RDUniform.new()
	s_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	s_uniform.binding = 2
	
	normal_uniform = RDUniform.new()
	normal_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	normal_uniform.binding = 3
	
	matrices_uniform = RDUniform.new()
	matrices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	matrices_uniform.binding = 0
	
	d_uniform = RDUniform.new()
	d_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	d_uniform.binding = 1
	
	uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			# Freeing our shader will also free any dependents such as the pipeline!
			rd.free_rid(shader)
		if sampler.is_valid(): rd.free_rid(sampler)
		if mat_buffer.is_valid(): rd.free_rid(mat_buffer)
		if normal_sampler.is_valid(): rd.free_rid(normal_sampler)
func _check_shader() -> bool:
	if not rd:
		return false

	var new_shader_code: String = ""

	# Check if our shader is dirty.
	mutex.lock()
	if shader_is_dirty:
		new_shader_code = shader_code
		shader_is_dirty = false
	mutex.unlock()

	# We don't have a (new) shader?
	if new_shader_code.is_empty():
		return pipeline.is_valid()

	# Apply template.
	new_shader_code = template_shader.replace("#COMPUTE_CODE", new_shader_code);

	# Out with the old.
	if shader.is_valid():
		rd.free_rid(shader)
		shader = RID()
		pipeline = RID()

	# In with the new.
	var shader_source: RDShaderSource = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	shader_source.source_compute = new_shader_code
	var shader_spirv: RDShaderSPIRV = rd.shader_compile_spirv_from_source(shader_source)

	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		push_error("In: " + new_shader_code)
		return false

	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return false

	pipeline = rd.compute_pipeline_create(shader)
	return pipeline.is_valid()

func _render_callback(p_effect_callback_type, p_render_data):
	if not noise:
		return
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and _check_shader():
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return

			# We can use a compute shader here.
			var x_groups = (size.x - 1) / 8 + 1
			var y_groups = (size.y - 1) / 8 + 1
			var z_groups = 1

			# Push constant.
			var push_constant: PackedFloat32Array = PackedFloat32Array()
			push_constant.resize(8)
			push_constant[0] = (size.x)
			push_constant[1] = (size.y)
			push_constant[2] = (thres)
			push_constant[3] = (time)
			push_constant[4] = (y_stretch)
			push_constant[5] = (step_offset)
			if not noise_image:
				var noise_format := RDTextureFormat.new()
				noise_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
				var noise_img = noise.get_image()
				noise_img.clear_mipmaps()
				noise_img.convert(Image.FORMAT_RGBAF)
				noise_format.width = noise_img.get_width()
				noise_format.height = noise_img.get_height()
				noise_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
				var n_view = RDTextureView.new()
				noise_image = rd.texture_create(noise_format, n_view, [noise_img.get_data()])
			var normals_buffer = render_scene_buffers.get_texture("forward_clustered", "normal_roughness")
			s_uniform.clear_ids()
			s_uniform.add_id(sampler)
			s_uniform.add_id(noise_image)
			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				var render_scene_data = p_render_data.get_render_scene_data()
				var invcam_tr = render_scene_data.get_cam_transform()
				var proj = render_scene_data.get_cam_projection()
				
				var view_tr = invcam_tr.inverse()
				var invproj = proj.inverse()
				

				var invcam_mat = [
					invcam_tr.basis.x.x, invcam_tr.basis.x.y, invcam_tr.basis.x.z, 0.0, 
					invcam_tr.basis.y.x, invcam_tr.basis.y.y, invcam_tr.basis.y.z, 0.0, 
					invcam_tr.basis.z.x, invcam_tr.basis.z.y, invcam_tr.basis.z.z, 0.0, 
					invcam_tr.origin.x, invcam_tr.origin.y, invcam_tr.origin.z, 1.0, 
				]
				
				var proj_mat = [
					proj.x.x, proj.x.y, proj.x.z,  proj.x.w, 
					proj.y.x, proj.y.y, proj.y.z,proj.y.w, 
					proj.z.x, proj.z.y, proj.z.z, proj.z.w, 
					proj.w.x, proj.w.y, proj.w.z, proj.w.w, 
				]
				
				
				var view_mat = [
					view_tr.basis.x.x, view_tr.basis.x.y, view_tr.basis.x.z, 0.0, 
					view_tr.basis.y.x, view_tr.basis.y.y, view_tr.basis.y.z, 0.0, 
					view_tr.basis.z.x, view_tr.basis.z.y, view_tr.basis.z.z, 0.0, 
					view_tr.origin.x, view_tr.origin.y, view_tr.origin.z, 1.0, 
				]
				
				var invproj_mat = [
					invproj.x.x, invproj.x.y, invproj.x.z,  invproj.x.w, 
					invproj.y.x, invproj.y.y, invproj.y.z,invproj.y.w, 
					invproj.z.x, invproj.z.y, invproj.z.z, invproj.z.w, 
					invproj.w.x, invproj.w.y, invproj.w.z, invproj.w.w, 
				]
				
						
				var icma = PackedFloat32Array(invcam_mat).to_byte_array()
				var pma = PackedFloat32Array(proj_mat).to_byte_array()
				
				var vma = PackedFloat32Array(view_mat).to_byte_array()
				var ipma = PackedFloat32Array(invproj_mat).to_byte_array()
				
				var pb = PackedByteArray()
				pb.append_array(icma)
				pb.append_array(pma)
				
				pb.append_array(vma)
				pb.append_array(ipma)
				
				rd.buffer_update(mat_buffer, 0, 256, pb)

				
				matrices_uniform.clear_ids()
				matrices_uniform.add_id(mat_buffer)
				var matrices_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 1, [  matrices_uniform ])

				# Get the RID for our color image, we will be reading from and writing to it.
				var input_image = render_scene_buffers.get_color_layer(view)
				var depth_texture = render_scene_buffers.get_depth_layer(view)

				d_uniform.clear_ids()
				d_uniform.add_id(depth_sampler)
				d_uniform.add_id(depth_texture)

				# Create a uniform set.
				# This will be cached; the cache will be cleared if our viewport's configuration is changed.
				uniform.clear_ids()
				uniform.add_id(input_image)
				
				normal_uniform.clear_ids()
				normal_uniform.add_id(normal_sampler)
				normal_uniform.add_id(normals_buffer)
				var uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ uniform , d_uniform, s_uniform, normal_uniform])

				# Run our compute shader.
				var compute_list:= rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, matrices_uniform_set, 1)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
