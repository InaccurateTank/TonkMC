--[[
GUI API Ver:2.0
Written by Tankman
Contains ants

Changelog:
  Refactor to use metatables.  Uses less memory than previous setup at the cost of call speed.
  Unicode support
  Custom key handling offloaded onto container event handlers, allowing self-contained event handing.
]]

local component = require("component")
local event = require("event")
local thread = require("thread")
local unicode = require("unicode")
local gpu = component.gpu

local GUI = {}
local SCREEN_WIDTH, SCREEN_HEIGHT = gpu.getResolution()
local BACKGROUND = gpu.getBackground()
local FOREGROUND = gpu.getForeground()

-----Aux Functions-----

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

local function splitEvery(str, n) -- String manipulation.  Splits a string every n letters.
  n = n or 1
  local result = {}
  for i = 1, unicode.len(str), n do
    local substr = unicode.sub(str, i, i + n - 1)
    result[result+1] = substr
  end
  return result
end

local function split(inputstr, sep) -- String manipulation.  This one splits strings depending on input.  Default is spaces.
  if sep == nil then
    sep = "%s"
  end
  local result={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    result[#result+1] = str
  end
  return result
end

local function textWrap(text, limit) -- Text wrapping, adapted from some place I can't remember to spit out tables.
  local result = {}
  local line = 1
  if type(text) == "string" then -- Turns strings into tables
    text = split(text, "\n")
  end
  for i = 1, #text do
    if unicode.wlen(text[i]) <= limit then
      result[line] = text[i]
      line = line + 1
    else
      local here = 1
      local function check(space, rear, word, fore)
        if fore - here > limit then
            result[line] = unicode.sub(text[i], here, rear - 1 - #space)
            here = rear
            line = line + 1
        end
      end
      text[i]:gsub("(%s*)()(%S+)()", check) -- Captures spaces, string positions, and words.  Throws results to a function and iterates.
      result[line] = unicode.sub(text[i], here)
      line = line + 1
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
      y = y + math.floor((farY - y) / 2) - math.floor(unicode.wlen(text) / 2)
    }
  else
    center = {
      x = x + math.floor((farX - x) / 2) - math.floor(unicode.wlen(text) / 2),
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

function GUI.resetBack() -- Resets colors to their pre-GUI state and clears the screen.
  gpu.setBackground(BACKGROUND)
  gpu.setForeground(FOREGROUND)
  gpu.fill(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, " ")
end

-----Container Object: Used for the GUI Manager and Windows-----

local container = {}
container.entries = {}
container.disabled = false

function container:new(x, y, width, height, back, fore)
  local obj = setmetatable({}, self)
  obj.x = x or 1
  obj.y = y or 1
  obj.width = width or SCREEN_WIDTH
  obj.height = height or SCREEN_HEIGHT
  obj.back = back or BACKGROUND
  obj.fore = fore or FOREGROUND
  self.__index = self
  return obj
end

function container:draw()
  gpu.setBackground(self.back)
  gpu.setForeground(self.fore)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
  if not self.disabled then
    for i = #self.entries, 1, -1 do
      if self.entries[i].draw and not self.entries[i].disabled then
        self.entries[i]:draw()
      end
    end
  end
end

function container:moveToFront(obj)
  ArrayRemove(self.entries, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
  self:draw()
  self.entries[#self.entries+1] = obj
end

function container:moveToBack(obj)
  ArrayRemove(self.entries, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
  table.insert(self.entries, 1, obj)
end

function container:removeEntry(obj)
  ArrayRemove(self, function(t, i, j)
    local v = t[i]
    return (v ~= obj) end)
    return nil
end

function container:customKeys(char, code, player)
end

function container:touch(x, y, button, player, con)
  if hitbox(self, x, y, not self.disabled) then
    if con ~= nil and con.entries[#con.entries] ~= self then
      con.moveToFront(self)
    end
    for i = #self.entries, 1, -1 do
      if self.entries[i].touch then
        if self.entries[i]:touch(x, y, button, player, self) then break end
      end
    end
    return true
  end
end

-- function container:drag(x, y, button, player)
--   if not self.disabled then
--     for i = #self.entries, 1, -1 do
--       if self.entries[i].drag then
--         if self.entries[i]:drag(x, y, button, player) then
--           return true
--         end
--       end
--     end
--   end
-- end

function container:scroll(x, y, dir, player, con)
  if hitbox(self, x, y, not self.disabled) then
    if con ~= nil and con.entries[#con.entries] ~= self then
      con.moveToFront(self)
    end
    for i = #self.entries, 1, -1 do
      if self.entries[i].scroll then
        if self.entries[i]:scroll(x, y, dir, player, self) then break end
      end
    end
    return true
  end
end

function container:key(char, code, player)
  if not self.disabled then
    self:customKeys(char, code, player)
    for i = #self.entries, 1, -1 do
      if self.entries[i].key then
        if self.entries[i]:key(char, code, player) then
          return true
        end
      end
    end
  end
end

--[[
Box Object
  Basically a glorified gpu.fill command.  Makes a colored box somewhere on screen.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  back               : color of the background

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
]]
local box = {}
box.disabled = false

function box:new(x, y, width, height, back)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  self.__index = self
  return obj
end

function box:draw()
  gpu.setBackground(self.back)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
end

function GUI.newBox(con, x, y, width, height, back)
  local obj = box:new(x + con.x - 1, y + con.y - 1, width, height, back)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Frame Object
  Makes a hollow box at the target point.  if not supplied with dimensions it fits itself to the container.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  back               : color of the background
  fore               : color of the foreground
  text               : text on the top of the frame

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
]]
local frame = {}
frame.disabled = false

function frame:new(x, y, width, height, back, fore, text)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.back = back
  obj.fore = fore
  obj.text = text
  self.__index = self
  return obj
end

function frame:draw()
  gpu.setBackground(self.back)
  gpu.setForeground(self.fore)
  gpu.set(self.x, self.y, "╔")
  gpu.set(self.x + self.width - 1, self.y, "╗")
  gpu.set(self.x, self.y + self.height - 1, "╚")
  gpu.set(self.x + self.width - 1, self.y + self.height - 1, "╝")
  gpu.fill(self.x + 1, self.y, self.width - 2, 1, "═")
  gpu.fill(self.x + 1, self.y + self.height - 1, self.width - 2, 1, "═")
  gpu.fill(self.x, self.y + 1, 1, self.height - 2, "║")
  gpu.fill(self.x + self.width - 1, self.y + 1, 1, self.height - 2, "║")
  if self.text then
    local center = textCenter(self.x, self.y, self.width, self.height, self.text)
    gpu.set(center.x, self.y, self.text)
  end
end

function GUI.newFrame(con, x, y, width, height, back, fore, text)
  local obj = frame:new(x + con.x - 1, y + con.y - 1, width, height, back, fore, text)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Label Objects
  Displays a string of text, with optional filler.  Comes in vertical and horizontal variants

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width/height       : width/height of the object
  back               : color of the background
  fore               : color of the foreground
  text               : text on the top of the frame
  fill               : (Optional) fill character.  defaults to " "
  fillFore          : (Optional) color of the labels fill.  defaults to white

Public Properties:
  disabled           : disabled objects are not drawn or interacted with
  align              : alignment of the text.  horizontal has left/right, vertical has top/bottom.

Public Functions:
  draw               : draws the object
]]
local label = {}
label.disabled = false
label.align = "center"

function label:new(x, y, width, back, fore, text, fill, fillFore)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.text = text
  obj.width = math.max(width, unicode.len(text))
  obj.back = back
  obj.fore = fore
  obj.fill = fill
  obj.fillFore = fillFore or obj.fore
  self.__index = self
  return obj
end

function label:draw()
  gpu.setBackground(self.back)
  if self.fill then
    gpu.setForeground(self.fillFore)
    gpu.fill(self.x, self.y, self.width, 1, self.fill)
  else
    gpu.fill(self.x, self.y, self.width, 1, " ")
  end
  gpu.setForeground(self.fore)
  if self.align == "left" then
    gpu.set(self.x, self.y, self.text)
  else
    if self.align == "right" then
      gpu.set(self.x + self.width - unicode.len(self.text), self.y, unicode.len(self.text))
    else
      local center = textCenter(self.x, self.y, self.width, 1, self.text)
      gpu.set(center.x, self.y, self.text)
    end
  end
end

function GUI.newLabel(con, x, y, width, back, fore, text, fill, fillFore)
  local obj = label:new(x + con.x - 1, y + con.y - 1, width, back, fore, text, fill, fillFore)
  con.entries[#con.entries+1] = obj
  return obj
end

-----Vertical Label-----

local vLabel = {}
vLabel.disabled = false
vLabel.align = "center"

function vLabel:new(x, y, height, back, fore, text, fill, fillFore)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.text = splitEvery(text)
  obj.height = math.max(height, #text)
  obj.back = back
  obj.fore = fore
  obj.fill = fill
  obj.fillFore = fillFore
  self.__index = self
  return obj
end

function vLabel:draw()
  gpu.setBackground(self.back)
  if self.fill then
    gpu.setForeground(self.fillFore)
    gpu.fill(self.x, self.y, 1, self.height, self.fill)
  end
  gpu.setForeground(self.fore)
  local center = textCenter(self.x, self.y, 0, self.height, self.text)
  for i = 1, #self.text do
    if self.align == "top" then
      gpu.set(self.x, self.y + i - 1, self.text[i])
    else
      if self.align == "bottom" then
        gpu.set(self.x, self.y + (self.height - #self.text) + i - 1, self.text[i])
      else
        gpu.set(self.x, center.y + i - 1, self.text[i])
      end
    end
  end
end

function GUI.newVLabel(con, x, y, height, back, fore, text, fill, fillFore)
  local obj = vLabel:new(x + con.x - 1, y + con.y - 1, height, back, fore, text, fill, fillFore)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Button Object
  Creates a pressable button.  Button function needs to be set manually.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  back               : default background color
  fore               : default text color
  backPressed        : the color that the button gets when pressed
  forePressed        : the color that the text gets when button is pressed
  text               : button text contents.  default ""

Public Properties:
  disabled           : disabled objects are not drawn or interacted with
  switch             : if true turns the button into a toggle switch
  theme              : alters the display properties of the button.  rounded culls corners

Public Functions:
  draw               : draws the object
  onTouch            : what the button does when touched.  can be replaced
]]
local button = {}
button.disabled = false
button.pressed = false
button.switch = false
button.theme = ""

function button:new(x, y, width, height, back, fore, backPressed, forePressed, text)
  local obj = setmetatable({}, self)
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
      background = 0x333333,
      text = 0xcccccc
    }
  }
  obj.text = text or ""
  self.__index = self
  return obj
end

function button:draw()
  local center = textCenter(self.x, self.y, self.width, self.height, self.text)
  local oldBack, oldFore = gpu.getBackground(), gpu.getForeground()
  local text, background = getPreset(self)
  gpu.setBackground(background)
  gpu.setForeground(text)
  if self.theme == "rounded" then
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.set(center.x, center.y, self.text)
    gpu.setBackground(oldBack)
    gpu.setForeground(oldFore)
    gpu.set(self.x, self.y, " ")
    gpu.set(self.x + self.width - 1, self.y, " ")
    gpu.set(self.x, self.y + self.height - 1, " ")
    gpu.set(self.x + self.width - 1, self.y + self.height - 1, " ")
  else
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.set(center.x, center.y, self.text)
  end
end

function button:touch(x, y, button, player, con)
  if hitbox(self, x, y, not self.disabled) then
    self.onTouch(player)
    self.pressed = not self.pressed
    if not con.disabled then
      self:draw()
    end
    if not self.switch then
      os.sleep(0.10)
      self.pressed = not self.pressed
      if not con.disabled then
        self:draw()
      end
    end
    return true
  end
end

function button:onTouch()
end

function GUI.newButton(con, x, y, width, height, back, fore, backPressed, forePressed, text)
  local obj = button:new(x, y, width, height, back, fore, backPressed, forePressed, text)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Radio Object
  Simple radio button for true-false.  More compact than a standard button.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  back               : default background color
  fore               : default text color

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
  onActive           : what the radio button does when active.  can be replaced
]]
local radio = {}
radio.disabled = false
radio.active = false

function radio:new(x, y, back, fore)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = 3
  obj.height = 1
  obj.presets = {
    default = {
      background = back,
      text = fore
    },
    disabled = {
      background = 0x333333,
      text = 0xcccccc
    }
  }
  self.__index = self
  return obj
end

function radio:draw()
  local fore, back = getPreset(self)
  gpu.setBackground(back)
  gpu.setForeground(fore)
  if self.active == false then
    gpu.set(self.x, self.y, "[ ]")
  else
    gpu.set(self.x, self.y, "[■]")
  end
end

function radio:touch(x, y, button, player, con)
  if hitbox(self, x, y, not self.disabled) then
    if self.active == false then
      self.active = not self.active
      self.onActive(player)
    else
      self.active = not self.active
    end
    self:draw()
    return true
  end
end

function radio:onActive()
end

function GUI.newRadio(con, x, y, back, fore)
  local obj = radio:new(x, y, back, fore)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Textbox Object
  Creates a scrollable box given either a string or a table of strings.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  back               : color of the background
  fore               : color of the foreground
  text               : text on the top of the frame

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
  refresh            : changes text or number values of the object
]]
local text = {}
text.disabled = false
text.yOffset = 0

