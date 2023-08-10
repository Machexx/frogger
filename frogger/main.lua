local libquadtastic = require("libquadtastic")

io.stdout:setvbuf("no")

local is_dead = false


local spritesheet

local raw_quads

local quads

lane_height = 60
local car_positions = {} 
local frogs = {}

local logs = {
  [6] = {
    {size = "small", x = 0},
    {size = "large", x = 240},
    {size = "small", x = 500},
  },
  [7] = {
    {size = "small", x = 0},
    {size = "small", x = 240},
    {size = "large", x = 500},
  },
  [8] = {
    {size = "large", x = 0},
    {size = "small", x = 240},
    {size = "large", x = 500},
  },
}

local level = 1
local cooldown_dead1 = 0
local cooldown_dead2 = 0

function set_lives()
  lives_frog1 = 3
  lives_frog2 = 3
end

function whenfrogdead1()
  lives_frog1 = lives_frog1 - 1
  cooldown_dead1 = 1.5
end

function whenfrogdead2()
  lives_frog2 = lives_frog2 - 1
  cooldown_dead2 = 1.5
end

function reset_pos_frog1()
  local frog_pos = {x = 300, y = lane_position(0) + lane_height/2}
  frogs[1] = frog_pos
end

function reset_pos_frog2()
  local frog_pos = {x = 500, y = lane_position(0) + lane_height/2}
  frogs[2] = frog_pos
end

function where_is_frog(frog_index)
  return (600 - (frogs[frog_index].y + lane_height/2)) / lane_height
end


function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  spritesheet = love.graphics.newImage('graphics/sprites.png')
  local sheet_w, sheet_h = spritesheet:getWidth(), spritesheet:getHeight()
  raw_quads = require("graphics/sprites")
  quads = libquadtastic.create_quads(raw_quads, sheet_w, sheet_h)

  for lane = 1, 4 do
    local cars_in_lane = {} 
    for car_index=1,4 do
      table.insert(cars_in_lane, car_index * 190)
    end
    table.insert(car_positions, cars_in_lane)
  end

  for lane_index,cars_in_lane in ipairs(car_positions) do
    print("cars of lane: " .. lane_index)
    for car_index,car_pos in ipairs(cars_in_lane) do
      print("car ".. car_index .. " is at x position " .. car_pos)
    end
  end
reset_pos_frog1()
reset_pos_frog2()
set_lives()
end

function lane_position(lane_index)
  return 600 - lane_height - lane_height * lane_index
end

function love.draw()

  local window_width = 800
  draw_background("grass", 0, lane_position(0), window_width)

  love.graphics.setColor(190, 0, 150)

  draw_background("grass", 0, lane_position(5), window_width)
  draw_background("river", 0, lane_position(6), window_width)
  draw_background("river", 0, lane_position(7), window_width)
  draw_background("river", 0, lane_position(8), window_width)
  draw_background("grass", 0, lane_position(9), window_width)

  for lane_index=6, 8 do
    for log_index=1,#logs[lane_index] do
      local log = logs[lane_index][log_index]
      draw_log(lane_index, log)
    end
  end

  for lane_index,cars_in_lane in ipairs(car_positions) do
    draw_background("street", 0, lane_position(lane_index), window_width)
  end

  for frog_index=1, #frogs do
    local frog_pos =  frogs[frog_index]
    love.graphics.setColor(0,200, 50)
    draw_frog(frog_pos.x, frog_pos.y, frog_index)
    
  end

  if cooldown_dead1 > 0 then
    draw_dead_frog(frogs[1].x, frogs[1].y, 1)
  end

  if cooldown_dead2 > 0 then
    draw_dead_frog(frogs[2].x, frogs[2].y, 2)
  end

  for lane_index,cars_in_lane in ipairs(car_positions) do
    for car_index, car_pos in ipairs(cars_in_lane) do
      draw_car(car_pos, lane_position(lane_index) + 10)
      
    end
  end

  love.graphics.setColor(0, 0, 0)
  love.graphics.print(lives_frog1, 40, 15, 0, 3, 3)
  love.graphics.setColor(237, 177, 38)
  love.graphics.print(lives_frog2, 750, 15, 0, 3, 3)

  love.graphics.setColor(237, 59, 38)
  if lives_frog1 == 0 and lives_frog2 == 0 then
    love.graphics.print("GAME OVER", 250, 106, 0, 4, 4)  
    love.graphics.print("press space to restart", 255, 166, 0, 2, 2)
  end

