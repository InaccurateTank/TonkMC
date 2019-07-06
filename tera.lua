--[[
/tank/tera Ver:1.0
Written by Tankman
Contains ants
]]

local GUI = require("GUI")
local term = require("term")

local VER = 0.1
local PROG_NAME = "/tank/tera"

local prog = GUI.manager()

-----Windows-----

-----Aux Functions-----

-----Common Commands-----

-----Button Init-----

-----Container Events-----

prog:start()
repeat
  os.sleep(0.25)
until not prog.run