--[[pod_format="raw",created="2024-09-04 23:51:40",modified="2024-10-26 19:58:30",revision=202]]
include"require.lua"
include"profiler.lua"

local import_ptm = require"blade3d.ptm_importer"
local Rendering = require"blade3d.rendering"
local Transform = require"blade3d.transform"
local Camera = require"blade3d.camera"
local quat = require"blade3d.quaternions"
local B3dUtils = require"blade3d.utils"

profile.enabled(false,true)

-- The materials table tells the ptm importer what each
-- material name in the model file should be rendered with.
local materials = {
	Teapot = {
		shader = require"blade3d.shaders.flatfill",
	},
}

local model = import_ptm("mdl/teapot.ptm",materials)
local model_mat = B3dUtils.ident_mat(4) -- Gets a matrix with no transformations

local cam_yaw,cam_pitch = 0,0
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
	
	-- Get the rotated matrix and inverse matrix
	local rot_matrix, inv_rot_matrix = Transform.double_rotate(vec(t()/16,t()/8,t()/32), model_mat, model_mat)
	
	-- Tell the renderer to render the model with the rotated matricies
	Rendering.queue_model(model,rot_matrix,inv_rot_matrix,vec(0.70,0.71,0.0))
	
	-- Draw and animate a cool grid effect
	draw_grid(Transform.translate(vec(0,-10,(t()*40)%40)))
	draw_grid(Transform.translate(vec(0,10,(t()*40)%40)))

	Rendering.draw_all()
	
	profile.draw()
end

function draw_grid(mat)
	for x = 0, 20 do
		local scale = 40 * x
		local v1 = vec(scale-400,0,-400,1)
		local v2 = vec(scale-400,0,400,1)
		local v3 = vec(400,0,scale-400,1)
		local v4 = vec(-400,0,scale-400,1)
		
		Rendering.queue_line(v1,v2,8,mat)
		Rendering.queue_line(v3,v4,8,mat)
	end
end