--[[pod_format="raw",created="2024-10-26 19:38:52",modified="2024-10-26 19:58:30",revision=73]]
---Draws a shaded triangle to the screen.
---@param props table The properties passed to the shader. Expects a `light` field that determines the color of the triangle.
---@param p1 userdata The XY coordinates of the first vertex.
---@param p2 userdata The XY coordinates of the second vertex.
---@param p3 userdata The XY coordinates of the third vertex.
---@param screen_height number The height of the screen, used for scanline truncation.
return function(properties,p1,p2,p3,_,_,_,screen_height)
	profile"Triangle setup"

	local color_ramp = {1,21,5,13,22,6,7}
	local face_color
	
	face_color = color_ramp[ceil((properties.light * #color_ramp))]

	-- To make it so that rasterizing top to bottom is always correct,
	-- and so that we know at which point to switch the minor side's slope,
	-- we need the vertices to be sorted by y.
	if p1.y > p2.y then
		p1,p2 = p2,p1
	end
	if p2.y > p3.y then
		p2,p3 = p3,p2
	end
	if p1.y > p2.y then
		p1,p2 = p2,p1
	end
	
	-- Since the y components are used extensively, we'll store them in
	-- local variables.
	local y1,y2,y3 = p1.y,p2.y,p3.y
	
	local v1,v2 = 
		vec(p1.x,p1.y,p1.x,p1.y,face_color),
		vec(
			p2.x,p2.y,
			(p3.x-p1.x)*(p2.y-p1.y)/(p3.y-p1.y)+p1.x, p2.y,
			face_color
		)
	profile"Triangle setup"
	
	profile"Triangle drawing"
	local start_y = y1 < -1 and -1 or y1\1
	local mid_y = y2 < -1 and -1 or y2 > screen_height-1 and screen_height-1 or y2\1
	local stop_y = (y3 <= screen_height-1 and y3\1 or screen_height-1)
	
	-- Top half
	local dy = mid_y-start_y
	if dy > 0 then
		local slope = (v2-v1)/(y2-y1)
		
		local scanlines = userdata("f64",5,dy)
			:copy(slope*(start_y+1-y1)+v1,true,0,0,5)
			:copy(slope,true,0,5,5,0,5,dy-1)
		
		rectfill(scanlines:add(scanlines,true,0,5,5,5,5,dy-1))
	end
	
	-- Bottom half
	dy = stop_y-mid_y
	if dy > 0 then
		-- This is, otherwise, the only place where v3 would be used,
		-- so we just inline it.
		local slope = (vec(p3.x,p3.y,p3.x,p3.y,face_color)-v2)/(y3-y2)
		
		local scanlines = userdata("f64",5,dy)
			:copy(slope*(mid_y+1-y2)+v2,true,0,0,5)
			:copy(slope,true,0,5,5,0,5,dy-1)
		
		rectfill(scanlines:add(scanlines,true,0,5,5,5,5,dy-1))
	end
	profile"Triangle drawing"
end