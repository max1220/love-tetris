local flux = require("flux")
local moonshine = require("moonshine")

local tetris_scene = {}



function tetris_scene:on_gameover()
	-- TODO
	gameover_scene.score = self.game.score
	change_scene(gameover_scene)
end
function tetris_scene:on_score(score, combo)
	self.anim_text_color_h = 0
	self.anim_text_color_l = 0.5

	self.particle_system:setEmissionArea("uniform", self.game.board_w*0.5, combo*0.5)
	self.particle_system:start()
	self.linebreak_particles_y = self.linebreak_particles_y - combo*0.5
	flux.to(self, 0.5, {linebreak_particles_visible = 0}):oncomplete(function() self.particle_system:stop() end)

	flux.to(self, combo*2, { anim_text_color_h=combo*2 } ):oncomplete(function() self.anim_text_color_l = 1; self.anim_text_color_h=0 end)
end
function tetris_scene:on_line_remove(y)
	self.linebreak_particles_y = y
	self.linebreak_particles_visible = 1
end
function tetris_scene:on_block_set(x,y,block_id)
	self.anim_board_bg_color = {1,1,1,1}
	flux.to(self.anim_board_bg_color, 0.1, self.board_bg_color)
end
function tetris_scene:draw_tile(x,y,tile_id,color)
	if tile_id ~= 0 then
		love.graphics.setColor(color or self.block_colors[tile_id])
		love.graphics.rectangle("fill",x,y,1,1)
		love.graphics.setColor(1,1,1,0.2)
	end
end
function tetris_scene:draw_board()
	love.graphics.setColor(self.anim_board_bg_color)
	love.graphics.rectangle("fill", 0,0,self.game.board_w, self.game.board_h)
	for y=1, self.game.board_h do
		for x=1, self.game.board_w do
			local tile_id = self.game:get_at(x,y)
			self:draw_tile(x-1,y-1,tile_id)
		end
	end
	self:draw_current_block()
	self:draw_ghost_block()
end
function tetris_scene:draw_current_block()
	local block = self.game:rotate_block(self.game.blocks[self.game.block_id], self.game.block_r)
	love.graphics.setColor(self.block_colors[self.game.block_id])
	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			local sx = (self.game.block_x+x-2)
			local sy = (self.game.block_y+y-2)
			self:draw_tile(sx, sy, block[y][x])
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
	local color = {c[1], c[2], c[3], 0.6}
	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			local sx = (self.game.block_x+x-2)
			local sy = (min_y+y-2)
			self:draw_tile(sx,sy,block[y][x], color)
		end
	end
end
function tetris_scene:draw_next_block()
	local block = self.game.blocks[self.game.next_block_id]
	love.graphics.setColor(self.anim_board_bg_color)
	love.graphics.rectangle("fill",0,0,self.game.block_w,self.game.block_h)
	for y=1, self.game.block_h do
		for x=1, self.game.block_w do
			if block[y][x] ~= 0 then
				love.graphics.setColor(self.block_colors[self.game.next_block_id])
				love.graphics.rectangle("fill",x-1,y-1,1,1)
			end
		end
	end
end
function tetris_scene:draw_buttons_overlay()
	local w,h = self.width, self.height
	local wh,hh,wq,hq = w/2,h/2,w/4,h/4

	love.graphics.setColor(self.anim_button_colors[1])
	love.graphics.rectangle("fill", 0, hh, wq, hq)

	love.graphics.setColor(self.anim_button_colors[2])
	love.graphics.rectangle("fill", wq, hh, wq, hq)

	love.graphics.setColor(self.anim_button_colors[3])
	love.graphics.rectangle("fill", 2*wq, hh, wq, hq)

	love.graphics.setColor(self.anim_button_colors[4])
	love.graphics.rectangle("fill", 3*wq, hh, wq, hq)

	love.graphics.setColor(self.anim_button_colors[5])
	love.graphics.rectangle("fill", 0, hh+hq, wh, hq)

	love.graphics.setColor(self.anim_button_colors[6])
	love.graphics.rectangle("fill", wh, hh+hq, wh, hq)
end
function tetris_scene:draw_timer()
	love.graphics.setColor(self.timer_bg_color)
	love.graphics.rectangle("fill",0,self.game.board_h+1, self.game.board_w, 1)

	love.graphics.setColor(self.timer_fg_color)
	local b = 0.05
	love.graphics.rectangle("fill",0,self.game.board_h+1+b, (self.game.autodown_time/self.game.autodown_timeout)*(self.game.board_w-2*b), 1)
end
function tetris_scene:draw_particles()
	love.graphics.setColor(1,1,1,self.linebreak_particles_visible)
	love.graphics.draw(self.particle_system,self.game.board_w*0.5, self.linebreak_particles_y)
