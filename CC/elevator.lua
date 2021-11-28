--[[
  /tank/elevator Ver:0.5
  Written by: InaccurateTank
  Contains Ants

  Elevator is a semi-dynamic program for creating multi-floor Create elevators.
  The program comes with multiple modes that are used together across multiple computers:
    control - The master control unit, sends signals to the brake units.  Requires a PMU (Persistant Memory Unit, hardwired redstone memory cell)
    brake   - Each floor contains a brake controller.  The brake controller dictates if the floor brakes are deployed based on elevator position.  Requires access to the PMU.
    car     - Sits in the elevator car for players to request floors to travel to.
  
  The PMU is the backbone of the entire operation and stores elevator states between restarts and chunkloads.

  Changelog:
    lmao
]]--

--------------------
-- CORE FUNCTIONS --
--------------------

local function partCheck(side, type)
  if peripheral.getType(side) == type then
    return peripheral.wrap(side)
  end
end

------------------
-- MAIN PROGRAM --
------------------

local GUI = require("GUI-R")

local modem = partCheck("top", "modem") or error("Computer missing top side modem.")
local monitor = partCheck("right", "monitor") or error("Computer missing right side monitor.")
local rside = "left"

local mode, floor = ...
-- local prog = GUI.init(colors.gray, monitor)
local prog = GUI.init(colors.gray)
local conTab = {
  up = colors.white,
  down = colors.black,
  {
    color = colors.blue,
    pos = 2,
  },
  {
    color = colors.lightBlue,
    pos = 5,
  },
  {
    color = colors.yellow,
    pos = 8,
  },
  {
    color = colors.red,
    pos = 11,
  },
  {
    color = colors.green,
    pos = 14,
  },
  {
    color = colors.pink,
    pos = 17,
  }
}
GUI.newBox(prog, 3, 2, 1, 17, colors.lightGray)
local elInd

-- Init Loops
for i=1,#conTab do
  if redstone.testBundledInput(rside, conTab[i].color) then
    floor = i
    elInd = GUI.newBox(prog, 3, conTab[i].pos, 1, colors.white)
    prog:moveToFront(elInd)
    break
  end
end
for i=1,#conTab do
  GUI.newBox(prog, 2, conTab[i].pos, 1, 2, conTab[i].color)
  if mode == "car" then
    conTab[i].button = GUI.newButton(prog, 5, conTab[i].pos, 9, 2, colors.lightGray, colors.black, colors.lime, colors.black, "Floor " .. i)
    conTab[i].button.onPoke = function()
      modem.transmit(20, 21, "car "..floor.." "..i)
    end
  end
end

local function main()
  modem.open(20)
  modem.open(21)
  repeat
    for i=1, #conTab do
      if redstone.testBundledInput(rside, conTab[i].color) and floor ~= i then
        floor = i
        GUI.drawBox(3, elInd.y, 1, 2, colors.lightGray, monitor)
        elInd.y = conTab[i].pos
        elInd:draw()
      end
    end
    os.sleep(0.25)
  until not prog.run
  modem.closeAll()
end

if mode == "car" then
  prog:start( main )
else
  print("Please select client mode")
end