function text:new(x, y, width, height, back, fore, txt)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.back = back
  obj.fore = fore
  obj.text = textWrap(txt, width)
  self.__index = self
  return obj
end

function text:draw()
  gpu.setBackground(self.back)
  gpu.setForeground(self.fore)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
  for i = 1, self.height do
    if not self.text[i + self.yOffset] then
      break
    else
      gpu.set(self.x, self.y + (i - 1), self.text[i + self.yOffset])
    end
  end
end

function text:refresh(text)
  self.text = textWrap(text, self.width)
  if not self.disabled then
    self:draw()
  end
end

function text:scrollCheck()
  if self.yOffset < #self.text - self.height then
    return true
  else
    return false
  end
end

function GUI.newText(con, x, y, width, height, back, fore, txt)
  local obj = text:new(x + con.x - 1, y + con.y - 1, width, height, back, fore, txt)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Progress Bar Object
  Creates a bar that fills based on the percentage of two numbers.

Parameters:
  container          : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  inactive           : color of non-filled area
  active             : color of filled area
  current            : current integer value
  max                : maximum integer value
  thin               : (Optional) if the bar should be a thin line or not
  vert               : (Optional) if the bar should be vertical or not

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
  refresh            : changes text or number values of the object
]]--
local pbar = {}
pbar.disabled = false

