--[[
/tank/tera Ver:1.0
Written by Tankman
Contains ants
]]

local component = require("component")
local sides = require("sides")
local GUI = require("GUI")
local thread = require("thread")

local VER = 0.1
local PROG_NAME = "/tank/tera"
local reactor = component.reactor_redstone_port
local inv = component.inventory_controller
local tank = component.tank_controller
local rs = component.redstone
local cap = ""
local CSIDE = sides.east
local RSIDE = sides.down

local MAXHEAT = reactor.getMaxHeat()
local COOLMAX = 10000
local RODS = {}
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, PROG_NAME.." v:"..VER)
title.align = "left"

-----Fuel Window-----

-----Energy Window-----

-----Program Functions-----
local function checkReactor()
  local active = reactor.getReactorEUOutput()
  local heat = reactor.getHeat()
  local heatPercent = math.floor((math.min(heat, MAXHEAT) / MAXHEAT) * 100)
  local coolent = tank.getFluidInTank(CSIDE)
  local coolTank = coolent[1].amount
  local coolPercent = math.floor((math.min(coolTank, 10000) / 10000) * 100)
  local hotTank = coolent[2].amount
  local hotPercent = math.floor((math.min(hotTank, 10000) / 10000) * 100)
  return active, heat, heatPercent, coolTank, coolPercent, hotTank, hotPercent
end

local function checkEnergy()
end

local function checkFuel(rods, deep)
  if deep then
    rods = {}
    for i = 1, 54 do
      local slot = inv.getStackInSlot(CSIDE, i)
      if slot ~= nil then
        if string.find(slot.label, "Fuel") then
          rods[#rods+1] = slot
        end
      end
    end
  else
    for k, v in pairs(rods) do
      rods[k] = inv.getStackInSlot(CSIDE, k)
    end
  end
  return rods
end

-----Common Commands-----
local function close()
  rs.setOutput(RSIDE, 0)
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
  checkReactor()
  checkEnergy()
  os.sleep(0.25)
until not prog.run

-- 70% radiation
-- 85% lava