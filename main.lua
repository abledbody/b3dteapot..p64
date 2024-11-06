--[[pod_format="raw",created="2024-09-04 23:51:40",modified="2024-11-06 08:07:27",revision=251]]
include"require.lua"
include"profiler.lua"

local import_ptm = require"blade3d.ptm_importer"
local Rendering = require"blade3d.rendering"
local Transform = require"blade3d.transform"
local Camera = require"blade3d.camera"
local quat = require"blade3d.quaternions"

profile.enabled(false,true)

-- The materials table tells the ptm importer what each
-- material name in the model file should be rendered with.
local materials = {
	Teapot = {
		shader = require"blade3d.shaders.lambtri",
		properties = {
			col = 7,
		},
	},
	B3DBadge = {
		shader = require"blade3d.shaders.lambtextri",
		properties = {
			tex = 2,
		},
	},
}

local model = import_ptm("mdl/teapot.ptm",materials)

local grid_spacing = 40
local grid_lines = 20
local grid_separation = 40

local cam_yaw,cam_pitch = 0.08,-0.03
local cam_vel = vec(0,0,0)
local cam_dist = 6
local cam
do
	local cam_rot = quat.mul(quat(vec(0,1,0),cam_yaw),quat(vec(1,0,0),cam_pitch))
	window() -- For some reason get_display doesn't work without this.
	cam = Camera.new(
		0.1,100, -- Near and far planes
		Camera.get_fov_slope(100), -- FOV
		get_display(), -- Target display userdata
		quat.vmul(vec(0,0,cam_dist),cam_rot), -- Position
		cam_rot -- Rotation
	)
end
Rendering.set_camera(cam)

function _update()
	local inputs = vec(
		(btn(1) or 0)/255 - (btn(0) or 0)/255,
		(btn(3) or 0)/255 - (btn(2) or 0)/255,
		(btn(5) or 0)/255 - (btn(4) or 0)/255
	)
	cam_vel += inputs*vec(0.0006,0.0006,0.01)
	cam_vel *= 0.9
	cam_yaw = (cam_yaw+cam_vel.x)%1
	cam_pitch = mid(cam_pitch+cam_vel.y,-0.25,0.25)
	cam_dist = max(cam_dist+cam_vel.z,0.1)
	local cam_rot = quat.mul(quat(vec(0,1,0),cam_yaw),quat(vec(1,0,0),cam_pitch))
	cam:set_transform(quat.vmul(vec(0,0,cam_dist),cam_rot),cam_rot)
end

function _draw()
	cls()
	
	local rot = vec(
		cos(t()/19)*0.5,
		t()/21,
		cos(t()/27)*0.5
	)
	
	-- Get the model matrix and its inverse. The only transformation is rotation.
	local model_mat, model_mat_inv = Transform.double_rotate(rot)
	
	-- To draw a model, you need to add it to the queue with some extra
	-- information. Both the model matrix is needed for transformations,
	-- and its inverse for lighting and backface culling.
	-- The last three arguments, ambient light, light direction,
	-- and light intensity, are optional. If no light intensity is given,
	-- the light is directional, and the magnitude controls the intensity.
	Rendering.queue_model(model,model_mat,model_mat_inv,0.1,vec(0.8,0.8,0.0))
	
	-- Draw and animate a cool grid effect
	draw_grid(Transform.translate(vec(0,-10,(t()*grid_separation)%grid_spacing)))
	draw_grid(Transform.translate(vec(0,10,(t()*grid_separation)%grid_spacing)))

	Rendering.draw_all()
	
	profile.draw()
end

function draw_grid(mat)
	local length = grid_lines*grid_spacing*0.5
	
	for x = -grid_lines*0.5, grid_lines*0.5 do
		local offset = x*grid_spacing
		local v1 = vec(offset,0,-length,1)
		local v2 = vec(offset,0,length,1)
		local v3 = vec(length,0,offset,1)
		local v4 = vec(-length,0,offset,1)
		
		Rendering.queue_line(v1,v2,8,mat)
		Rendering.queue_line(v3,v4,8,mat)
	end
end

include"error_explorer.lua"

music(0)