function pbar:new(x, y, width, height, inactive, active, current, max, thin, vert)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.inactive = inactive
  obj.active = active
  obj.current = current or 0
  obj.max = max or 100
  obj.thin = thin or false
  obj.vert = vert or false
  self.__index = self
  return obj
end

function pbar:draw()
  if not self.vert then
    local active = math.floor(math.min(self.current, self.max) / self.max * self.width)
    if self.thin then
      gpu.setForeground(self.inactive)
      gpu.fill(self.x, self.y, self.width, self.height, "━")
      gpu.setForeground(self.active)
      gpu.fill(self.x, self.y, active, self.height, "━")
    else
      gpu.setBackground(self.inactive)
      gpu.setForeground(self.active)
      gpu.fill(self.x, self.y, self.width, self.height, " ")
      gpu.fill(self.x, self.y, active, self.height, "█")
    end
  else
    local active = math.floor(math.min(self.current, self.max) / self.max * self.height)
    if self.thin then
      gpu.setForeground(self.inactive)
      gpu.fill(self.x, self.y, self.width, self.height, "│")
      gpu.setForeground(self.active)
      gpu.fill(self.x, self.y, self.width, active, "│")
    else
      gpu.setBackground(self.inactive)
      gpu.setForeground(self.active)
      gpu.fill(self.x, self.y, self.width, self.height, " ")
      gpu.fill(self.x, self.y + (self.height - active), self.width, active, "█")
    end
  end
