--[[pod_format="raw",created="2024-09-04 23:51:40",modified="2024-10-17 08:16:51",revision=88]]
include"require.lua"
include"profiler.lua"

local import_ptm = require"blade3d.ptm_importer"
local Rendering = require"blade3d.rendering"
local Camera = require"blade3d.camera"
local quat = require"blade3d.quaternions"
local B3dUtils = require"blade3d.utils"

profile.enabled(false,true)

-- The materials table tells the ptm importer what each
-- material name in the model file should be rendered with.
local materials = {
	Teapot = {
		shader = require"blade3d.shaders.textri",
		properties = {tex = 1}
	},
}

local model = import_ptm("mdl/teapot.ptm",materials)
local model_mat = B3dUtils.ident_mat(4) -- Gets a matrix with no transformations

local cam_yaw,cam_pitch = 0,-0.1
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
	
	-- Since model_mat is an identity matrix, it is its own inverse,
	-- but in practice you would generate a separate matrix for the
	-- inverse transformation.
	Rendering.queue_model(model,model_mat,model_mat)
	Rendering.draw_all()
	
	profile.draw()
end