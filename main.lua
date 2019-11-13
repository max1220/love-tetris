local flux = require("flux")
local moonshine = require("moonshine")


math.randomseed(os.time())
local scene
local gameover_scene
local tetris_scene
local function change_scene(new_scene)
	if scene and scene.unload then
		scene:unload()
	end
	if new_scene.load then
		new_scene:load()
	end
	scene = new_scene
end
function love.update(dt)
	if scene and scene.update then
		scene:update(dt)
	end
	flux.update(dt)
end
function love.draw()
	if scene and scene.draw then
		scene:draw()
	end
end
function love.load()
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




tetris_scene = {
	width = 1280,--love.graphics.getWidth(),
	height = 720,--love.graphics.getHeight(),
	block_colors = {
		[0] = {1,1,1,0.2},
		{1,1,0,1},
		{0,1,1,1},
		{1,0,0,1},
		{0,1,0,1},
		{1,0,1,1},
		{0,0,1,1}
	},

	screen_shake = 0,
	text_color_h = 0,
	text_color_l = 1,

	particles_y = 0,
	particles_visible = 0
}
local function hue2rgb(p, q, t)
	if t < 0   then t = t + 1 end
	if t > 1   then t = t - 1 end
	if t < 1/6 then return p + (q - p) * 6 * t end
	if t < 1/2 then return q end
	if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
	return p
end
local function hsl_to_rgb(h, s, l, a)
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
function tetris_scene:on_gameover()
	-- TODO
	gameover_scene.score = self.game.score
	change_scene(gameover_scene)
end
function tetris_scene:on_score(score, combo)
	self.text_color_h = 0
	self.text_color_l = 0.5
	flux.to(self, combo*2, { text_color_h=combo*2 } ):oncomplete(function() self.text_color_l = 1; self.text_color_h=0 end)
end
function tetris_scene:on_line_remove(y)
	self.particles_y = y
	self.particles_visible = 1
	--self.particle_system:start()
	flux.to(self, 0.5, {particles_visible = 0})--:oncomplete(function() self.particle_system:stop() end)
end
function tetris_scene:on_block_set(x,y,block_id)
	local orig_block_color = self.block_colors[0]
	self.block_colors[0] = {1,1,1,1}
	flux.to(self.block_colors[0], 0.1, orig_block_color)
end
function tetris_scene:draw_board()
	for y=1, self.game.board_h do
		for x=1, self.game.board_w do
			local tile_id = self.game:get_at(x,y)
			if tile_id and tile_id ~= 0 then
				love.graphics.setColor(self.block_colors[tile_id])
				love.graphics.rectangle("fill",x-1,y-1,1,1)
			else
				love.graphics.setColor(self.block_colors[0])
				love.graphics.rectangle("fill",x-1,y-1,1,1)
			end
		end
	end
end
function tetris_scene:draw_current_block()
	local block = self.game:rotate_block(self.game.blocks[self.game.block_id], self.game.block_r)
	love.graphics.setColor(self.block_colors[self.game.block_id])
	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			local sx = (self.game.block_x+x-2)
			local sy = (self.game.block_y+y-2)
			if block[y][x] ~= 0 then
				love.graphics.rectangle("fill",sx,sy,1,1)
			end
		end
	end
end
function tetris_scene:draw_ghost_block()
	local block = self.game:rotate_block(self.game.blocks[self.game.block_id], self.game.block_r)
	local min_y = self.game.block_y
	for y=self.game.block_y, self.game.board_h do
		if not self.game:check_block_at(self.game.block_x, y, self.game.block_r) then
			break
		end
		min_y = y
	end
	local c = self.block_colors[self.game.block_id]
	local r,g,b,a = c[1], c[2], c[3], 0.6
	love.graphics.setColor(r,g,b,a)
	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			local sx = (self.game.block_x+x-2)
			local sy = (min_y+y-2)
			if block[y][x] ~= 0 then
				love.graphics.rectangle("fill",sx,sy,1,1)
			end
		end
	end
end
function tetris_scene:draw_next_block()
	local block = self.game.blocks[self.game.next_block_id]

	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			if block[y][x] ~= 0 then
				love.graphics.setColor(self.block_colors[self.game.next_block_id])
				love.graphics.rectangle("fill",x-1,y-1,1,1)
			else
				love.graphics.setColor(self.block_colors[0])
				love.graphics.rectangle("fill",x-1,y-1,1,1)
			end
		end
	end
