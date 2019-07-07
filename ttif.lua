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

local function tally(t, order) -- Returns an ordered array of tables with table frequency data.  Sorts if required.
  local tmp = {}
  for i = 1, #t do
    tmp[t[i].back] = (tmp[t[i].back] or 0) + 1
  end
  local res = {}
  for k, v in pairs(tmp) do
      res[#res+1] = {k, v} -- {{hex, cnt}, ...}
  end
  if order then
    table.sort(res, order)
  end
  return res
end

function ttif.save(tab, width, height, path)
  local count = tally(tab, function(a, b) return a[2] > b[2] end)
  table.sort(tab, function(a, b)
    local c1, c2
    for i = 1, #count do
      if count[i][1] == a.back then -- Which ID does the main entry match on the hash?
        c1 = i
      end
      if count[i][1] == b.back then -- ditto
        c2 = i
      end
    end
    return c1 < c2 -- lower entries are more common
  end)
  tab.width = width
  tab.height = height
  tab.mainBack = count[1][1]
  ArrayRemove(tab, function(t, i, j)
    local v = t[i]
    return (v.back ~= count[1][1]) end)
  -- {width, height, mainBack, {back, x, y}, ...}
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