pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- pico garden
-- by ryan nein

--[[
	TODO:
		- fix planting "used" check
]]--

debug = false

function _init()

	grid = create_board()
	
	music(0)
	-- sfx(03)

	rain_timer = flr(rnd(300))+800
	rain_duration = flr(rnd(100)+200)

	player_init()

	pets = {}
	for i=0,3 do
		make_pet()
	end

	plants = {}
	plant_types = 
	{
		{start_sprite = 32, color = 8, stages = {16, 25, 40, 60}},
		{start_sprite = 36, color = 9, stages = {20, 30, 40, 55}},
		{start_sprite = 40, color = 12, stages = {15, 30, 42, 50}},
		{start_sprite = 44, color = 7, stages = {12, 25, 30, 65}}
	}

end

function _update60()
	player_update()

	for plant in all(plants) do
		plant:update()
	end
	for pet in all(pets) do
		pet:update()
	end
end

function _draw()
	cls()
	draw_board()

	for pet in all(pets) do
		pet:draw()
	end
	for plant in all(plants) do
		plant:draw()
	end

	player_draw()

	rain()
	
	if debug then
	color(8)
		rect(player_x*8, player_y*8, player_x*8+7, player_y*8+7)
		print("steps: " .. player_steps)
		print("x: " .. player_x)
		print("y: " .. player_y)
		print("selection: " .. player_plant_selection)
		print("timer: " .. rain_timer)
		print("plants: " .. #plants)
	end
	color()
end


--player
function player_init()
	player_x = 8
	player_y = 8
	flipped = false
	spr_timer = 00
	player_plant_selection = 1
	player_steps = 0
	off_x = 0
	off_y = 0
	player_state = "choice" -- choice, move
end

function player_update()
	if player_state == "choice" then
		--movment:
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) then

			if btnp(0) and player_x>1 then
				player_x -= 1
				off_x = flipped and 8 or 0
				flipped = true
				sfx(01)
			elseif btnp(1) and player_x<14 then
				player_x += 1
				off_x = flipped and 0 or -8
				flipped = false
				sfx(01)
			elseif btnp(2) and player_y>1 then
				player_y -= 1
				off_y = 8
				sfx(01)
			elseif btnp(3) and player_y<14  then
				player_y +=1
				off_y = -8
				sfx(01)
			end

			--clamp
			player_x = mid(1, player_x, 14)
			player_y = mid(1, player_y, 14)
			

			player_steps += 1
			for plant in all(plants) do
				plant.steps += 1
			end

			player_state = "move"
		end

		-- make plant:
		if btnp(5) and grid[player_x+1][player_y+1].used == false then 
			make_plant(player_plant_selection, player_x, player_y)
			grid[player_x+1][player_y+1].used = true
			sfx(02)
		end
	end

	-- Selection change:
	if btnp(4) then 
		player_plant_selection +=1;
		if player_plant_selection > #plant_types then
			player_plant_selection = 1
		elseif player_plant_selection < 1 then
			player_plant_selection = #plant_types
		end
	end

	if off_x > 0 then
		off_x -= 1
		off_y = -1
	elseif off_x < 0 then
		off_x += 1
		off_y = -1
	elseif off_y > 0 then
		off_y -= 1
	elseif off_y < 0 then
		off_y += 1
	else
		player_state = "choice"
	end

	--animation:
	spr_timer +=1
	player_spr = spr_timer%40 > 20 and 01 or 03
	if player_state == "move" then
		player_spr = 01
	end
end

function player_draw()
	pal(2, plant_types[player_plant_selection].color)
	pal(4, 5)
	if flipped then
		spr(player_spr, (player_x)*8+off_x, (player_y-1)*8+off_y, 2, 2, flipped)
	else
		spr(player_spr, (player_x-1)*8+off_x, (player_y-1)*8+off_y, 2, 2, flipped)
	end
	pal()
end


