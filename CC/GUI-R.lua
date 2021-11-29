--[[
  GUI-R API Ver:1.0
  Written by: InaccurateTank
  Contains Ants

  The GUI-R is a pared down "Redux" of the original OpenComputers GUI API built for ComputerCraft.
  As ComputerCraft is a pain in the ass to program for, this will only be expanded when neccesary.
  Incorperates "Optimizations" because Rust ruined me.

  Changelog:
    It's new give me a fucking break
]]--

local GUI = {}
local MANAGER
local LOCATION
local SCREEN_WIDTH, SCREEN_HEIGHT
local BACKGROUND, FOREGROUND

-------------------
-- AUX FUNCTIONS --
-------------------

local function ArrayRemove(tab, fnKeep) -- Optimized table removal function ripped from https://stackoverflow.com/a/53038524
  local j = 1
  local len = #tab
  for i=1,len do
    if fnKeep(tab, i, j) then
      -- Move i's kept value to j's position, if it's not already there.
      if i ~= j then
        tab[j] = tab[i]
        tab[i] = nil
      end
      j = j + 1 -- Increment position of where we'll place the next kept value.
    else
      tab[i] = nil
    end
  end
  return tab
end

local function ArrayAdd(tab, obj, slot)
  for i = #tab, 1, -1 do
    if tab[i] == slot then
      tab[i] = obj
      return true
    else
      tab[i+1] = tab[i]
    end
  end
end

local function hitbox(obj, x, y, comp) -- Due to how often we check positions, heres a function to see if the cursor is on the object
  local result = false
  if x >= obj.x and x <= obj.x + obj.width - 1 then
    if y >= obj.y and y <= obj.y + obj.height - 1 then
      if comp then
        result = true
      end
    end
  end
  return result
end