end
function tetris_scene:draw_score(max_w)
	love.graphics.setColor(hsl_to_rgb(self.anim_text_color_h%1, 1, self.anim_text_color_l, 1))
	love.graphics.printf(("Score:\n%d\nLines:\n%d\n"):format(self.game.score, self.game.lines), 0, 0, max_w, "left")
end
function tetris_scene:draw_game_wide()
	-- scale so that the entire board + 4 tiles fit in the y-axix
	local s = self.height/(self.game.board_h+4)
	love.graphics.clear(self.anim_bg_color)

	love.graphics.push()
	love.graphics.translate(self.width*0.33-self.game.board_w*0.5*s, self.height*0.5-(self.game.board_h+2)*0.5*s+self.anim_screen_shake)
	love.graphics.scale(s,s)
	self:draw_board()
	self:draw_particles()
	self:draw_timer()
	love.graphics.pop()


	love.graphics.push()
	love.graphics.translate(self.width*0.66, s+self.anim_screen_shake)
	self:draw_score(self.width*0.66, 0, self.width*0.33)
	love.graphics.translate(0, (self.height-s)*0.5)
	love.graphics.scale(s,s)
	self:draw_next_block()
	love.graphics.pop()
end
function tetris_scene:draw_game_tall()
	-- scale so that the entire board + 7 tiles fit in the x-axix
	local s = self.width/(self.game.board_w+7)
	
	if (self.game.board_h+4)*s > self.height then
		--s = self.height/(self.game.board_h+4)
	end
	
	
	love.graphics.clear(self.anim_bg_color)

	love.graphics.push()
	love.graphics.translate(s, s+self.anim_screen_shake)
	love.graphics.scale(s,s)
	self:draw_board()
	self:draw_particles()
	self:draw_timer()
	love.graphics.pop()


	love.graphics.push()
	love.graphics.translate((self.game.board_w+2)*s, s+self.anim_screen_shake)
	self:draw_score(self.width*0.66, 0, self.width*0.33)
	love.graphics.translate(0, (self.height-s)*0.5)
	love.graphics.scale(s,s)
	self:draw_next_block()
	love.graphics.pop()
end
function tetris_scene:draw_game()
	self.effect(function()
		love.graphics.push()
		if tetris_scene.screen_rotate then
			love.graphics.translate(0, self.width)
			love.graphics.rotate(math.rad(270))
		end
		if self.width>self.height then
			self:draw_game_wide()
		else
			self:draw_game_tall()
		end
		love.graphics.pop()
	end)
	love.graphics.push()
	if tetris_scene.screen_rotate then
		love.graphics.translate(0, self.width)
		love.graphics.rotate(math.rad(270))
	end
	self:draw_buttons_overlay()
	love.graphics.pop()
end

function tetris_scene:load()
	--self.font = love.graphics.newFont("good_times_rg.ttf", self.height/12)
	self.game = require("tetris").new()
	self.game.on_gameover = function(_) self:on_gameover() end
	self.game.on_score = function(_, points, combo) self:on_score(points, combo) end
	self.game.on_line_remove = function(_, y) self:on_line_remove(y) end
	self.game.on_block_set = function(_, x,y,block_id) self:on_block_set(x,y,block_id) end
	self.game:reset()
	
	self.block_colors = {
		{1,1,0,1},
		{0,1,1,1},
		{1,0,0,1},
		{0,1,0,1},
		{1,0,1,1},
		{0,0,1,1}
	}
	self.anim_button_colors = {
		{0,0,0,0},
		{0,0,0,0},
		{0,0,0,0},
		{0,0,0,0},
		{0,0,0,0},
		{0,0,0,0},
	}
	self.bg_color = {0.1, 0.1, 0.1, 1}
	self.board_bg_color = {0.3,0.3,0.3, 1}
	self.anim_board_bg_color = {0.3,0.3,0.3, 1}
	self.anim_bg_color = {0.1, 0.1, 0.1, 1}
	self.anim_screen_shake = 0
	self.anim_text_color_h = 0
	self.anim_text_color_l = 1
	self.timer_bg_color = {0.3,0.3,0.3,3}
	self.timer_fg_color = {1,1,1,1}
	self.linebreak_particles_visible = 0
	self.linebreak_particles_y = 0
	self.screen_rotate = is_phone()

	local canvas = love.graphics.newCanvas(8,8)
	canvas:renderTo(function()
		love.graphics.clear(0,0,0,0)
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle("fill",4,4,4)
	end)
	self.particle_system = love.graphics.newParticleSystem(canvas, 1500)
	self.particle_system:setParticleLifetime(0.1,0.6)
	self.particle_system:setEmissionRate(250)
	self.particle_system:setSizes( 0.1, 0.2, 0.3)
	self.particle_system:setSizeVariation(0.1)
	self.particle_system:setLinearAcceleration(0, -2, 0, 2)
	self.particle_system:setColors(1,1,1,1, 1,1,1,0)
	self.particle_system:setRadialAcceleration( 15, 20 )
	self.particle_system:setSpin( -20, 20 )
	self.particle_system:setEmissionArea("uniform", self.game.board_w*0.5, 1)

	self.ambient_color = {1,1,1,1}

	self.anim_screen_shake = -1000
	flux.to(self, 1.5, { anim_screen_shake = 0 } )

	--self.effect = moonshine(moonshine.effects.glow).chain(moonshine.effects.scanlines).chain(moonshine.effects.crt).chain(moonshine.effects.vignette)
	self.effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt).chain(moonshine.effects.vignette)
	--self.effect.glow.min_luma = 0.9
	--self.effect.glow.strength = 3

	self:resize(love.graphics.getWidth(), love.graphics.getHeight())

	self.font = love.graphics.newFont("dotty.ttf", 96)
