--[[
  /tank/elevator Ver:0.5
  Written by: InaccurateTank
  Contains Ants

  Elevator is a semi-dynamic program for creating multi-floor Create elevators.
  The program comes with multiple modes that are used together across multiple computers:
    control - The master control unit, sends signals to the brake units.
    brake   - Each floor contains a brake controller.  The brake controller dictates if the floor brakes are deployed based on elevator position.
    car     - Sits in the elevator car for players to request floors to travel to.
  
  All modes require access to the PMU (Persistant Memory Unit, hardwired redstone memory cell).
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

------------------
-- MAIN PROGRAM --
------------------

local GUI = require("GUI-R")

local modem = partCheck("top", "modem") or error("Computer missing top side modem.")
local monitor = partCheck("right", "monitor") or error("Computer missing right side monitor.")
local bundleSide = "left"
local doorSide = "left"
local upRS = "back"
local downRS = "right"

local mode, brakeFloor = ...
brakeFloor = tonumber(brakeFloor)
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

local function findFloor()
  for i=1, #conTab do
    if redstone.testBundledInput(bundleSide, conTab[i].color) then
      return i
    end
  end
end

-- GUI Init
local prog = GUI.init(colors.gray, monitor)
GUI.newBox(prog, 3, 2, 1, 17, colors.lightGray)
local callButton
if mode ~= "car" then
  callButton = GUI.newButton(prog, 5, 8, 9, 5, colors.lightGray, colors.black, colors.lime, colors.black, "Call")
  callButton.onPoke = function(self)
    local current = findFloor()
    if current == brakeFloor then
      redstone.setOutput(doorSide, true)
      os.sleep(1)
      redstone.setOutput(doorSide, false)
    elseif mode == "control" then
      if current > brakeFloor then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.up))
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.up))
      elseif current < brakeFloor then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.down))
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.down))
      end
    elseif mode == "brake" then
      modem.transmit(30, 30, "brake "..brakeFloor)
    end
  end
end
local elInd

local function init()
  for i=1,#conTab do
    if redstone.testBundledInput(bundleSide, conTab[i].color) then
      elInd = GUI.newBox(prog, 3, conTab[i].pos, 1, colors.white)
      prog:moveToFront(elInd)
      break
    end
  end
  for i=1,#conTab do
    GUI.newBox(prog, 2, conTab[i].pos, 1, 2, conTab[i].color)
    if mode == "car" then
      conTab[i].button = GUI.newButton(prog, 5, conTab[i].pos, 9, 2, colors.lightGray, colors.black, colors.lime, colors.black, "Floor " .. i)
      conTab[i].button.onPoke = function(self)
        modem.transmit(20, 30, "car "..i)
      end
      conTab[i].button.disabled = true
    end
  end
end

local function doorToggle()
  for i=1, #conTab do
    conTab[i].button.disabled = true
    conTab[i].button:draw()
  end
  os.sleep(2)
  for i=1, #conTab do
    conTab[i].button.disabled = false
    conTab[i].button:draw()
  end
end

local function modemListen()
  repeat
    local _, _, chan, reply, mes, _ = os.pullEvent("modem_message")
    local parsed = split(mes)
    local current = findFloor()
    if parsed[1] == "car" and mode == "control" then
      parsed[2] = tonumber(parsed[2])
      if parsed[2] == current then
        if parsed[2] == brakeFloor then
          redstone.setOutput(doorSide, true)
          os.sleep(1)
          redstone.setOutput(doorSide, false)
        else
          modem.transmit(reply, reply, "control open")
        end
      elseif parsed[2] > current then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.up))
        modem.transmit(reply, reply, "control up "..parsed[2])
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.up))
      elseif parsed[2] < current then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.down))
        modem.transmit(reply, reply, "control down "..parsed[2])
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.down))
      end
    elseif parsed[1] == "brake" and mode == "control" then
      parsed[2] = tonumber(parsed[2])
      if parsed[2] > current then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.up))
        modem.transmit(reply, reply, "control up "..parsed[2])
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.up))
      elseif parsed[2] < current then
        redstone.setBundledOutput(bundleSide, colors.combine(conTab.down))
        modem.transmit(30, 1, "control down "..parsed[2])
        os.sleep(1)
        redstone.setBundledOutput(bundleSide, colors.subtract(conTab.down))
      end
    elseif parsed[1] == "control" and mode == "brake" then
      if parsed[2] == "open" then
        redstone.setOutput(doorSide, true)
        os.sleep(1)
        redstone.setOutput(doorSide, false)
      elseif parsed[2] == "up" and parsed[3] == brakeFloor then
        parsed[3] = tonumber(parsed[3])
        redstone.setOutput(upRS, true)
        local ver = true
        while ver do
          local current = findFloor()
          if current == parsed[3] then
            ver = false
            redstone.setOutput(upRS, false)
          end
        end
      elseif parsed[2] == "down" and parsed[3] == brakeFloor then
        parsed[3] = tonumber(parsed[3])
        redstone.setOutput(downRS, true)
        local ver = true
        while ver do
          local current = findFloor()
          if current == parsed[3] then
            ver = false
            redstone.setOutput(downRS, false)
          end
        end
      end
    end
  until not prog.run
end

local function main()
  if mode == "car" then
    doorToggle()
    modem.open(20)
  else
    modem.open(20)
    modem.open(30)
  end
  repeat
    local current = findFloor()
    if brakeFloor ~= current then
      GUI.drawBox(3, elInd.y, 1, 2, colors.lightGray, monitor)
      elInd.y = conTab[current].pos
      elInd:draw()
    end
    os.sleep(0.25)
  until not prog.run
  modem.closeAll()
end

if mode == "car" then
  init()
  prog:start(main)
elseif mode == "control" or mode == "brake" then
  if brakeFloor ~= nil then
    init()
    prog:start(modemListen, main)
  else
    print("Client modes other than car require a brake floor")
  end
else
  print("Please select valid client mode")
end