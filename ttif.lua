--[[
ttif API Ver:1.0
Written by Tankman
Contains ants

Changelog:
  Release
]]

local serial = require("serialization")
local component = require("component")
local gpu = component.gpu

local ttif = {}

-- {width, height, mainBack, {back, x, y}, {back, x, y}}

function ttif.save(tab, width, height, path)
  local count = {}
  for p = 1, #tab do
    count[#count+1] = {tab[p].back, 1}


  end


  -- {{hex, cnt}, ...}
  table.sort(count, function(a,b) return a[2] < b[2] end)

  tab.width = width
  tab.height = height

  local file = io.open(path, "w")
  file:write(serial.serialize(tab))
  file:close()
end

function ttif.load(file)
  file = io.open(file, "r")
  local tab = serial.unserialize(file:read())
  file:close()
  return tab
end

function ttif.draw(tab, x, y)
  local currentBack = tab.mainBack
  gpu.setBackground(tab.mainBack)
  gpu.fill(x, y, tab.width, tab.height, " ")
  for p = 1, #tab do
    if currentBack ~= tab[p].back then
      currentBack = tab[p].back
      gpu.setBackground(tab[p].back)
    end
    gpu.set(x + tab[p].x - 1, y + tab[p].y - 1, " ")
  end
end

return ttif

-- ttif.save({b = "b", {1, 2}, {3, 4}, {5, 6}})
-- local out = ttif.load("/home/bigboi")

-- for v = 1, #out do
--   print(table.concat(out[v], " : "))
-- end

-- sort via count table



-- Format sorts by colors

-- Choose most common background and fill the board with it