end
function tetris_scene:load()

	love.keyboard.setKeyRepeat(true)
	local major, minor = love.getVersion()
	local usedpiscale = nil
	if major >= 11 and minor >= 3 then
		usedpiscale = false
	end
	love.window.setMode(self.width, self.height, {
		vsync = true,
		resizable = true,
		fullscreen = true,
		usedpiscale = usedpiscale
	})
	--self.font = love.graphics.newFont("good_times_rg.ttf", self.height/12)
	self.font = love.graphics.newFont("dotty.ttf", self.height/8)
	self.game = require("tetris").new()
	self.game.on_gameover = function(_) self:on_gameover() end
	self.game.on_score = function(_, points, combo) self:on_score(points, combo) end
	self.game.on_line_remove = function(_, y) self:on_line_remove(y) end
	self.game.on_block_set = function(_, x,y,block_id) self:on_block_set(x,y,block_id) end
	self.game:reset()
	--pixelate

	--self.effect = moonshine(moonshine.effects.pixelate).chain(moonshine.effects.crt).chain(moonshine.effects.scanlines).chain(moonshine.effects.fastgaussianblur).chain(moonshine.effects.vignette)
	self.effect = moonshine(moonshine.effects.crt).chain(moonshine.effects.scanlines).chain(moonshine.effects.fastgaussianblur).chain(moonshine.effects.vignette)
	--self.effect = moonshine(moonshine.effects.vignette)
	--self.effect.disable("fastgaussianblur")
	--self.effect.scanlines.frequency = self.height / 4
	self.effect.scanlines.opacity = 0.2

	local canvas = love.graphics.newCanvas(8,8)
	canvas:renderTo(function()
		love.graphics.clear(0,0,0,0)
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle("fill",4,4,4)
	end)
	self.particle_system = love.graphics.newParticleSystem(canvas, 500)
	self.particle_system:setParticleLifetime(0.1,0.6)
	self.particle_system:setEmissionRate(50)
	self.particle_system:setSizes( 0.1, 0.2, 1)
	self.particle_system:setSizeVariation(0.1)
	self.particle_system:setLinearAcceleration(0, -20, 0, 20)
	self.particle_system:setColors(1,1,1,1, 1,1,1,0)
	self.particle_system:setRadialAcceleration( 15, 20 )
	self.particle_system:setSpin( -20, 20 )
	self.particle_system:setEmissionArea("uniform", self.game.board_w*0.5, 1)

	self.ambient_color = {1,1,1,1}

	self.screen_shake = -1000
	flux.to(self, 1.5, { screen_shake = 0 } )
end
function tetris_scene:update(dt)
	if self.game:update_timer(dt) then
		-- TODO: more particles
	end
	self.particle_system:update(dt)
end
function tetris_scene:draw()
	love.graphics.setColor(self.ambient_color)
	love.graphics.setFont(self.font)
	self.effect(function()
		love.graphics.clear(0.1,0.1,0.1,1)


		love.graphics.push()
		love.graphics.translate(0,self.screen_shake)

		local board_w = self.game.board_w
		local s = love.graphics.getHeight()/22

		love.graphics.push()
		love.graphics.translate(love.graphics.getWidth()*0.5-self.game.board_w*0.5*s,love.graphics.getHeight()*0.5-self.game.board_h*0.5*s)
		love.graphics.scale(s,s)

		self:draw_board()
		self:draw_current_block()
		self:draw_ghost_block()
		love.graphics.setColor(1,1,1,self.particles_visible)
		love.graphics.draw(self.particle_system,self.game.board_w*0.5, self.particles_y)
		love.graphics.setColor(1,1,1,0.1)
		love.graphics.rectangle("fill",0,self.game.board_h+1, self.game.board_w, 1)
		love.graphics.setColor(1,1,1,1)
		local b = 0.05
		love.graphics.rectangle("fill",0,self.game.board_h+1+b, (self.game.autodown_time/self.game.autodown_timeout)*(self.game.board_w-2*b), 1)

		love.graphics.pop()


		love.graphics.setColor(hsl_to_rgb(self.text_color_h%1, 1, self.text_color_l, 1))
		love.graphics.print(("Score:\n%d\nLines:\n%d\n"):format(self.game.score, self.game.lines), self.width*0.7, self.height*0.20)


		love.graphics.push()
		love.graphics.translate(self.width*0.7,self.height*0.65)
		love.graphics.scale(s,s)
		self:draw_next_block()
		love.graphics.pop()

		love.graphics.pop()
	end)
end
function tetris_scene:keypressed(key)
	if key == "left" then
		self.game:left()
	elseif key == "right" then
		self.game:right()
	elseif key == "down" then
		self.game:down()
	elseif key == "up" then
		self.game:rotate_left()
	elseif key == "q" then
		self.game:rotate_left()
	elseif key == "e" then
		self.game:rotate_right()
	elseif key == "space"  then
		self.game:drop()
		flux.to(self, 0.08, { screen_shake = 50 } ):after(0.04, {screen_shake=0})
	elseif key == "return" then
		self.game:reset()
		self.screen_shake = -1000
		flux.to(self, 0.4, { screen_shake = 0 } )
	elseif key == "escape" then
		love.window.setFullscreen(false)
	elseif key == "f11" then
		love.window.setFullscreen(true)
	end
end
function tetris_scene:mousepressed(x,y,btn)
	local x = x / self.width
	local y = y / self.height
	if y > 0.75 then
		if x > 0.5 then
			-- bottom-right
			self.game:drop()
		else
			-- bottom-left
			self.game:down()
		end
	elseif y > 0.5 then
		if x > 0.5 then
			if x > 0.75 then
				-- top right
				self.game:rotate_left()
			else
				-- top middle-right
				self.game:rotate_right()
			end
		else
			if x > 0.25 then
				-- top middle-left
				self.game:right()
			else
				-- top left
				self.game:left()
			end
		end
	end
end
function tetris_scene:resize(w,h)
	self.effect.resize(w,h)
	self.width = w
	self.height = h
	self.font = love.graphics.newFont("dotty.ttf", self.height/8)
end




gameover_scene = {}
function gameover_scene:draw()
	love.graphics.clear(0,0,0,0)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setFont(tetris_scene.font)

	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()
	local b = 0.66*w
	love.graphics.printf("GAME OVER!\nSCORE: " .. self.score .. "\n\nPress enter to start a new game!\n", w*0.5-b*0.5, h*0.2, b, "center")
end
function gameover_scene:keypressed(key)
	if key == "return" then
		tetris_scene.game:reset()
		change_scene(tetris_scene)
	end
end
function gameover_scene:mousepressed()
	tetris_scene.game:reset()
	change_scene(tetris_scene)
end
