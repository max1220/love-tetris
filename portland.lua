--[===================================================================[--

Portland - an orientation handling library for Android.

Copyright © 2018 Pedro Gimeno Fortea.

This file is part of the package Portland. Both copying and distribution 
of this package or parts of it are permitted, with or without 
modification, under the sole condition that any copyright notices and 
this notice are preserved. This package is offered as-is, without any 
warranty express or implied.

--]===================================================================]--

local physWidth = love.graphics.getWidth()
local physHeight = love.graphics.getHeight()

local portland = {
  accelerometer = false,
  forced = false,
  physWidth = physWidth,
  physHeight = physHeight,

  -- Time to consider the current orientation stable.
  stableTime = 0.4,

  -- Current values for tweening
  angle = 0,
  width = physWidth,
  height = physHeight,
  tweenTimer = 0,

  -- Tweening variables (old)
  oldOrient = 0,
  oldWidth = physWidth,
  oldHeight = physHeight,

  -- Tweening variables (target)
  orientation = 0,
  targetWidth = physWidth,
  targetHeight = physHeight,
  targetTime = 0,

  -- Pre-allocate space for methods, to avoid rehash
  updateOrientation = false,
  orient = false,
  setTween = false,
  easeFunc = false,
  forceOrient = false,
  ease = { linear = false, accel = false, brake = false,
           sigmoid3 = false, sigmoid5 = false }
}

-- Ease functions for tween. ease_brake or ease_sigmoid5 recommended.
function portland.ease.linear(a, b, t)
  if t < 0 then t = 0 end
  if t > 1 then t = 1 end
  return t < 0.5 and a+(b-a)*t or b+(a-b)*(1-t)
end

function portland.ease.accel(a, b, t)
  return portland.ease.linear(a, b, t*t)
end

function portland.ease.brake(a, b, t)
  return portland.ease.linear(a, b, 1-(1-t)*(1-t))
end

function portland.ease.sigmoid3(a, b, t)
  return portland.ease.linear(a, b, t*t*(3-2*t))
end

function portland.ease.sigmoid5(a, b, t)
  return portland.ease.linear(a, b, t^3*(t*(6*t-15)+10))
end

-- Sets the tween function, or false to remove tweening.
-- It also allows specifying the duration of the tween.
function portland.setTween(func, time)
  portland.easeFunc = func
  portland.targetTime = func and time or 0
  portland.tweenTimer = 0
end

-- Returns: orientation or false,
-- where orientation is one of 0, 90, 180, 270.
-- 0 is landscape, 90 is portrait,
-- 180 is landscape inverted, 270 is portrait inverted.
local function getOrientationChange()
  if portland.forced then
    return portland.orientation
  end
  if portland.accelerometer then
    local x, y, z = portland.accelerometer:getAxes()
    z = math.abs(z)
    if z < 0.9 then
      local ht = 0.4 -- horizontal threshold
      if x >  0.5 and y > -ht and y <   ht then return  90 end
      if x < -0.5 and y > -ht and y <   ht then return 270 end
      if x >  -ht and x <  ht and y >  0.5 then return   0 end
      if x >  -ht and x <  ht and y < -0.5 then return 180 end
    end
  end
  return false
end

-- Find accelerometer
if love.joystick then
  local list = love.joystick.getJoysticks()
  for i = 1, #list do
    if list[i]:getName() == 'Android Accelerometer' then
      portland.accelerometer = list[i]
      break
    end
  end
end

-- Initialize current orientation
if portland.accelerometer then
  love.event.pump()  -- without this, the initial reading is always 0
  local orientation = getOrientationChange()
  if orientation then
    portland.angle = orientation
    portland.orientation = orientation
    tentativeOrient = orientation
    portland.oldOrient = orientation
    if orientation == 90 or orientation == 270 then
      portland.width, portland.height = physHeight, physWidth
      portland.oldWidth, portland.oldHeight = portland.width, portland.height
      portland.targetWidth, portland.targetHeight = portland.width, portland.height
    end
  end
end

-- Force a specific orientation.
function portland.forceOrient(value)
  assert(value == 0 or value == 90 or value == 180 or value == 270
         or value == false)
  portland.forced = value
  if value and value ~= portland.angle then
    portland.orientation = value
    if value == 90 or value == 270 then
      portland.targetWidth, portland.targetHeight = physHeight, physWidth
    else
      portland.targetWidth, portland.targetHeight = physWidth, physHeight
    end
    portland.oldOrient = portland.angle
    portland.oldWidth = portland.width
    portland.oldHeight = portland.height
    portland.tweenTimer = portland.targetTime - portland.tweenTimer
  end
end


-- Corresponds to the last read of the accelerometer. If it persists until
-- changeOrientTimer expires, then it's taken as good and committed to
-- portland.orientation, which is the target value for tweening.
local tentativeOrient = portland.orientation
local changeOrientTimer = 0

-- This should be called from love.update to keep the orientation up-to-date.
function portland.updateOrientation(dt)
  portland.tweenTimer = portland.tweenTimer + dt
  if portland.tweenTimer > portland.targetTime then
    portland.tweenTimer = portland.targetTime
  end
  local oldOrientation = tentativeOrient
  tentativeOrient = getOrientationChange()
  if not tentativeOrient then
    changeOrientTimer = 0
    return
  end

  if tentativeOrient == oldOrientation then
    changeOrientTimer = changeOrientTimer + dt
    if changeOrientTimer > portland.stableTime and portland.orientation ~= tentativeOrient then
      -- Persisted long enough; take this orientation as good.
      portland.orientation = tentativeOrient
      if portland.orientation == 90 or portland.orientation == 270 then
        portland.targetWidth, portland.targetHeight = physHeight, physWidth
      else
        portland.targetWidth, portland.targetHeight = physWidth, physHeight
      end
      portland.tweenTimer = portland.targetTime - portland.tweenTimer
      portland.oldOrient = portland.angle
      portland.oldWidth = portland.width
      portland.oldHeight = portland.height
      if not portland.easeFunc then
        portland.angle = portland.orientation
        portland.width = portland.targetWidth
        portland.height = portland.targetHeight
      end

      if portland.onOrientationChange then
        portland.onOrientationChange(portland.orientation,
                                     portland.targetWidth,
                                     portland.targetHeight)
      end
    end
  end
end


-- This should be called from love.draw to make the appropriate transform.
function portland.orient()
  if portland.easeFunc and portland.tweenTimer < portland.targetTime then
    local t = portland.tweenTimer/portland.targetTime
    -- Use a modified old value so that it follows the shortest path when
    -- going from 0 to 270 degrees.
    local old = portland.oldOrient == 270 and portland.orientation == 0 and -90
             or portland.oldOrient == 0 and portland.orientation == 270 and 360
             or portland.oldOrient
    portland.angle = portland.easeFunc(old, portland.orientation, t)
    portland.width = portland.easeFunc(portland.oldWidth, portland.targetWidth, t)
    portland.height = portland.easeFunc(portland.oldHeight, portland.targetHeight, t)
  else
    portland.angle = portland.orientation
    portland.width = portland.targetWidth
    portland.height = portland.targetHeight
  end
  love.graphics.translate(physWidth*.5, physHeight*.5)
  love.graphics.rotate(-math.rad(portland.angle))
  love.graphics.translate(portland.width*-.5, portland.height*-.5)
end


return portland