love.graphics.setColor(78, 36, 115)
love.graphics.print("LEVEL  ".. level, 330, 15, 0, 3, 3)

end

local cooldown = 0
local cooldown_frog2 = 0

function lane_speed(lane_index)
  local multiplier = 0.1
  if lane_index == 1 then return 0.2 + level * multiplier
  elseif lane_index == 2 then return 0.3 + level * multiplier
  elseif lane_index == 3 then return 0.4 + level * multiplier
  elseif lane_index == 4 then return 0.1 + level * multiplier
  elseif lane_index == 6 then return 0.2 + level * multiplier
  elseif lane_index == 7 then return -0.3 - level * multiplier
  elseif lane_index == 8 then return 0.1 + level * multiplier
  end
end

function love.update(dt)
  is_dead = false


  if cooldown_dead1 > 0 then
    cooldown_dead1 = cooldown_dead1 - dt
    if  cooldown_dead1 <= 0 then reset_pos_frog1() end
  end
  
  if cooldown_dead2 > 0 then
    cooldown_dead2 = cooldown_dead2 - dt
    if cooldown_dead2 <= 0 then reset_pos_frog2() end
  end

  for lane_index=6, 8 do
    local logs_in_lane = logs[lane_index]
    for log_index, log in ipairs(logs_in_lane) do
      log.x = log.x + lane_speed(lane_index)
      if lane_speed(lane_index) > 0 then
        if log.x > 800 then log.x = -raw_quads.logs.large.w * 2
        end
      else 
        if log.x < -raw_quads.logs.large.w * 2 then log.x = 800 end
      end
    end
  end

  for lane_index, cars_in_lane in ipairs(car_positions) do
    for car_index, car_pos in ipairs(cars_in_lane) do
      car_pos = car_pos + lane_speed(lane_index)
      if car_pos > 800 then
        car_pos = -60
      end
      cars_in_lane[car_index] = car_pos

      
      local rect_car = {
        x = car_pos,
        y = lane_position(lane_index) + 10, 
        w = 60,
        h = 40,
      }
      for frog_index = 1, #frogs do
        local frog_pos = frogs[frog_index]
        
        local rect_frog = {
          x = frog_pos.x - 20,
          y = frog_pos.y - 20,
          w = 40,
          h = 40,
        }

        if collision_check(rect_car, rect_frog) then
          is_dead = true
          if frog_index == 1 and cooldown_dead1 <= 0 then 
            whenfrogdead1()
          end
          if frog_index == 2 and cooldown_dead2 <= 0 then
            whenfrogdead2()
          end
        end
      end
    end
  end

  if drown_check(1) and cooldown_dead1 <= 0 then whenfrogdead1() end
  if drown_check(2) and cooldown_dead2 <= 0 then whenfrogdead2() end

  if cooldown > 0 then
    cooldown = cooldown - dt
  end

  if cooldown_frog2 > 0 then
    cooldown_frog2 = cooldown_frog2 - dt
  end

  local jump_length = lane_height

  local frog_pos = frogs[1]

  if lives_frog1 > 0 and cooldown_dead1 <= 0 then
    local is_left_down = love.keyboard.isDown("left")
    if is_left_down and cooldown <= 0 and frog_pos.x >= 5 then
      frog_pos.x = frog_pos.x  - jump_length
      cooldown = 0.15
    end

    local is_right_down = love.keyboard.isDown("right")
    if is_right_down and cooldown <= 0 and frog_pos.x <= 775 then
      frog_pos.x = frog_pos.x  + jump_length
      cooldown = 0.15
    end

    local is_up_down = love.keyboard.isDown("up")
    if is_up_down and cooldown <= 0 and frog_pos.y > lane_height/2 then
      frog_pos.y = frog_pos.y  - jump_length
      cooldown = 0.15
    end

    local is_down_down = love.keyboard.isDown("down")
    if is_down_down and cooldown <= 0 and frog_pos.y < 600-lane_height/2 then
      frog_pos.y = frog_pos.y  + jump_length
      cooldown = 0.15
    end
  end
  local frog_pos = frogs[2]

  if lives_frog2 > 0 and cooldown_dead2 <= 0 then
    local is_a_down = love.keyboard.isDown("a")
    if is_a_down and cooldown_frog2 <= 0 and frog_pos.x >= 60 then
      frog_pos.x = frog_pos.x  - jump_length
      cooldown_frog2 = 0.15
    end

    local is_d_down = love.keyboard.isDown("d")
    if is_d_down and cooldown_frog2 <= 0 and frog_pos.x <= 775 then
      frog_pos.x = frog_pos.x  + jump_length
      cooldown_frog2 = 0.15
    end

    local is_w_down = love.keyboard.isDown("w")
    if is_w_down and cooldown_frog2 <= 0 and frog_pos.y > lane_height/2 then
      frog_pos.y = frog_pos.y  - jump_length
      cooldown_frog2 = 0.15
    end

    local is_s_down = love.keyboard.isDown("s")
    if is_s_down and cooldown_frog2 <= 0 and frog_pos.y < 600-lane_height/2 then
      frog_pos.y = frog_pos.y  + jump_length
      cooldown_frog2 = 0.15
    end
  end

  if lives_frog1 == 0 and lives_frog2 == 0 and love.keyboard.isDown("space")
    then set_lives()
    level = 1
  end

  if lives_frog1 > 0 and lives_frog2 > 0 and
     where_is_frog(1) == 9 and where_is_frog(2) == 9 then
     next_level()
  elseif lives_frog1 > 0 and lives_frog2 == 0 and where_is_frog(1) == 9 then
     next_level()
  elseif lives_frog2 > 0 and lives_frog1 == 0 and where_is_frog(2) == 9 then
     next_level()
  end