end

function pbar:refresh(current)
  self.current = current
  if not self.disabled then
    self:draw()
  end
end

function GUI.newBar(con, x, y, width, height, inactive, active, current, max, thin, vert)
  local obj = pbar:new(x + con.x - 1, y + con.y - 1, width, height, inactive, active, current, max, thin, vert)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Input Object
  Text input box with primative wrapping function.  Supports most basic inputs.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  back               : color of the background
  fore               : color of the foreground
  idleBack           : selected background color
  idleFore           : selected foreground color
  cursorBack         : background color used for the cursor
  placeText          : (Optional) text to show if the box has nothing in it.
  placeColor         : (Optional) color of placeText

Public Properties:
  disabled           : disabled objects are not drawn or interacted with
  mask               : determines if the input box should hide its input, useful for passwords.  default false
  autoWrap           : determines if the object should use a primative wrapping function.  default false

Public Functions:
  draw               : draws the object
  onReturn           : input enter key functionality, can be replaced
]]--
local function getLine(input)
  return input.cursor.y - input.y + input.yOffset + 1
end

local function getLetter(input)
  return input.cursor.x - input.x + input.xOffset + 1
end

local function lineShift(tab, line, letter, dir)
  local result = {}
  if dir == -1 then -- Enter
    local i = 1
    repeat
      if i ~= line then
        result[#result + 1] = tab[i]
      else
        result[#result + 1] = unicode.sub(tab[line], 1, letter - 1) or ""
        result[#result + 1] = unicode.sub(tab[line], letter) or ""
      end
      i = i + 1
    until(i > #tab)
  elseif dir == 1 then -- Delete
    local i = 1
    repeat
      if i ~= line - 1 then
        result[#result + 1] = tab[i] or ""
        i = i + 1
      else
        result[#result + 1] = tab[i] .. unicode.sub(tab[line], letter) or ""
        i = i + 2
      end
    until(i > #tab)
  end
  return result
end

local input = {}
input.disabled = false
input.text = {}
input.xOffset = 0
input.yOffset = 0
input.focus = false
input.mask = false
input.autoWrap = false

function input:new(x, y, width, height, back, fore, idleBack, idleFore, cursorBack, placeText, placeColor)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.presets = {
    default = {
      background = idleBack,
      text = idleFore
    },
    pressed = {
      background = back,
      text = fore
    },
    disabled = {
      background = 0x333333,
      text = 0xcccccc
    }
  }
  obj.cursorBack = cursorBack or idleBack
  obj.placeText = placeText or ""
  obj.placeColor = placeColor or 0x333333
  obj.cursor = {
    x = obj.x,
    y = obj.y,
  }
  self.__index = self
  return obj
end

function input:draw()
  local text, background = getPreset(self)
  gpu.setBackground(background)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
  if #self.text <= 1 and (self.text[1] == "" or self.text[1] == nil) then
    gpu.setForeground(self.placeColor)
    gpu.set(self.x, self.y, self.placeText)
  else
    gpu.setForeground(text)
    for i = 1, self.height do
      if not self.text[i + self.yOffset] then
        break
      else
        if self.mask then
          gpu.set(self.x, self.y + (i - 1), string.rep("*", unicode.len(self.text[i + self.yOffset])))
        else
          gpu.set(self.x, self.y + (i - 1), unicode.sub(self.text[i + self.yOffset], 1 + self.xOffset, self.width + self.xOffset))
        end
      end
    end
    if self.focus then
      local char = gpu.get(self.cursor.x, self.cursor.y)
      gpu.setBackground(self.cursorBack)
      gpu.set(self.cursor.x, self.cursor.y, char)
    end
  end
end

function input:touch(x, y, button, player, con)
  if hitbox(self, x, y, not self.disabled) then
    con:moveToFront(self)
    self.focus = true
    -- Cursor position logic
    if not self.text[y - self.y + self.yOffset + 1] then
        self.cursor.y = self.y + #self.text
    else
      self.cursor.y = y
    end
    local line = getLine(self)
    if not self.text[line] or self.text[line] == "" then
      self.cursor.x = self.x
      self.xOffset = 0
    elseif x + self.xOffset > self.x + unicode.len(self.text[line]) then
      self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line]))
      self.xOffset = math.max(0, unicode.len(self.text[line]) - self.width + 1)
    else
      self.cursor.x = x
    end
    self:draw()
    return true
  elseif not self.disabled then
    if self.focus then
      con:moveToBack(self)
      self.focus = false
      self:draw()
    end
    return false
  end
end

function input:key(char, code, player)
  if self.focus then
    local line = getLine(self)
    local letter = getLetter(self)
    if char == 13 then -- Enter
      self:onReturn(player)
    elseif char == 8 then -- Delete
      if letter == 1 and line ~= 1 then
        self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line - 1]))
        self.xOffset = math.max(0, unicode.len(self.text[line - 1]) - self.width + 1)
        if self.cursor.y + 1 > self.y and self.yOffset > 0 then
          self.yOffset = self.yOffset - 1
        elseif line ~= 1 then
          self.cursor.y = self.cursor.y - 1
        end
        self.text = lineShift(self.text, line, letter, 1)
      elseif letter ~= 1 then
        self.text[line] = unicode.sub(self.text[line], 1, letter - 2) .. unicode.sub(self.text[line], letter)
        if self.xOffset > 0 then
          self.xOffset = self.xOffset - 1
        elseif self.cursor.x ~= self.x  then
          self.cursor.x = self.cursor.x - 1
        end
      end
    elseif char > 31 and char < 128 or char == 9 then -- Characters
      self.text[line] = self.text[line] or ""
      if char == 9 then
        char = "  "
      else
        char = string.char(char)
      end
      if self.autoWrap and unicode.len(self.text[line]) + unicode.len(char) > self.width - 1 then
        if char:find("%s") then
          self.text = lineShift(self.text, line, letter, -1)
        else
          self.text[line] = unicode.sub(self.text[line], 1, letter - 1) .. char .. unicode.sub(self.text[line], letter)
          self.text = textWrap(self.text, self.width-1)
        end
        self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line+1]))
        if self.cursor.y + 1 > self.y + self.height - 1 then
          self.yOffset = self.yOffset + 1
        else
          self.cursor.y = self.cursor.y + 1
        end
      else
        if not self.text[line] or self.text[line] == "" then
          self.text[line] = char
        else
          self.text[line] = unicode.sub(self.text[line], 1, letter - 1) .. char .. unicode.sub(self.text[line], letter)
        end
        if unicode.len(self.text[line]) >= self.width then
          self.xOffset = self.xOffset + unicode.len(char)
        else
          self.cursor.x = self.cursor.x + unicode.len(char)
        end
      end
    else -- Arrow Keys
      if code == 203 then -- Left
        if self.cursor.x > self.x then
          self.cursor.x = self.cursor.x - 1
        elseif self.cursor.x == self.x and self.xOffset > 0 then
          self.xOffset = self.xOffset - 1
        end
      end
      if code == 205 then -- Right
        if self.cursor.x < self.x + self.width - 1 and letter <= unicode.len(self.text[line]) then
          self.cursor.x = self.cursor.x + 1
        elseif self.cursor.x == self.x + self.width - 1 and letter <= unicode.len(self.text[line]) then
          self.xOffset = self.xOffset + 1
        end
      end
      if code == 200 then -- Up
        if self.cursor.y + 1 > self.y and self.yOffset > 0 then
          self.yOffset = self.yOffset - 1
        elseif line ~= 1 then
          self.cursor.y = self.cursor.y - 1
        end
        if not self.text[line-1] or self.text[line-1] == "" then
          self.cursor.x = self.x
          self.xOffset = 0
        elseif self.cursor.x + self.xOffset > self.x + unicode.len(self.text[line-1]) then
          self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line-1]))
          self.xOffset = math.max(0, unicode.len(self.text[line-1]) - self.width + 1)
        end
      end
      if code == 208 then -- Down
        if self.cursor.y + 1 > self.y + self.height - 1 and self.yOffset < #self.text - self.height then
          self.yOffset = self.yOffset + 1
        elseif self.cursor.y + 1 <= self.y + self.height - 1 and self.text[line+1]then
          self.cursor.y = self.cursor.y + 1
        end
        if not self.text[line+1] then
          self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line]))
          self.xOffset = math.max(0, unicode.len(self.text[line]) - self.width + 1)
        elseif self.text[line+1] == "" then
          self.cursor.x = self.x
          self.xOffset = 0
        elseif self.cursor.x + self.xOffset > self.x + unicode.len(self.text[line+1]) then
          self.cursor.x = math.min(self.x + self.width - 1, self.x + unicode.len(self.text[line+1]))
          self.xOffset = math.max(0, unicode.len(self.text[line+1]) - self.width + 1)
        end
      end
    end
    self:draw()
    return true
  end
