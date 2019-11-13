local function new_tetris()

	local tetris = {
		board_w = board_w or 10,
		board_h = board_h or 16,
		spawn_x = spawn_x or 4,
		block_w = block_w or 4,
		block_h = block_h or 4,
		combo_scores = {[0]=0, 100, 300, 500, 800},
		blocks = blocks or {
			{
				{ 0,0,0,0 },
				{ 0,1,1,0 },
				{ 0,1,1,0 },
				{ 0,0,0,0 },
			},
			{
				{ 0,0,1,0 },
				{ 0,0,1,0 },
				{ 0,0,1,0 },
				{ 0,0,1,0 },
			},
			{
				{ 0,0,1,0 },
				{ 0,1,1,0 },
				{ 0,1,0,0 },
				{ 0,0,0,0 },
			},
			{
				{ 0,1,0,0 },
				{ 0,1,1,0 },
				{ 0,0,1,0 },
				{ 0,0,0,0 },
			},
			{
				{ 0,0,1,0 },
				{ 0,0,1,0 },
				{ 0,1,1,0 },
				{ 0,0,0,0 },
			},
			{
				{ 0,1,0,0 },
				{ 0,1,0,0 },
				{ 0,1,1,0 },
				{ 0,0,0,0 },
			},
		}
	}

	-- Rotate block right(transpose and mirror x axis)
	function tetris:rotate_block_right(block)
		local new_block = {}
		for cy=1, self.block_h do
			new_block[cy] = {}
			for cx=1, self.block_w do
				new_block[cy][cx] = block[cx][5-cy]
			end
		end
		return new_block
	end

	-- Rotate block to the specified rotation by rotating right multiple times
	function tetris:rotate_block(block, r)
		local new_block = block
		for i=1, r do
			new_block = self:rotate_block_right(new_block)
		end
		return new_block
	end

	-- remove the line at y from the table, insert a _new_line() at the top
	function tetris:remove_line(t, y)
		table.remove(t, y)
		local new_line = {}
		for i=1, self.board_w do
			new_line[i] = 0
		end
		table.insert(t, 1, new_line)
	end

	-- set the tile_id for the board at x,y (Only sets if index is valid)
	function tetris:set_at(x,y,tile_id)
		if self:get_at(x,y) then
			self.board[y][x] = tile_id
		end
	end

	-- chech if the block starting at x,y with the rotation r would collide with the walls or a block
	function tetris:check_block_at(x,y,r)
		local block = self:rotate_block(self.blocks[self.block_id], r)
		for cy=1, self.block_h do
			for cx=1, self.block_w do
				if (block[cy][cx] ~= 0) and (self:get_at(x+cx-1, y+cy-1) ~= 0) then
					return false
				end
			end
		end
		return true
	end

	-- After a block was dropped, get the next block_id, and reset the position/rotation,
	-- then check if the block fits on the board, if not sets gameover and calls :on_gameover
	function tetris:next_block()
		self.block_id = self.next_block_id
		self.next_block_id = self:random(1, #self.blocks)
		self.block_x = self.spawn_x
		self.block_y = 1
		self.block_r = 0
		if (not self:check_block_at(self.block_x, self.block_y, self.block_r)) then
			self.gameover = true
			if self.on_gameover then
				self:on_gameover()
			end
		end
	end

	-- check the board for complete lines, remove old lines, calculate new score, call :on_line_remove and :on_score
	function tetris:check_complete_lines()
		local lines = 0
		for y=1, self.board_h do
			local complete = true
			for x=1, self.board_w do
				if self.board[y][x] == 0 then
					complete = false
				end
			end
			if complete then
				lines = lines + 1
				if self.on_line_remove then
					self:on_line_remove(y)
				end
				self:remove_line(self.board, y)
			end
		end
		self.lines = self.lines + lines
		local add = self.combo_scores[lines] or 0
		self.score = self.score + add
		if add > 0 then
			if self.on_score then
				self:on_score(add, lines)
			end
		end
	end

	-- copy the block to the board at x,y
	function tetris:set_block_at(x,y, block_id, block_r)
		local block = self:rotate_block(self.blocks[block_id], block_r)
		for cy=0, self.block_h-1 do
			for cx=0, self.block_w-1 do
				if block[cy+1][cx+1] ~= 0 then
					self:set_at(x+cx, y+cy, block_id)
				end
			end
		end
	end

	function tetris:random(min, max)
		return math.random(min, max)
	end

	-- reset the game state
	function tetris:reset()
		self.block_id = self:random(1, #self.blocks)
		self.next_block_id = self:random(1, #self.blocks)
		self.block_x = self.spawn_x
		self.block_y = 1
		self.block_r = 0
		self.score = 0
		self.autodown_time = 0
		self.autodown_timeout = 2
		self.board = {}
		self.gameover = false
		self.lines = 0

		-- the board needs to be prefilled, because this determines the valid indexes
		for y=1, self.board_h do
			self.board[y] = {}
			for x=1, self.board_w do
				self.board[y][x] = 0
			end
		end
	end

	-- return the tile_id from the board at x,y (return nil if out of range)
	function tetris:get_at(x,y)
		if (x<1) or (y<1) or (x>self.board_w) or (y>self.board_h) then
			return
		end
		return self.board[y][x]
	end

	-- Check if the current tile needs to be dropped
	function tetris:update_timer(dt)
		if self.gameover then return end
		self.autodown_time = self.autodown_time + dt
		if self.autodown_time >= self.autodown_timeout then
			self:down()
			self.autodown_time = 0
			return true
		end
	end

	-- move the tile left
	function tetris:left()
		if self.gameover then return end
		if self:check_block_at(self.block_x-1, self.block_y, self.block_r) then
			self.block_x = self.block_x - 1
		end
	end

	-- move the tile right
	function tetris:right()
		if self.gameover then return end
		if self:check_block_at(self.block_x+1, self.block_y, self.block_r) then
			self.block_x = self.block_x + 1
		end
	end

	-- rotate the tile left
	function tetris:rotate_left()
		if self.gameover then return end
		local nr = (self.block_r - 1) % 4
		if self:check_block_at(self.block_x, self.block_y, nr) then
			self.block_r = nr
		end
	end

	-- rotate the tile right
	function tetris:rotate_right()
		if self.gameover then return end
		local nr = (self.block_r + 1) % 4
		if self:check_block_at(self.block_x, self.block_y, nr) then
			self.block_r = nr
		end
	end

	-- move the tile down by 1, convert it to blocks if it collides with blocks
	function tetris:down()
		if self.gameover then return end
		if self:check_block_at(self.block_x, self.block_y+1, self.block_r) then
			self.block_y = self.block_y + 1
		else
			if self.on_block_set then
				self:on_block_set(self.block_x, self.block_y, self.block_id)
			end
			self:set_block_at(self.block_x, self.block_y, self.block_id, self.block_r)
			self:check_complete_lines()
			self:next_block()
			return true
		end
		self.autodown_time = 0
	end

	-- drop the current tile to the bottom
	function tetris:drop()
		if self.gameover then return end
		while not tetris:down() do
		end
	end

	return tetris
end


return {
	new = new_tetris,
}