local function textCenter(x, y, width, height, text) -- Text Centering.
  if type(text) == "table" then
    text = table.concat(text)
  end
  local center = {}
  local farX = x + width
  local farY = y + height
  if width == 0 then -- A width of 0 indicates that the text being centered is vertical.
    center = {
      x = x + math.floor((farX - x) / 2),
      y = y + math.floor((farY - y) / 2) - math.floor(#text / 2)
    }
  else
    center = {
      x = x + math.floor((farX - x) / 2) - math.floor(#text / 2),
      y = y + math.floor((farY - y) / 2)
    }
  end
  return center
end

local function getPreset(obj) -- Get color preset for objects with multiple.
  if obj.disabled then
    return obj.presets.disabled.text, obj.presets.disabled.background
  else
    if obj.pressed or obj.focus then
      return obj.presets.pressed.text, obj.presets.pressed.background
    else
      return obj.presets.default.text, obj.presets.default.background
    end
  end
end

------------------------
-- PAINTING FUNCTIONS --
------------------------

-- Sometimes you just want to draw a temporary box!
function GUI.drawBox(x, y, width, height, color, loc)
  local color = color or colors.white
  local loc = loc or term
  local reset = loc.getBackgroundColor()
  loc.setBackgroundColor(color)
  for w=1,width do
    for h=1,height do
      loc.setCursorPos(x+w-1, y+h-1)
      loc.write(" ")
    end
  end
  loc.setBackgroundColor(reset)
  loc.setCursorPos(1, 1)
end

----------------------
-- WIDGET FUNCTIONS --
----------------------

--[[
  Container Object:
    The backbone of the whole API.  Contains other GUI objects.  Can be nested infinitely.
]]--
local container = {}
container.children = {}
container.disabled = false

function container:draw()
  GUI.drawBox(self.x, self.y, self.width, self.height, self.back, LOCATION)
  if not self.disabled then
    for i=1, #self.children do
      if self.children[i].draw then
        self.children[i]:draw()
      end
    end
  end
end

function container:moveToFront(obj)
  ArrayRemove(self.children, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
  self.children[#self.children+1] = obj
end

function container:moveToBack(obj)
  ArrayRemove(self.children, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
  ArrayAdd(self.children, obj, 1)
  -- table.insert(self.children, 1, obj)
end

function container:removeEntry(obj)
  ArrayRemove(self.children, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
    return nil
end

function container:addChild(c)
  self.children[#self.children + 1] = c
end

function container:setParent(p)
  self.parent = p ~= nil and setmetatable({}, { __index = p }) or nil
  p:addChild(self)
end

function container:poke(x, y)
  if hitbox(self, x, y, not self.disabled) then
    if self.parent ~= nil and self.parent.children[#self.parent.children] ~= self then
      self.parent:moveToFront(self)
      self.parent:draw()
    end
    for i = #self.children, 1, -1 do
      if self.children[i].poke then
        if self.children[i]:poke(x, y) then break end
      end
    end
    return true
  else
    return false
  end
end

function GUI.newContainer(x, y, width, height, back, parent)
  local obj = setmetatable({}, { __index = container })
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.back = back
  if parent then
    obj:setParent(parent)
  end
  return obj
end

--[[
  Box Object:
    Essentially a wrapper around GUI.drawBox that turns it into a persistant object.
]]--
local box = {}
box.disabled = false

function box:draw()
  if not self.disabled then
    GUI.drawBox(self.x, self.y, self.width, self.height, self.back, LOCATION)
  end
end

function box:setParent(p)
  self.parent = setmetatable({}, { __index = p })
  p:addChild(self)
end

function GUI.newBox(parent, x, y, width, height, back)
  local obj = setmetatable({}, { __index = box })
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.back = back
  obj:setParent(parent)
  return obj
end

--[[
  Button Object:
    Creates a pressable button.  Button has no functionality until manually assigned.
]]--
local button = {}
button.disabled = false
button.pressed = false
button.switch = false
button.theme = ""

function button:draw()
  local center = textCenter(self.x, self.y, self.width, self.height, self.text)
  local text, back = getPreset(self)
  LOCATION.setBackgroundColor(back)
  LOCATION.setTextColor(text)
  for w=1,self.width do
    for h=1,self.height do
      LOCATION.setCursorPos(self.x+w-1, self.y+h-1)
      LOCATION.write(" ")
    end
  end
  LOCATION.setCursorPos(center.x, center.y)
  LOCATION.write(self.text)
  LOCATION.setBackgroundColor(BACKGROUND)
  LOCATION.setTextColor(FOREGROUND)
  if self.theme == "rounded" then
    LOCATION.setCursorPos(self.x, self.y)
    LOCATION.write(" ")
    LOCATION.setCursorPos(self.x + self.width - 1, self.y)
    LOCATION.write(" ")
    LOCATION.setCursorPos(self.x, self.y + self.height - 1)
    LOCATION.write(" ")
    LOCATION.setCursorPos(self.x + self.width - 1, self.y + self.height - 1)
    LOCATION.write(" ")
  end
  LOCATION.setCursorPos(1, 1)
end

function button:poke(x, y)
  if hitbox(self, x, y, not self.disabled) then
    self.pressed = not self.pressed
    self:draw()
    self.onPoke()
    if not self.switch then
      os.sleep(0.10)
      self.pressed = not self.pressed
      self:draw()
    end
    return true
  else
    return false
  end
end

function button:onPoke()
end

function button:setParent(p)
  self.parent = setmetatable({}, { __index = p })
  p:addChild(self)
end

function GUI.newButton(parent, x, y, width, height, back, fore, backPressed, forePressed, text)
  local obj = setmetatable({}, { __index = button })
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.presets = {
    default = {
      background = back,
      text = fore
    },
    pressed = {
      background = backPressed,
      text = forePressed
    },
    disabled = {
      background = colors.black,
      text = colors.white
    }
  }
  obj.text = text or ""
  obj:setParent(parent)
  return obj
end

------------------------
-- MAIN GUI FUNCTIONS --
------------------------

local function events()
  repeat
    local eD = { os.pullEvent() }
    if eD[1] == "monitor_touch" and eD[2] == peripheral.getName(LOCATION) then
      MANAGER:poke(eD[3], eD[4])
    elseif eD[1] == "mouse_click" and eD[2] == 1 and LOCATION == term then
      MANAGER:poke(eD[3], eD[4])
    end
  until not MANAGER.run
end

function GUI.init(back, loc)
  LOCATION = loc or term
  SCREEN_WIDTH, SCREEN_HEIGHT = LOCATION.getSize()
  BACKGROUND = LOCATION.getBackgroundColor()
  FOREGROUND = LOCATION.getTextColor()
  MANAGER = GUI.newContainer(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, back)
  MANAGER.run = true
  function MANAGER:start(...)
    self:draw()
    if ... then
      parallel.waitForAll(..., events)
    else
      events()
    end
  end
  function MANAGER:stop(reset)
    self.run = false
    self.disabled = true
    if reset then
      GUI.drawBox(1,1,SCREEN_WIDTH,SCREEN_HEIGHT,BACKGROUND,LOCATION)
    end
  end
  return MANAGER
end

return GUI