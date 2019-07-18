--[[
/tank/crawl Ver:2.1
Written by Tankman
Contains ants

Changelog:
  Use GUI.res
  Removed term and commands
]]

local event = require("event")
local GUI = require("GUI")
local fs = require("filesystem")

local ver = 2.1
local progName = "/tank/crawl"
local edit = "edit" -- Edit program used

local fspath = "//home/" -- Default file path
local copybuffer = {} -- [1] 1 is copy, 2 is paste.  [2] File Path for copying.
local delconf = false -- Confirmation for deleting files
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, progName.." v:"..ver)
title.align = "left"

GUI.newLabel(prog, 3, 3, 17, prog.back, 0x000000, "[Folder Path]", "-", 0x000000)
local dirList = GUI.newList(prog, 3, 4, 16, 19, 0, 0x333399, 0xffffff, 0x9933cc, 0xffffff)
dirList.align = "left"
local dirScroll = GUI.newScroll(prog, dirList, 0x333399, 0xffffff, 0x5599ff, 0xffffff)

GUI.newLabel(prog, 64, 3, 15, prog.back, 0x000000, "[Type]", "-", 0x000000)
local typeLabel = GUI.newLabel(prog, 64, 4, 15, prog.back, 0x000000, "")
typeLabel.align = "left"
GUI.newLabel(prog, 64, 6, 15, prog.back, 0x000000, "[Last Mod]", "-", 0x000000)
local modLabel = GUI.newLabel(prog, 64, 7, 15, prog.back, 0x000000, "")
modLabel.align = "left"
GUI.newLabel(prog, 64, 9, 15, prog.back, 0x000000, "[Notifications]", "-", 0x000000)
local notes = GUI.newText(prog, 64, 10, 15, 6, 0x333399, 0xffffff, "")

local fileList = GUI.newList(prog, 21, 3, 41, 20, 0, 0x333399, 0xffffff, 0x9933cc, 0xffffff)
fileList.align = "left"
local fileScroll = GUI.newScroll(prog, fileList, 0x333399, 0xffffff, 0x5599ff, 0xffffff)

local manInput = GUI.newInput(prog, 3, 24, 76, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc, "Manual Commands Here", 0xffffff)
manInput.onReturn = function()
end

local newButton = GUI.newButton(prog, 64, 17, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "(N)ew: ")
local delButton = GUI.newButton(prog, 64, 18, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "(Del)ete:")
local runButton = GUI.newButton(prog, 64, 19, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "(R)un: ")
runButton.disabled = true
local editButton = GUI.newButton(prog, 64, 20, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "(E)dit:")
editButton.disabled = true
local copyButton = GUI.newButton(prog, 64, 21, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "Copy:")
copyButton.switch = true
copyButton.disabled = true
local cutButton = GUI.newButton(prog, 64, 22, 15, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "Cut: ")
cutButton.switch = true
cutButton.disabled = true

-----New File Window-----
local newGUI = GUI.newWindow(prog, 21, 3, 42, 20, 0xcccccc, 0x000000)
newGUI.disabled = true

GUI.newLabel(newGUI, 1, 1, newGUI.width, 0x333399, 0xffffff, "Create New...")
GUI.newLabel(newGUI, 2, 3, 1, newGUI.back, 0x000000, "Path:")
GUI.newLabel(newGUI, 2, 5, 1, newGUI.back, 0x000000, "Name:")
local folderInput = GUI.newInput(newGUI, 7, 3, 35, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc)
local nameInput = GUI.newInput(newGUI, 7, 5, 35, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc)
function folderInput:onReturn()
  folderInput.focus = false
  nameInput.focus = true
  folderInput:draw()
  nameInput:draw()
end
function nameInput:onReturn()
  nameInput.focus = false
  nameInput:draw()
end
GUI.newLabel(newGUI, 1, 7, newGUI.width, prog.back, 0x000000, "[Type (1-4)]", "-", 0x000000)
GUI.newLabel(newGUI, 2, 9, 1, newGUI.back, 0x000000, "Folder:")
local folderRadio = GUI.newRadio(newGUI, 10, 9, newGUI.back, 0x000000)
GUI.newLabel(newGUI, 2, 11, 1, newGUI.back, 0x000000, ".txt:")
local txtRadio = GUI.newRadio(newGUI, 10, 11, newGUI.back, 0x000000)
GUI.newLabel(newGUI, 2, 13, 1, newGUI.back, 0x000000, ".lua:")
local luaRadio = GUI.newRadio(newGUI, 10, 13, newGUI.back, 0x000000)
GUI.newLabel(newGUI, 2, 15, 1, newGUI.back, 0x000000, "None:")
local naRadio = GUI.newRadio(newGUI, 10, 15, newGUI.back, 0x000000)
local confirmButton = GUI.newButton(newGUI, 2, 19, 10, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "Confirm:")
local cancelButton = GUI.newButton(newGUI, 31, 19, 11, 1, 0x333399, 0xffffff, 0xffffff, 0x000000, "(C)ancel:")