end

function input:onReturn(player) -- By default this simply moves text around like a word processor, but it can be overwritten.
  local line = getLine(self)
  local letter = getLetter(self)
  self.cursor.x = self.x
  self.xOffset = 0
  if self.cursor.y + 1 > self.y + self.height - 1 then
    self.yOffset = self.yOffset + 1
  else
    self.cursor.y = self.cursor.y + 1
  end
  self.text = lineShift(self.text, line, letter, -1)
end

function input:scrollCheck()
  if self.yOffset < #self.text - self.height then
    return true
  else
    return false
  end
end

function GUI.newInput(con, x, y, width, height, back, fore, idleBack, idleFore, cursorBack, placeText, placeColor)
  local obj = input:new(x, y, width, height, back, fore, idleBack, idleFore, cursorBack, placeText, placeColor)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
List Object
  Creates an interactable list of items.  For non-interactable lists use the text box.

Parameters:
  con                : container that the object belongs to
  x                  : x axis position relative to the container
  y                  : y axis position relative to the container
  width              : width of the object
  height             : height of the object
  sep                : seperator between text
  back               : color of the background
  fore               : color of the foreground
  selectBack         : selected background color
  selectFore         : selected foreground color
  altBack            : (Optional) color used for alternating entries.
  altFore            : (Optional) text color used for alternating entries.

