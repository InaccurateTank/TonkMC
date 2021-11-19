--[[
/tank/tera Ver:1.0
Written by Tank
Contains ants
]]

local component = require("component")
local sides = require("sides")
local GUI = require("GUI")
local thread = require("thread")

local ver = 1.0
local progName = "/tank/tera"

local reactor = component.proxy("e75b2fb8-c3c4-466c-ae7e-1d8450d6fad3")
local inv = component.proxy("001188a5-1236-436e-9838-a54943cbedc1")
local tank = component.proxy("2761ed08-1aa9-49d7-bad2-581f23794cf3")
local rs = component.proxy("a5de26a1-7e24-461d-8a15-d02ced226ece")
-- local cap = component.proxy()
local cSide = sides.east -- Reactor Tank/Inv Side
local rSide = sides.down -- Reactor Redstone Side

local rods = {}
local overide = false
local prog = GUI.manager()
prog.back = 0x000000--0xcccccc

-----Vital Functions-----
local function close(e)
  rs.setOutput(rSide, 0)
  GUI.invertTouch(false)
  prog:stop()
  if e == 1 then
    error("Reactor does not exist.  Please check the block formation for explosions.")
  end
  os.exit()
end

local function errChk(comp, func)
  if not component.get(comp.address) then -- See if the reactor even exists
    local rbuffer = rs.setOutput(rSide, 0) -- if not, shut off reactor
    -- TODO: some code to do UI stuff when this is happening
    for i = 1, 5 do -- Check if reactor exists again once per second for 5 seconds
      if component.get(comp.address) then -- IT LIVES
        if rbuffer > 0 then -- Restart reactor if it was on
          rs.setOutput(rSide, 15)
        end
        -- TODO: UI stuff
        if func then
          return func
        else
          return true
        end
      elseif i == 5 then -- Has those 5 seconds elapsed
        close(1)
        return false
      else
        os.sleep(1)
      end
    end
  else -- It always existed you dumbass
    if func then
      return func
    else
      return true
    end
  end
end

-----Main Window-----
-- local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
-- local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, progName.." v:"..ver)
-- title.align = "left"

-----Fuel Window-----

-----Energy Window-----

-----Program Functions-----
local function checkFuel(fuel, deep) -- Checks reactor fuel rods
  errChk(inv)
  if deep then -- Deep scan checks the entire reactor inventory.  Use sparingly.
    fuel = {}
    for i = 1, 54 do
      print(i)
      local slot = inv.getStackInSlot(cSide, i)
      if slot ~= nil then
        if string.find(slot.label, "Fuel") then
          fuel[i] = slot
        end
      end
    end
  else -- Quick scan checks only the slots that had rods in them last.
    for k, v in pairs(fuel) do
      print(k)
      fuel[k] = inv.getStackInSlot(cSide, k)
    end
  end
  return fuel
end

local function reactorControl(status)
  if status.active == 0 then
    print("offline")
    -- TODO: Actual UI stuff, Reactor Offline
  else
    print("online")
    -- TODO: Actual UI stuff, Reactor Online
  end
  --print(status[3])
  if overide then -- Manual shutoff
    print("SCRAM engaged") -- TODO: Actual UI stuff
    rs.setOutput(rSide, 0)
  else
    if status.heatPercent >= 80 then -- 85% is failure, we want to stop BEFORE that.
      print("critical temps") -- TODO: Actual UI stuff, Melting
      rs.setOutput(rSide, 0)
    elseif status.heatPercent >= 70 then -- 70% however is just radiation leaks.
        print("radwarning") -- TODO: Actual UI stuff, Radiation
    end
    for k, v in pairs(rods) do
      if rods[k].damage == 0 or rods == {} then
        print("fuel depleted") -- TODO: Actual UI stuff, Fuel Depleted
        -- TODO: set activator to lock until deep fuel scan
        rs.setOutput(rSide, 0)
      end
    end
  end
end

local function capControl()
  -- TODO: code to automate reactor based on cacpacitor levels
end

-----Common Commands-----

-----Button Init-----

-----Container Events-----


GUI.res(2)
GUI.invertTouch(true)
prog:start()

rods = checkFuel(rods, true)

repeat
  if errChk(reactor) then
    local h = errChk(reactor, reactor.getHeat())
    local mH = errChk(reactor, reactor.getMaxHeat())
    local t = errChk(tank, tank.getFluidInTank(cSide))
    local status = {
      active = errChk(reactor, reactor.getReactorEUOutput()),
      heat = h,
      heatPercent = math.floor((math.min(h, mH) / mH) * 100),
      coolent = t,
      coolTank = t[1].amount,
      coolPercent = math.floor((math.min(t[1].amount, 10000) / 10000) * 100),
      hotTank = t[2].amount,
      hotPercent = math.floor((math.min(t[2].amount, 10000) / 10000) * 100)
    }
    print("cycle")
    rods = checkFuel(rods)
    reactorControl(status)
    capControl()
    os.sleep(0.25)
  end
until not prog.run