function make_plant(_type,_x,_y)
	plant = {
		type = _type, --number to pull from table
		x = _x,
		y = _y,

		steps = 0,
		start_sprite = 32,
		sprite = 32,
		
		stage = 1, -- of stages{}
		stages = {5, 10, 15, 20}, -- stage ENDing numbers

		update = function(self)
			-- change stages
			if self.steps > self.stages[self.stage] then
				if self.stage >= #self.stages then
					grid[self.x+1][self.y+1].used = false
					del(plants, self)
				else
					self.stage += 1
				end
			end
			-- use stages to get sprite
			self.sprite = self.start_sprite + self.stage-1
		end,

		draw = function(self)
			spr(self.sprite, self.x*8, (self.y-1)*8, 1, 2)
		end
	}
	for key,value in pairs(plant_types[plant.type]) do
		plant[key] = value
	end
	add(plants, plant)
	bubble(plants)
end

function make_pet()
	local pet = {
		sprite = choose({7,8}),
		x = flr(rnd(16)),
		y = flr(rnd(16)),
		flipped = false,
		walk_alarm = 0,

		update = function(self)
			--random movment:
			self.walk_alarm-=1
			if self.walk_alarm <= 0 then
				if flr(rnd(2)) ~= 0 then -- decides if is idle
					local dir = flr(rnd(5))
					if dir == 0 then
						self.x -= 1
						self.flipped = true
					elseif dir == 1 then
						self.x += 1
						self.flipped = false
					elseif dir == 2 then
						self.y -= 1
					elseif dir == 3 then
						self.y += 1
					end
					--clamp:
					self.x = mid(0, self.x, 15)
					self.y = mid(0, self.y, 15)
				end
				self.walk_alarm = flr(rnd(20))+30 --reset alarm				
			end
		end,

		draw = function(self)
			spr(self.sprite, self.x*8, self.y*8, 1,1, self.flipped)
		end
	}
	add(pets, pet)
end


function rain()
	if rain_timer <= 0 then
		rain_timer = flr(rnd(300))+800
		rain_duration = flr(rnd(100)+200)
	elseif rain_timer <= rain_duration then
		--raining:
		for i=1,10 do
			spr(flr(rnd(3))+23,flr(rnd(128)),flr(rnd(128)))
		end
		sfx(00)
	end
	rain_timer -= 1
end
	
