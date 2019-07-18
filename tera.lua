--[[
/tank/tera Ver:1.0
Written by Tankman
Contains ants
]]

local component = require("component")
local sides = require("sides")
local GUI = require("GUI")
local thread = require("thread")

local ver = 0.1
local progName = "/tank/tera"
local reactor = component.reactor_redstone_port
local inv = component.inventory_controller
local tank = component.tank_controller
local rs = component.redstone
local cap = nil
local cSide = sides.east
local rSide = sides.down

local maxHeat = reactor.getMaxHeat()
local rods = {}
local overide = false
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, progName.." v:"..ver)
title.align = "left"

-----Fuel Window-----

-----Energy Window-----

-----Program Functions-----
local function checkReactor()
  local active = reactor.getReactorEUOutput()
  local heat = reactor.getHeat()
  local heatPercent = math.floor((math.min(heat, maxHeat) / maxHeat) * 100)
  local coolent = tank.getFluidInTank(cSide)
  local coolTank = coolent[1].amount
  local coolPercent = math.floor((math.min(coolTank, 10000) / 10000) * 100)
  local hotTank = coolent[2].amount
  local hotPercent = math.floor((math.min(hotTank, 10000) / 10000) * 100)
  return {active, heat, heatPercent, coolTank, coolPercent, hotTank, hotPercent}
end

local function checkEnergy()
end

local function checkFuel(rods, deep)
  if deep then
    rods = {}
    for i = 1, 54 do
      local slot = inv.getStackInSlot(cSide, i)
      if slot ~= nil then
        if string.find(slot.label, "Fuel") then
          rods[#rods+1] = slot
        end
      end
    end
  else
    for k, v in pairs(rods) do
      rods[k] = inv.getStackInSlot(cSide, k)
    end
  end
  return rods
end

local function reactorControl()
  local status = checkReactor()
  if status[1] == 0 then
    print("offline")
  else
    print("online")
  end
  if overide then
    print("SCRAM engaged")
    rs.setOutput(rSide, 0)
  end
  if status[3] >= 80 then
    print("critical temps")
    rs.setOutput(rSide, 0)
  end
  if status[3] >= 70 then
    print("radwarning")
  end
  if rods == "maxdam" then
    print("fuel depleated")
  end
end

-----Common Commands-----
local function close()
  rs.setOutput(rSide, 0)
  GUI.invertTouch(false)
  prog:stop()
  os.exit()
end

-----Button Init-----

-----Container Events-----

GUI.res(2)
GUI.invertTouch(true)
prog:start()
repeat
  reactorControl()
  checkEnergy()
  os.sleep(0.25)
until not prog.run

-- 70% radiation
-- 85% lava