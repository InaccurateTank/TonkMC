--[[
/tank/tera Ver:1.0
Written by Tankman
Contains ants
]]

local component = require("component")
local sides = require("sides")
local GUI = require("GUI")
local term = require("term")

local VER = 0.1
local PROG_NAME = "/tank/tera"
local reactor = component.reactor
local inv = component.inventorycontroller
local tank = component.tankcontroller
local rs = component.redstone
local SIDE = ""

local MAXHEAT = reactor.getMaxHeat()
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, PROG_NAME.." v:"..VER)
title.align = "left"

-----Aux Functions-----
local function checkReactor()
  local heat = reactor.getHeat()
  local active = reactor.getReactorEUOutput()
  local heatPercent = math.floor((math.min(heat, MAXHEAT) / MAXHEAT) * 100)
  local coolent = tank.getFluidInTank(SIDE)
  local coolTank = coolent[1].amount
  local hotTank = coolent[2].amount
end

local function fuelCheck()
end

-----Common Commands-----
local function close()
  prog:stop()
  term.setCursor(1, 1)
  os.exit()
end

-----Button Init-----

-----Container Events-----

prog:start()
repeat
  os.sleep(0.25)
until not prog.run

-- 70% radiation
-- 85% lava