function choose(numbers)
	return numbers[flr(rnd(#numbers)+1)]
end

function create_board()
	local grid = {}
	for x=0, 15 do
		grid[x+1] = {}
		for y=0, 15 do
			if x>0 and y>0 and x<15 and y<15 then --middle tiles
				grid[x+1][y+1] = {used = false, spr = choose({91,92,93,94})}
			elseif y>0 and y<15 then --horizontal side tiles
				grid[x+1][y+1] = {used = true, spr = choose({75,76,77,78})}
			else 
				grid[x+1][y+1] = {used = true, spr = choose({74,88,89,89})}
			end
		end
	end
	grid[1][1].spr = 72
	grid[16][1].spr = 72
	grid[1][16].spr = 73
	grid[16][16].spr = 73
	return grid
end


function draw_board()
	for x=1, 16 do
		for y=1, 16 do
			if x>15 then
				spr(grid[x][y].spr, (x-1)*8, (y-1)*8, 1, 1, true) -- h flip
			elseif x > 1 and y > 15 and x<16 then
				spr(grid[x][y].spr, (x-1)*8, (y-1)*8, 1, 1, false, true) -- v flip
			else
				spr(grid[x][y].spr, (x-1)*8, (y-1)*8)
			end
		end
	end
end

function bubble(_list)
	repeat
	local swaps = 0
		for i=1,#_list-1 do
			if _list[i].y > _list[i+1].y then
				local dummy = _list[i]
				_list[i] = _list[i+1]
				_list[i+1] = dummy
				swaps += 1
			end
		end
	until swaps < 1
end


__gfx__
0000000000000000aaa0000000000000aaa000000000000000000000000070700000000000000000000000000000000000000000000000000000000000000000
000000000000a00aafaa0a000000000aafaa000000000000000000000000707000000aa000000000000000000000000000000000000000000000000000000000
0070070000000aaafffaa0000000a0aafffa0a000000000000000000000070700000aaa900000000000000000000000000000000000000000000000000000000
0007700000000aaafffaa00000000aaafffaaa00000000000000000000007777aaaaaaa000000000000000000000000000000000000000000000000000000000
000770000000000afffa0000000000aafffaa0000000000000000000077777770aaaaa0000000000000000000000000000000000000000000000000000000000
0070070000fff000ee00000000000000ee00000000000000000000007777777700aaaa0000000000000000000000000000000000000000000000000000000000
0000000000000fffe7e0000000000fffe7e00000000000000000000077777770000aa00000000000000000000000000000000000000000000000000000000000
00000000000000eeeefff402000ff0eeeef000000000000000000000077770700000000000000000000000000000000000000000000000000000000000000000
0000000000000e7ee702404000f00e7ee70ff4000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000
000000000000eeeeee0022420000eeeeee00404000000000000000000000000c0000000000000c00000000000000000000000000000000000000000000000000
000000000000e7ee7e04f4f40000e7ee7e02224200000000000000000c000000c0000000000000c0000000000000000000000000000000000000000000000000
0000000000000eeeee0f4f4f00000eeeee04f4f4000000000000000000c0c0000c0000000c000000000000000000000000000000000000000000000000000000
0000000000000f00f004f4f4000000f00f0f4f4f000000000000000000000c00000c000000c00000000000000000000000000000000000000000000000000000
0000000000000f00f0000000000000f00f04f4f40000000000000000000000000000c0000000c000000000000000000000000000000000000000000000000000
00000000000ff000f000000000000f00f00000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000
0000000000000000f00000000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000
000000000000000000000000000880000000000000000000000000000009000000000000000000000000000000c0000000000000000000000000000000077000
000000000000000000000000008aa800000000000000000000000000009a90000000000000000000000000000acc00000000000000000000000000000775a770
000000000000000000088000008aa800000000000000000000090000000900000000000000000000000000000ccc0000000000000000000000000700007a5700
0000000000000000000880000008800000000000000000000003000000030090000000000000000000000000000b000000000000000000000007700000077000
00000000000000000000b0000000b000000000000000000000030000000309a900000000000000000000c0000000b00000000000000000000000700000073000
00000000000000000000b0000000b0b00000000000000000000030900090339000000000000000000000b0000000b00000000000000070000000300000003000
00000000000000000000bbb000b0bbb000000000000000000000330009a9300000000000000000000000b000000bb00000000000000700000000300000003000
0000000000000b00000bbb00000bbb00000000000000300000903000009030000000000000000000000b00000b0b00b000000000000300000003000000030000
000000000000b0000000b0000000b000000000000000300000033000000330000000000000000b000b0b0bb00bbb0bb000000000000300000003000000030000
000000000000b0000000b0000000b000000000000000300000003000000030000000000000b0b00000bbbb0000bbbb0000030000000300000003000000030000
000000000000b0000000b0000000b0000000300000003000000030000000300000000000000bb000000bb000000bb00000003000000030000000300000003000
0000d0000000d000000ddd00000ddd000000d0000000d0000000300000003000000dd000000dd000000dd000000dd00000003000000030000000300000003000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbb3bbbbbb3bbb44bbbb3bbb3bb3b444b3bbb444bbbb4444bbbbb44400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbb4bbbbbb3bbbbb4b44bbb3bb44bb3bb444bbb3bb4400000000
0000000000000000000000000000000000000000000000000000000000000000b3bbbb3bbbbbb4bbb3bbbbbbbbbbb444bbbbb444bbb4b444bb3bb44400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb3bbbbbbbbbbbb3bbbb44bbbbb4b4bbbbb444bbbb444400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbb3bbbbbbb4b4b4bbbbbb4b44bbbb44443bbbbb44bbbb4b4400000000
0000000000000000000000000000000000000000000000000000000000000000b3bbbb44bbbbbbbbbb44444bbbbb4444bb3bbb44bbbb4444bbbbb44400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbb4b4bbbbbbbb44444444bb3bb444bbbb4b44bbb4b444b3bb4bb400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbb44bbbb3bbb44444444bbbbb444bbbbb444bbbbb444bbbbbb4400000000
0000000000000000000000000000000000000000000000000000000000000000bbbb3bbbbbbbbbbbbb3bbbbb4444444444444444444444444444444400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb3bbbbbbbbb4444444444444444444444444444444400000000
0000000000000000000000000000000000000000000000000000000000000000bb3bbb3bbb3bbbbbb3bbb3bb4444444444444444444444444444444400000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbb4bbbbbbbbbbbb4444454444444444444444444454445400000000
0000000000000000000000000000000000000000000000000000000000000000b4bbbb4bbbbbb4bbbb4bbb4b4544444444445444444444454444444400000000
0000000000000000000000000000000000000000000000000000000000000000bb4b44bb4b444444bbbbb44b4444444444444444454444444444444400000000
00000000000000000000000000000000000000000000000000000000000000004444b4444444444444b4b4444444444444444444444444444444444400000000
00000000000000000000000000000000000000000000000000000000000000004444444444444444444444444444444444444444444444444444444400000000
__label__
bbb3bbbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbb
b3bbbb3bbb3bbb3bbb3bbb3bbb3bbbbbbb3bbb3bb3bbbbbbbb3bbbbbb3bbbbbbbb3bbb3bbb3bbbbbbb3bbb3bbb3bbb3bbb3bbb3bbb3bbbbbbb3bbbbbb3bbbb3b
bbbbbbbbbbbbbbbbbbbbbbbbbbb4bbbbbbbbbbbbbbbbbbbbbbb4bbbbbbbbbbbbbbbbbbbbbbb4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4bbbbbbb4bbbbbbbbbbbb
bbbbbbbbb4bbbb4bb4bbbb4bbbbbb4bbb4bbbb4bb4b4b4bbbbbbb4bbb4b4b4bbb4bbbb4bbbbbb4bbb4bbbb4bb4bbbb4bb4bbbb4bbbbbb4bbbbbbb4bbbbbbbbbb
b3bbbb44bb4b44bbbb4b44bb4b444444bb4b44bbbb44444b4b444444bb44444bbb4b44bb4b444444bb4b44bbbb4b44bbbb4b44bb4b4444444b44444444bbbb3b
bbbbb4b44444b4444444b444444444444444b4444444444444444444444444444444b444444444444444b4444444b4444444b44444444444444444444b4bbbbb
bbbbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bb3bb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbb444444544454444444444444444444544454444445444454445444444444444444444444444444544454444444444444444444444444444445444444bbbb
bbbb4b44444444444444444544445444444444444544444444444444444454444444444544445444444444444444444544445444444444454544444444b4bbbb
bbbbb4444444444445444444444444444444444444444444444444444444444445444444444444444444444445444444444444444544444444444444444bbbbb
b3bb4bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb4bb3b
bbbbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbb
3bb3b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbb4b44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
b3bbbb4444444444444444444444454444444544444445444444444444444444444445444454445444544454444445444454445444444444444444444444bbbb
bbbb4b44444454444444444545444444454444444544444444444445444454444544444444444444444444444544444444444444444444454444444544b4bbbb
bbbb44444444444445444444444444444444444444444444454444444444444444444444444444444444444444444444444444444544444445444444444bbbbb
bb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb4bb3b
bbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbb
bbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bb3bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bbb4b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbb44444444444444444444444454444544454444444444444444444444544444444444444444444544454445444544444454444444444444444444444bbbb
3bbbbb44444454444444444545444444444444444444544444445444454444444444444544445444444444444444444445444444444444454444444544b4bbbb
bbbb44444444444445444444444444444444444444444444444444444444444445444444444444444444444444444444444444444544444445444444444bbbbb
bbb4b44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb4bb3b
bbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbb
b3bbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbb
bbb3bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbb
bbbbb4b44444454444444444445444544444444444444544444444444444444444544454444444444444444444444544444444444454445444444444444bbbbb
bbbb4444454444444444444544444444444454444544444444444445444444454444444444444445444454444544444444444445444444444444544444bbbbb3
bb3bbb4444444444454444444444444444444444444444444544444445444444444444444544444444444444444444444544444444444444444444444444bbbb
bbbb4b444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b3bb3
bb3bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bbb4b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb444444444444454445444444544445444544444444444444444445444544444444444444444444444444454445444544454444445444454445444bbbb3b
3bbbbb44444444454444444445444444444444444444544444445444444444444444544444445444444444454444444444444444454444444444444444b4bbbb
bbbb444445444444444444444444444444444444444444444444444444444444444444444444444445444444444444444444444444444444444444444444bbbb
bbb4b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
3bb3b4444444444444444444444444444444444444444444aaa444444444444444444444444444444747444444444444444444444444444444444444444b3bb3
bbbb4b44444444444444444444444aa4444444444444a44aafaa4a44444444444448844444444444474744444444444444444444444444444444444444b4bbbb
bbbbb44444444444444444444444aaa94444444444444aaafffaa44444444444448aa844444444444747444444444444444444444444444444444444444bbbbb
b3bbbb444444454444444444aaaaaaa44444444444444aaafffaa44444444444448aa84444444444777744444444444444444444444444444444454444bbbb3b
bbbb4b4445444444444444454aaaaa44444454444444444afffa5444444444454448844444444445777777754444444544444445444454444544444444b4bbbb
bbbb4444444444444544444444aaaa444444444445fff444ee444444454444444444b4444544444477777777454444444544444444444444444444444444bbbb
bb3bb4444444444444444444444aa4444444444444444fffe7e44444444444444444b4b4444444444777777744444444444444444444444444444444444bb3bb
bbbbb44444444444444444444444444444444444444444eeeefff5484444444444b4bbb4444444444747777444444444444444444444444444444444444bbbbb
3bb3b4444444444444444444444444444444444444444e7ee748545444444444444bbb444444444444444444444444444444444444444444444444444444bbbb
bbbb4b44444444444444444444444444444444444444eeeeee448858444444444444b444444444444444444444444444444444444444444444444444444bb3bb
bbbbb444444444444444444444444444444444444444e7ee7e45f5f5444444444444b444444444444444444444444444444444444444444444444444444b4bbb
b3bbbb444444444444444444444444444444454444444eeeee4f5f5f445444544444b444444444444444454444444444444444444444444444544454444bbbbb
bbbb4b444444444544445444444444454544444445444f44f445f5f544444444444ddd4444445444454444444444444544445444444454444444444444bbbbb3
bbbb44444544444444444444454444444444444444444f44f444444444444444444444444444444444444444454444444444444444444444444444444444bbbb
bb3bb44444444444444444444444444444444444444ff444f44444444444444444444444444444444444444444444444444444444444444444444444444b4bbb
bbbbb4444444444444444444444444444444444444444444f44444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
b3bbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbb3b
bbb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb4b444444444444444444444444444444444445444544454445444444444445444544444444444444444444444444444444444544454444445444b4bbbbb
bbbb444444444445444454444444544444445444444444444444444444444445444444444444544444444445444454444444444544444444454444444444bbbb
bb3bbb44454444444444444444444444444444444444444444444444454444444444444444444444454444444444444445444444444444444444444444bbb3bb
bbbb4b44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b3bb3
bbb3bb44444444444444444444444444444444444444444444444aa4444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bb3bb44444444444444444444444444444444444444444444444aaa94444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbb44444444454444444544444444444454445444444444aaaaaaa4444444444444444444444444445444544454445444444444444445444444454444bbbb3b
bbbb4b4445444444454444444444444544444444444454444aaaaa45444444454444444544445444444444444444444444445444454444444544444444b4bbbb
bbbbb444444444444444444445444444444444444444444445aaaa4445444444454444444444444444444444444444444444444444444444444444444444bbbb
b3bb4bb44444444444444444444444444444444444444444444aa4444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
3bb3b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbb3b
bbbb4b44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
b3bbbb4444444544444444444444444444544454444445444444444444444444445444544444444444544454444445444444444444444444444444444b4bbbbb
bbbb4b4445444444444454444444544444444444454444444444544444445444444444444444444544444444454444444444544444445444444444454444bbbb
bbbb4444444444444444444444444444444444444444444444444444444444444444444445444444444444444444444444444444444444444544444444bbb3bb
bb3bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbb3b
bbb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bbb
bb3bb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbb444444444444444445444444454444544454444444444444454444444544444445444454445444444444444444444444454444444444445444544b4bbbbb
bbbb4b4444444445454444444544444444444444444444454544444445444444454444444444444444444445444454444544444444444445444444444444bbbb
bbbbb444454444444444444444444444444444444544444444444444444444444444444444444444454444444444444444444444454444444444444444bbb3bb
b3bb4bb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bbbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
b3bbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b3bb3
bbb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb4b4445444544444454444544454444444444444454444544454444444444444444444544454444444444454445444444444445444544454445444bbbb3b
bbbb4444444444444544444444444444444444454544444444444444444454444444544444444444444444454444444444445444444444444444444444b4bbbb
bb3bbb4444444444444444444444444445444444444444444444444444444444444444444444444445444444444444444444444444444444444444444444bbbb
bbbb4b444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b3bb3
bbb3bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbbb
bb3bb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bbbb4444444445444444444444444544444444444444454444444444444444444444444444444444444444444444444444544454444444444444444444bbbb3b
bbbb4b44454444444444544445444444444454444544444444444445444454444444444544445444444444454444544444444444444454444444544444b4bbbb
bbbbb44444444444444444444444444444444444444444444544444444444444454444444444444445444444444444444444444444444444444444444444bbbb
b3bb4bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
b3bbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbb
bbb3bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bb3bb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbb
bbbbb4b44444454444444444444445444444444444444544444445444444444444444444444444444454445444444444444445444454445444544454444bbbbb
bbbb4444454444444444544445444444444444454544444445444444444454444444544444444445444444444444444545444444444444444444444444bbbbb3
bb3bbb4444444444444444444444444445444444444444444444444444444444444444444544444444444444454444444444444444444444444444444444bbbb
bbbb4b444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444b4bbb
bbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbb
bb3bbb44444444444444444444444444444444444444444444444444444444444747444444444444444444444444444444444444444444444444444444bbb3bb
bbbbbbb4444444444444444444444444444444444444b444444444444444b444474744444444b44444444444444444444444444444444444444444444bbbbbbb
bbbbb4bb4b444444bb44444b4b4444444b444444bb4b44bbbb44444bbb4b44bb47474444bb4b44bb4b4444444b444444bb44444bbb44444b4b444444bb4bbbbb
bbbb3bbbbbbbb4bbb4b4b4bbbbbbb4bbbbbbb4bbb4bbbb4bb4b4b4bbb4bbbb4b7777b4bbb4bbbb4bbbbbb4bbbbbbb4bbb4b4b4bbb4b4b4bbbbbbb4bbbbb3bbbb
b3bbbbbbbbb4bbbbbbbbbbbbbbb4bbbbbbb4bbbbbbbbbbbbbbbbbbbbbbbbbbbb7777777bbbbbbbbbbbb4bbbbbbb4bbbbbbbbbbbbbbbbbbbbbbb4bbbbbbbbbb3b
bbbbbbbbbb3bbbbbb3bbbbbbbb3bbbbbbb3bbbbbbb3bbb3bb3bbbbbbbb3bbb3b77777777bb3bbb3bbb3bbbbbbb3bbbbbb3bbbbbbb3bbbbbbbb3bbbbbbbbbbbbb
bbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3bbbbbbbbbb7777777bbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
bbbb3bbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbb7b7777bbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbbbbbbbbb3bbbb

__map__
4041414142414141424241414241414300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525152515151526161525152616300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626162616161625152626162615300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5052626151526151526162516161616300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6052516151525161626251526251525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051616161625251526161625161625300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5061626161616261515251515151515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5052516161626151616261515152515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051616252515251515151526162515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6051526162616251515252625151516300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5061625152515251616262515151516300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051515152616251526162525151516300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6051526151525161625152515251525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626251525152516162616261625300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061625161626162515151515151516300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071717271717172727271717272717300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
002200000861008600076000860008600066000660008600086000660007600076000760008600086000760008600086000860009600086000660006600086000860007600096000960007600066000860009600
000100001005000000165000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000061500f1501c1500710001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
791800000e5500e5200e5100e500135501352013510135001a5501a5201a51000000000001a5001f5501f5201f5101f5001e5501e5201e5101e50000500005001c5501c5301c5101c51021550215302151021510
911800000202002010020200201007020070100702007010020200201002020020100202002010020200201002020020100202002010020200201002020020100402004010040200401009020090100902009010
791800000c5500c5200c5100000013550135201351000000185501852018510000000000000000215502152021510000001f5501f5201e5501e5201c5501c52000000000001f5501f5301f5201f5100000000000
911800000002000010000200001007020070100702007010000200001000020000100002000010000200001009020090100902009010040200401004020040100702007010070200701007020070100702007010
__music__
01 03044644
02 05064344

