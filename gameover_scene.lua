


local gameover_scene = {}
function gameover_scene:new_game()
	tetris_scene.game:reset()
	change_scene(tetris_scene)
end
function gameover_scene:draw()
	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()

	love.graphics.clear(0,0,0,0)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setFont(tetris_scene.font)

	love.graphics.push()

	local text = "GAME OVER!\nSCORE: " .. self.score .. "\n\nPress enter to start a new game!\n"
	if tetris_scene.screen_rotate then
		w,h = h,w
		love.graphics.translate(0, w)
		love.graphics.rotate(math.rad(270))
		text = "GAME OVER!\nSCORE: " .. self.score .. "\n\nTap screen to start a new game!\n"
	end
	local text_h = tetris_scene.font:getHeight()*4
	
	love.graphics.printf(text, 0, h*0.5-text_h*0.5, w, "center")

	love.graphics.pop()
end
function gameover_scene:keypressed(key)
	if key == "return" then
		self:new_game()
	end
end
function gameover_scene:mousepressed()
	self:new_game()
end
return gameover_scene
