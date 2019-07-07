--[[
/tank/tera Ver:1.0
Written by Tankman
Contains ants
]]

local GUI = require("GUI")
local term = require("term")

local VER = 0.1
local PROG_NAME = "/tank/tera"

local reactor
local inv
local tank
local rs
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, PROG_NAME.." v:"..VER)
title.align = "left"

-----Aux Functions-----

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