-----Program Functions-----
local function treeUpdate(path) -- returns two tables, one of the file path and another of the folder contents.
  local folder = {}
  local files = {}
  if fspath ~= "//" then
    table.insert(folder, "...")
  end
  for file in fs.list(path) do
    if fs.isDirectory(path..file) then
      table.insert(folder, file)
    else
      table.insert(files, file)
    end
  end
  table.sort(files, function(a, b) return string.lower(a) < string.lower(b) end)
  table.sort(folder, function(a, b) return string.lower(a) < string.lower(b) end)
  for i = 1, #files do
    folder[#folder + 1] = files[i]
  end
  local pathtab = {}
  pathtab[1] = "//"
  for k, v in pairs(fs.segments(path)) do
    pathtab[#pathtab+1] = v.."/"
  end
  return folder, pathtab
end

local function treeDown(path)
  path = path:match("(.+/).-/$") -- Captures the file path before the last /
  return path
end

local function treeUp(path, folder)
  path = path..folder
  return path
end

local function fixName(name)
  local i = 0
  local old = name
  while true do
    if (fs.exists(name)) then
      i = i + 1
      name = old.."("..i..")"
    else
      break
    end
  end
  return name
end

local function appendName(name) -- takes file path, appends a number if neccesary
  local dir, n1, n2 = name:match("(.-)([^/]-)%.?([^%./]-)$") -- seperate components
  local i = 0
  if not n1 then -- does the file lack an extension
    local old = n2
    while true do
      if fs.exists(name) then
        i = i + 1
        name = dir..old.."("..i..")" -- concat new path
      else
        break -- exits if doesn't exist
      end
    end
  else
    local old = n1
    while true do
      if fs.exists(name) then
        i = i + 1
        name = dir..old.."("..i..")".."."..n2
      else
        break
      end
    end
  end
  return name
end

local function buttonManager(type)
  if type == "Folder" then
    runButton.disabled = true
    editButton.disabled = true
    if not (copyButton.disabled == false and copyButton.pressed == true) then
      copyButton.disabled = true
    end
    if not (cutButton.disabled == false and cutButton.pressed == true) then
      cutButton.disabled = true
    end
  elseif type == "Program" then
    runButton.disabled = false
    editButton.disabled = false
    copyButton.disabled = false
    cutButton.disabled = false
  elseif type == "Text File" then
    runButton.disabled = true
    editButton.disabled = false
    copyButton.disabled = false
    cutButton.disabled = false
  end
  runButton:draw()
  editButton:draw()
  copyButton:draw()
  cutButton:draw()
end

local function listPopulate()
  local folder, pathtab = treeUpdate(fspath)
  fileList:clearEntries()
  dirList:clearEntries()
  for i = 1, #folder do
    fileList:newEntry(folder[i], function(id)
      if fileList.entries[id].text == "..." then
        if fileList.confirm == id then
          fspath = treeDown(fspath)
          typeLabel.text = "Folder"
          listPopulate()
        else
          typeLabel.text = ""
          modLabel.text = ""
          typeLabel.text = "Folder"
          buttonManager(typeLabel.text)
          fileList.confirm = id
        end
      else
        if fs.isDirectory(fspath..fileList.entries[id].text) then
          if fileList.confirm == id then
            fspath = treeUp(fspath, fileList.entries[id].text)
            typeLabel.text = "Folder"
            listPopulate()
          else
            typeLabel.text = "Folder"
            buttonManager(typeLabel.text)
            fileList.confirm = id
          end
        elseif fileList.entries[id].text:find(".txt$") then
          typeLabel.text = "Text File"
          buttonManager(typeLabel.text)
          fileList.confirm = id
        else
          typeLabel.text = "Program"
          buttonManager(typeLabel.text)
          fileList.confirm = id
        end
        if fs.lastModified(fspath..fileList.entries[id].text) ~= 0 then
          local mod = tonumber(string.sub(fs.lastModified(fspath..fileList.entries[id].text), 1, -4) + (-8 * 3600))
          modLabel.text = os.date("%y/%m/%d %R", mod)
        else
          modLabel.text = "NaN"
        end
      end
      typeLabel:draw()
      modLabel:draw()
    end)
  end
  for i = 1, #pathtab do
    dirList:newEntry(pathtab[i], function(id)
      if dirList.confirm == id then
        fspath = table.concat(pathtab, "", 1, id)
        listPopulate()
      else
        dirList.confirm = id
      end
    end)
  end
  fileList.selected = 1
  fileList.entries[1].onPress(1)
  fileList:draw()
  fileScroll:draw()
  dirList:draw()
  dirScroll:draw()
end

-----Common Commands-----
local function close()
  prog:stop()
  os.exit()
end

local function delete()
  if not delconf then
    delconf = true
    notes:refresh("Are you sure you want to delete that?")
    event.timer(2, function()
      delconf = false
      notes:refresh("")
    end)
  else
    delconf = false
    notes:refresh("")
    fs.remove(fspath..fileList.entries[fileList.selected].text)
    listPopulate()
  end
end

local function run()
  GUI.resetBack()
  prog.togglePause()
  os.execute(fspath..fileList.entries[fileList.selected].text.." \""..(manInput.text[1] or "").."\"")
  prog.togglePause()
  prog:draw()
end

local function edit()
  GUI.resetBack()
  prog.togglePause()
  os.execute(edit.." \""..fspath..fileList.entries[fileList.selected].text.."\"")
  prog.togglePause()
  prog:draw()
end

local function copy()
  if not copybuffer[1] then
    copybuffer[1] = 1
    copybuffer[2] = fspath..fileList.entries[fileList.selected].text
    notes:refresh("File path copied to buffer")
  end
end

local function cut()
  if not copybuffer[1] then
    copybuffer[1] = 2
    copybuffer[2] = fspath..fileList.entries[fileList.selected].text
    notes:refresh("File path copied to buffer")
  end
end

local function paste()
  if copybuffer[1] == 1 then
    fs.copy(copybuffer[2], appendName(fspath..copybuffer[2]:match("([^/]-)$")))
    notes:refresh("File pasted")
    listPopulate()
    copybuffer = {}
    if editButton.disabled then
      copyButton.disabled = true
      copyButton:draw()
    end
  elseif copybuffer[1] == 2 then
    if fs.exists(fspath..copybuffer[2]:match("([^/]-)$")) then
      notes:refresh("Filename already taken at location")
      if cutButton.pressed == false then
        cutButton.pressed = true
      end
    else
      fs.copy(copybuffer[2], appendName(fspath..copybuffer[2]:match("([^/]-)$")))
      fs.remove(copybuffer[2])
      notes:refresh("File pasted")
      listPopulate()
      copybuffer = {}
      if editButton.disabled then
        cutButton.disabled = true
        cutButton:draw()
      end
    end
  end
end

local function new()
  -- fileList.disabled = true
  dirList.disabled = true
  newGUI.disabled = false
  folderInput.text[1] = fspath
  newGUI:moveToFront(folderInput)
  folderInput.focus = true
  folderInput.cursor.x = #folderInput.text[1] + folderInput.x
  prog:moveToFront(newGUI)
  newGUI:draw()
end

local function confirm()
  if folderRadio.active then
    if fs.exists(folderInput.text[1]..nameInput.text[1]) then
      notes:refresh("Folder Already Exists")
    else
      fs.makeDirectory(folderInput.text[1]..nameInput.text[1].."/")
    end
  elseif txtRadio.active then
    local _ = fs.open(folderInput.text[1]..appendName(nameInput.text[1])..".txt", "w")
    _:close()
  elseif luaRadio.active then
    local _ = fs.open(folderInput.text[1]..appendName(nameInput.text[1])..".lua", "w")
    _:close()
  elseif naRadio.active then
    local _ = fs.open(folderInput.text[1]..appendName(nameInput.text[1]), "w")
    _:close()
  end
  folderInput.text = {}
  nameInput.text = {}
  folderRadio.active = false
  txtRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  -- fileList.disabled = false
  dirList.disabled = false
  newGUI.disabled = true
  listPopulate()
end

-----Button Init-----
function exit:onTouch()
  close()
end

function newButton:onTouch()
  new()
end

function folderRadio:onActive()
  txtRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  txtRadio:draw()
  luaRadio:draw()
  naRadio:draw()
end
function txtRadio:onActive()
  folderRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  folderRadio:draw()
  luaRadio:draw()
  naRadio:draw()
end
function luaRadio:onActive()
  txtRadio.active = false
  folderRadio.active = false
  naRadio.active = false
  txtRadio:draw()
  folderRadio:draw()
  naRadio:draw()
end
function naRadio:onActive()
  txtRadio.active = false
  luaRadio.active = false
  folderRadio.active = false
  txtRadio:draw()
  luaRadio:draw()
  folderRadio:draw()
end

function cancelButton:onTouch()
  folderInput.text = {}
  nameInput.text = {}
  folderRadio.active = false
  txtRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  -- fileList.disabled = false
  dirList.disabled = false
  newGUI.disabled = true
  fileList:draw()
  fileScroll:draw()
end
function confirmButton:onTouch()
  confirm()
end
function delButton:onTouch()
  delete()
end
function runButton:onTouch()
  run()
end
function editButton:onTouch()
  edit()
end
function copyButton:onTouch()
  if copybuffer[1] ~= 1 then
    copy()
  else
    paste()
  end
  if cutButton.pressed then
    cutButton.pressed = false
    cutButton:draw()
  end
end
function cutButton:onTouch()
  if copybuffer[1] ~= 2 then
    cut()
  else
    paste()
  end
  if copyButton.pressed then
    copyButton.pressed = false
    copyButton:draw()
  end
end

-----Container Events-----
function prog:customKeys(char, code, player)
  if manInput.focus == false and newGUI.disabled == true then
    if code == 200 then -- Up
      if fileList.selected > 1 then
        fileList.selected = fileList.selected - 1
        fileList.entries[fileList.selected].onPress(fileList.selected)
        fileList:draw()
      end
    elseif code == 208 then -- Down
      if fileList.selected < #fileList.entries then
        fileList.selected = fileList.selected + 1
        fileList.entries[fileList.selected].onPress(fileList.selected)
        fileList:draw()
      end
    elseif code == 205 then -- Right
      if fs.isDirectory(fspath..fileList.entries[fileList.selected].text)then
        fspath = treeUp(fspath, fileList.entries[fileList.selected].text)
        typeLabel.text = "Folder"
        listPopulate()
      else
        notes:refresh("Not a folder.")
      end
    elseif code == 203 then -- Left
      if fspath ~= "//" then
        fspath = treeDown(fspath)
        typeLabel.text = "Folder"
        listPopulate()
      end
    elseif char == 13 then -- Enter
      prog:moveToFront(manInput)
      manInput.focus = true
    elseif code == 14 or code == 211 then -- Del
      delete()
    elseif char == 14 then -- Ctrl-N
      new()
    elseif char == 114 then -- R
      run()
    elseif char == 101 then -- E
      edit()
    elseif char == 3 then -- Ctrl-C
      copyButton.pressed = true
      copyButton:draw()
      copy()
      if cutButton.pressed then
        cutButton.pressed = false
        cutButton:draw()
      end
    elseif char == 24 then -- Ctrl-X
      cutButton.pressed = true
      cutButton:draw()
      cut()
      if copyButton.pressed then
        copyButton.pressed = false
        copyButton:draw()
      end
    elseif char == 22 then -- Ctrl-V
      if copybuffer == {} then
        notes:refresh("Buffer Empty")
      else
        if copyButton.pressed then
          copyButton.pressed = false
        end
        if cutButton.pressed then
          cutButton.pressed = false
        end
        paste()
        copyButton:draw()
        cutButton:draw()
      end
    end
  else
    return false
  end
end

function newGUI:customKeys(char, code, player)
  if newGUI.disabled == false and folderInput.focus == false and nameInput.focus == false then
    if char == 49 then -- 1 Folder
      folderRadio:touch(folderRadio.x, folderRadio.y)
    elseif char == 50 then -- 2 .txt
      txtRadio:touch(txtRadio.x, txtRadio.y)
    elseif char == 51 then -- 3 .lua
      luaRadio:touch(luaRadio.x, luaRadio.y)
    elseif char == 52 then -- 4 none
      naRadio:touch(naRadio.x, naRadio.y)
    elseif char == 13 then -- Enter
      confirm()
    elseif char == 99 then -- C
      cancelButton:onTouch()
    else
      return false
    end
  end
end


listPopulate()
GUI.res(2)
prog:start()
repeat
  os.sleep(0.25)
until not prog.run