Public Properties:
  disabled           : disabled objects are not drawn or interacted with
  align              : alignment of text.  left/center/right
  confirm            : used for pseudo-switches

Public Functions:
  draw               : draws the object
  newEntry           : creates a new sub-item from inputs text and func.  func is used as the action on press.
  clearEntries       : clears the entries table allowing for more iterating.
]]--
local list = {}
list.entries = {}
list.disabled = false
list.yOffset = 0
list.align = "center"
list.selected = 0
list.confirm = 0

function list:new(x, y, width, height, sep, back, fore, selectBack, selectFore, altBack, altFore)
  local obj = setmetatable({}, self)
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.presets = {
    default = {
      background = back,
      text = fore
    },
    alt = {
      background = altBack or back,
      text = altFore or fore
    },
    select = {
      background = selectBack,
      text = selectFore
    },
    disabled = {
      background = 0x333333,
      text = 0xcccccc
    }
  }
  obj.sep = sep
  self.__index = self
  return obj
end

function list:draw()
  local inc = (self.sep * 2 + 1)
  local back, text, altBack, altText
  if self.disabled then
    back = self.presets.disabled.background
    text = self.presets.disabled.text
    altBack = self.presets.disabled.background
    altText = self.presets.disabled.text
  elseif (1 + self.yOffset) % 2 ~= 0 then
    back = self.presets.default.background
    text = self.presets.default.text
    altBack = self.presets.alt.background
    altText = self.presets.alt.text
  else
    back = self.presets.alt.background
    text = self.presets.alt.text
    altBack = self.presets.default.background
    altText = self.presets.default.text
  end
  gpu.setBackground(back)
  gpu.setForeground(text)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
  for i = 1, self.height / inc, 2 do -- first draw pass
    if not self.entries[i+self.yOffset] then
      break
    else
      local center = textCenter(self.x, self.y + inc * (i - 1), self.width, inc, self.entries[i+self.yOffset].text)
      if i + self.yOffset == self.selected then -- selected detector
        gpu.setBackground(self.presets.select.background)
        gpu.setForeground(self.presets.select.text)
        gpu.fill(self.x, self.y + inc * (i - 1), self.width, inc, " ")
        if unicode.len(self.entries[i+self.yOffset].text) > self.width then
          gpu.set(self.x, center.y, unicode.sub(self.entries[i+self.yOffset].text, 1, self.width - 2).."..")
        elseif self.align == "left" then
          gpu.set(self.x, center.y, self.entries[i+self.yOffset].text)
        elseif self.align == "right" then
          gpu.set(self.x + self.width - unicode.len(self.entries[i+self.yOffset].text), center.y, self.entries[i+self.yOffset].text)
        else
          gpu.set(center.x, center.y, self.entries[i+self.yOffset].text)
        end
        gpu.setBackground(back)
        gpu.setForeground(text)
      else
        if unicode.len(self.entries[i+self.yOffset].text) > self.width then
          gpu.set(self.x, center.y, unicode.sub(self.entries[i+self.yOffset].text, 1, self.width - 2).."..")
        elseif self.align == "left" then
          gpu.set(self.x, center.y, self.entries[i+self.yOffset].text)
        elseif self.align == "right" then
          gpu.set(self.x + self.width - unicode.len(self.entries[i+self.yOffset].text), center.y, self.entries[i+self.yOffset].text)
        else
          gpu.set(center.x, center.y, self.entries[i+self.yOffset].text)
        end
      end
    end
  end
  gpu.setBackground(altBack)
  gpu.setForeground(altText)
  for i = 2, self.height / inc, 2 do -- second draw pass
    if not self.entries[i+self.yOffset] then
      break
    else
      local center = textCenter(self.x, self.y + inc * (i - 1), self.width, inc, self.entries[i+self.yOffset].text)
      if i + self.yOffset == self.selected then -- selected detector
        gpu.setBackground(self.presets.select.background)
        gpu.setForeground(self.presets.select.text)
        gpu.fill(self.x, self.y + inc * (i - 1), self.width, inc, " ")
        if unicode.len(self.entries[i+self.yOffset].text) > self.width then
          gpu.set(self.x, center.y, unicode.sub(self.entries[i+self.yOffset].text, 1, self.width - 2).."..")
        elseif self.align == "left" then
          gpu.set(self.x, center.y, self.entries[i+self.yOffset].text)
        elseif self.align == "right" then
          gpu.set(self.x + self.width - unicode.len(self.entries[i+self.yOffset].text), center.y, self.entries[i+self.yOffset].text)
        else
          gpu.set(center.x, center.y, self.entries[i+self.yOffset].text)
        end
        gpu.setBackground(altBack)
        gpu.setForeground(altText)
      else
        gpu.fill(self.x, self.y + inc * (i - 1), self.width, inc, " ")
        if unicode.len(self.entries[i+self.yOffset].text) > self.width then
          gpu.set(self.x, center.y, unicode.sub(self.entries[i+self.yOffset].text, 1, self.width - 2).."..")
        elseif self.align == "left" then
          gpu.set(self.x, center.y, self.entries[i+self.yOffset].text)
        elseif self.align == "right" then
          gpu.set(self.x + self.width - unicode.len(self.entries[i+self.yOffset].text), center.y, self.entries[i+self.yOffset].text)
        else
          gpu.set(center.x, center.y, self.entries[i+self.yOffset].text)
        end
      end
    end
  end