end

function draw_car(pos_x, pos_y)
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(spritesheet, quads.car, pos_x, pos_y, 0, 2, 2)
end

function draw_log(lane_index, log)
  love.graphics.setColor(255, 255, 255)
  local pos_y = lane_position(lane_index) + (lane_height - 40) / 2
  love.graphics.draw(spritesheet, quads.logs[log.size], log.x, pos_y, 0, 2, 2)
end

function draw_frog(pos_x, pos_y, frog_index)
  love.graphics.setColor(255, 255, 255)
  pos_x = pos_x - raw_quads.froggos[frog_index].w
  pos_y = pos_y - raw_quads.froggos[frog_index].h
  love.graphics.draw(spritesheet, quads.froggos[frog_index], pos_x, pos_y, 0, 2, 2)
end

function draw_dead_frog(pos_x, pos_y, dead_index)
  love.graphics.setColor(255, 255, 255)
  pos_x = pos_x - raw_quads.froggos[dead_index].w
  pos_y = pos_y - raw_quads.froggos[dead_index].h
  love.graphics.draw(spritesheet, quads.dead[dead_index], pos_x, pos_y, 0, 2, 2)
end

function draw_background(type, pos_x, pos_y, lane_width)
  love.graphics.setColor(255, 255, 255)
  local tile_width = raw_quads[type].w

  local tiles = (lane_width/2) / tile_width
  for i=0,tiles - 1 do
    love.graphics.draw(spritesheet, quads[type],
                       pos_x + i * 2 * tile_width, pos_y, 0, 2, 2)
  end
end

function collision_check(r1, r2)
  local r1_x_end = r1.x + r1.w
  local r1_y_end = r1.y + r1.h
  local r2_x_end = r2.x + r2.w
  local r2_y_end = r2.y + r2.h

  local x_overlaps = r1_x_end >= r2.x and r1.x <= r2.x or
        r2_x_end >= r1.x and r2.x <= r1.x
  local y_overlaps = r1_y_end >= r2.y and r1.y <= r2.y or
        r2_y_end >= r1.y and r2.y <= r1.y

  if  x_overlaps and y_overlaps then
    return true
  end
end

function frog_on_log(r1, p1)
  if p1.x >= r1.x and p1.x <= r1.x + r1.w 
     and p1.y >= r1.y and p1.y <= r1.y + r1.h then
    return true
  end
end

function drown_check(frog_index)

  local frog_lane = where_is_frog(frog_index)
  if frog_lane == 6 or frog_lane == 7 or frog_lane == 8 then
    for log_index=1, #logs[frog_lane] do
      local log = logs[frog_lane][log_index]
      local rect_log = {
        x = log.x,
        y = lane_position(frog_lane),
        w = raw_quads.logs[log.size].w * 2,
        h = raw_quads.logs[log.size].h * 2,
      }
      if frog_on_log(rect_log, frogs[frog_index]) then
        frogs[frog_index].x = frogs[frog_index].x + lane_speed(frog_lane)
        return false
      end
    end
    return true
  end
end

function next_level()
  reset_pos_frog1()
  reset_pos_frog2()
  level = level + 1
end