end
function tetris_scene:update(dt)
	collectgarbage()
	if self.game:update_timer(dt) then
		-- TODO: more particles
	end
	flux.update(dt)
	self.particle_system:update(dt)
end
function tetris_scene:draw()
	love.graphics.setColor(self.ambient_color)
	love.graphics.setFont(self.font)
	
	self:draw_game()
end
function tetris_scene:keypressed(key)
	local blocked = false
	if key == "left" then
		blocked = blocked or (not self.game:left())
	elseif key == "right" then
		blocked = blocked or (not self.game:right())
	elseif key == "down" then
		blocked = blocked or (not self.game:down())
	elseif key == "up" then
		blocked = blocked or (not self.game:rotate_left())
	elseif key == "q" then
		blocked = blocked or (not self.game:rotate_left())
	elseif key == "e" then
		blocked = blocked or (not self.game:rotate_right())
	elseif key == "space"  then
		self.game:drop()
		flux.to(self, 0.08, { anim_screen_shake = 50 } ):after(0.04, {anim_screen_shake=0})
	elseif key == "return" then
		self.game:reset()
		self.anim_screen_shake = -1000
		flux.to(self, 0.4, { anim_screen_shake = 0 } )
	elseif key == "escape" then
		love.window.setFullscreen(false)
	elseif key == "f11" then
		love.window.setFullscreen(true)
	elseif key == "r" then
		self.screen_rotate = not self.screen_rotate
		love.resize(love.graphics.getWidth(), love.graphics.getHeight())
	end
	if blocked then
		self.anim_bg_color = {1,0,0,0}
		flux.to(self.anim_bg_color, 0.1, self.bg_color)
	end
end
function tetris_scene:mousepressed(x,y,btn)
	--local x = x / self.width
	--local y = y / self.height
	local x = x / love.graphics.getWidth()
	local y = y / love.graphics.getHeight()

	if self.screen_rotate then
		x,y = 1-y,x
	end

	if y > 0.75 then
		if x > 0.5 then
			-- bottom-right
			self.game:drop()
			--button_colors[6]
			self.anim_button_colors[6] = {1,1,1,0.2}
			flux.to(self.anim_button_colors[6], 1, {1,1,1,0})
		else
			-- bottom-left
			self.game:down()
			--button_colors[5]
			self.anim_button_colors[5] = {1,1,1,0.2}
			flux.to(self.anim_button_colors[5], 1, {1,1,1,0})
		end
	elseif y > 0.5 then
		if x > 0.5 then
			if x > 0.75 then
				-- top right
				self.game:rotate_left()
				self.anim_button_colors[4] = {1,1,1,0.2}
				flux.to(self.anim_button_colors[4], 1, {1,1,1,0})
			else
				-- top middle-right
				self.game:rotate_right()
				self.anim_button_colors[3] = {1,1,1,0.2}
				flux.to(self.anim_button_colors[3], 1, {1,1,1,0})
			end
		else
			if x > 0.25 then
				-- top middle-left
				self.game:right()
				self.anim_button_colors[2] = {1,1,1,0.2}
				flux.to(self.anim_button_colors[2], 1, {1,1,1,0})
			else
				-- top left
				self.game:left()
				self.anim_button_colors[1] = {1,1,1,0.2}
				flux.to(self.anim_button_colors[1], 1, {1,1,1,0})
			end
		end
	end
end
function tetris_scene:resize(w,h)
	self.effect.resize(w,h)
	self.width = w
	self.height = h
	if self.screen_rotate then
		self.width, self.height = self.height, self.width
	end
end



return tetris_scene