end

function list:touch(x, y, button, player, con)
  if hitbox(self, x, y, not self.disabled) then
      local id = math.ceil((y - self.y + 1) / (self.sep * 2 + 1))+self.yOffset
      self.selected = id
      self.entries[id].onPress(id, player)
      self:draw()
      return true
  end
end

function list:scrollCheck()
  if self.yOffset < #self.entries - self.height / (self.sep * 2 + 1) then
    return true
  else
    return false
  end
end

function list:newEntry(text, func)
  local sub = {}
  sub.text = text
  sub.onPress = func
  self.entries[#self.entries + 1] = sub
end

function list:clearEntries()
  self.entries = {}
  self.selected = 0
  self.confirm = 0
  self.yOffset = 0
end

function GUI.newList(con, x, y, width, height, sep, back, fore, selectBack, selectFore, altBack, altFore)
  local obj = list:new(x, y, width, height, sep, back, fore, selectBack, selectFore, altBack, altFore)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
Scrollbar Object
  Activates scrolling functionality of relivent objects (See: Textbox, Input, List)

Parameters:
  con                : container that the object belongs to
  tether             : object that the scrollbar is tethered to
  back               : main background color
  fore               : main foreground color
  backPressed        : backround color of pressed buttons
  forePressed        : text color of the pressed buttons

Public Properties:
  disabled           : disabled objects are not drawn or interacted with

Public Functions:
  draw               : draws the object
]]--
local scroll = {}

