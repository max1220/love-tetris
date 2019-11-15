


math.randomseed(os.time())


local scene
function change_scene(new_scene)
	if scene and scene.unload then
		scene:unload()
	end
	if new_scene.load then
		new_scene:load()
	end
	scene = new_scene
end
function is_phone()
	if love.system.getOS() == 'iOS' or love.system.getOS() == 'Android' then
		return true
	end
end
local function hue2rgb(p, q, t)
	if t < 0   then t = t + 1 end
	if t > 1   then t = t - 1 end
	if t < 1/6 then return p + (q - p) * 6 * t end
	if t < 1/2 then return q end
	if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
	return p
end
function hsl_to_rgb(h, s, l, a)
	local r, g, b
	if s == 0 then
		return l,l,l,a
	else
		local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
		local p = 2 * l - q
		return hue2rgb(p, q, h + 1/3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1/3)
	end
	return r, g, b, a
end
function love.update(dt)
	if scene and scene.update then
		scene:update(dt)
	end
end
function love.draw()
	if scene and scene.draw then
		scene:draw()
	end
end
function love.load()
	love.keyboard.setKeyRepeat(true)
	if is_phone() then
		local maj, min,usedpiscale = love.getVersion()
		if min > 3 then
			usedpiscale = false
		end
		local usedpiscale
		love.window.setMode(800,600, {
			vsync = true,
			fullscreen = true,
			resizable = true,
			usedpiscale = usedpiscale
		})
	else
		love.window.setMode(800,600, {
			vsync = true,
			resizable = true,
			fullscreen = false,
		})
	end




	gameover_scene = require("gameover_scene")
	tetris_scene = require("tetris_scene")
	change_scene(tetris_scene)
end
function love.keypressed(key)
	if scene and scene.keypressed then
		scene:keypressed(key)
	end
end
function love.resize(w,h)
	if scene.resize then
		scene:resize(w,h)
	end
end
function love.mousepressed(x,y, btn)
	if scene.mousepressed then
		scene:mousepressed(x,y, btn)
	end
end