function scroll:new(tether, back, fore, backPressed, forePressed)
  local obj = setmetatable({}, self)
  obj.x = tether.x + tether.width
  obj.y = tether.y
  obj.width = 1
  obj.height = tether.height
  obj.back = back
  obj.fore = fore
  obj.tether = tether
  obj.upButton = button:new(obj.x, obj.y, 1, 1, back, fore, backPressed, forePressed, "▲")
  obj.upButton.disabled = true
  obj.downButton = button:new(obj.x, obj.y + obj.height - 1, 1, 1, back, fore, backPressed, forePressed, "▼")
  function obj.upButton:onTouch()
    if obj.tether.yOffset ~= 0 then
      obj.tether.yOffset = obj.tether.yOffset - 1
      obj.tether:draw()
      obj:refresh()
      obj:draw()
      return true
    end
  end
  function obj.downButton:onTouch()
    if obj.tether:scrollCheck() then
      obj.tether.yOffset = obj.tether.yOffset + 1
      obj.tether:draw()
      obj:refresh()
      obj:draw()
      return true
    end
  end
  self.__index = self
  return obj
end

function scroll:refresh()
  if self.tether.yOffset == 0 then
    self.upButton.disabled = true
  else
    self.upButton.disabled = false
  end
  if not self.tether:scrollCheck() then
    self.downButton.disabled = true
  else
    self.downButton.disabled = false
  end
end

function scroll:draw()
  gpu.setBackground(self.back)
  gpu.fill(self.x, self.y, self.width, self.height, " ")
  self.upButton:draw()
  self.downButton:draw()
end

function scroll:touch(x, y, button, player, con)
  if self.upButton:touch(x, y, button, player, con) or self.downButton:touch(x, y, button, player, con) then
    return true
  end
end

function scroll:scroll(x, y, dir, player, con)
  if hitbox(self.tether, x, y, not self.tether.disabled) then
    if dir == -1 then
      if self.tether:scrollCheck() then
        self.tether.yOffset = self.tether.yOffset + 1
        self.tether:draw()
      end
    elseif self.tether.yOffset ~= 0 then
      self.tether.yOffset = self.tether.yOffset - 1
      self.tether:draw()
    end
    self:refresh()
    self:draw()
    return true
  end
end

function GUI.newScroll(con, tether, back, fore, backPressed, forePressed)
  local obj = scroll:new(tether, back, fore, backPressed, forePressed)
  con.entries[#con.entries+1] = obj
  return obj
end

--[[
GUI Manager
  The main controller of the GUI.  Essentially a beefed up Window object.  Only one of these is needed per program.

Parameters:
  back
  fore

Public Properties:
  disabled
  customKeys

Public Functions:
  draw
  moveToFront/Back
  add/removeEntry
  start             : Initiates event handler and draws the whole GUI.
  stop              : Completely culls event handler and resets screen.
  togglePause       : Temporarily pauses event handler and disables GUI.
]]
local function eventThread(tab)
  local r = true
  while r do
    local name, _, a1, a2, a3, a4 = event.pullMultiple("touch", "scroll", "key_down")
    if name == "touch" then
      tab:touch(a1, a2, a3, a4)
    -- elseif name == "drag" then
    --   tab:drag(a1, a2, a3, a4)
    elseif name == "scroll" then
      tab:scroll(a1, a2, a3, a4)
    elseif name == "key_down" then
      tab:key(a1, a2, a3)
    end
  end
end

function GUI.manager(run, back, fore)
  local manager = container:new(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, back or BACKGROUND, fore or FOREGROUND)
  local t
  function manager:start()
    t = thread.create(eventThread, self)
    self:draw()
  end
  function manager:togglePause()
    if self.disabled == false then
      t:suspend()
      self.disabled = not self.disabled
    else
      self.disabled = not self.disabled
      t:resume()
      self:draw()
    end
  end
  function manager:stop()
    run = false
    t:kill()
    GUI.resetBack()
  end
  return manager
end


--[[
Window
  Simple container for objects with a background.

Parameters:
  x
  y
  width
  height
  back
  fore

Public Properties:
  disabled
  customKeys

Public Functions:
  draw
  moveToFront/Back
]]
function GUI.newWindow(con, x, y, width, height, back, fore)
  local obj = container:new(x + con.x - 1, y + con.y - 1, width, height, back, fore)
  con.entries[#con.entries+1] = obj
  return obj
end


return GUI
