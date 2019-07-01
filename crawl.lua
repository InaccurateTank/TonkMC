local event = require("event")
local GUI = require("GUI")
local fs = require("filesystem")
local term = require("term")

local VER = 0.5
local PROG_NAME = "/tank/crawl"
local EDIT = "shedit" -- Edit program used
local fspath = "//home/" -- Default file path
local copybuffer = "" -- File Path for copying
local RUNNING = true
local prog = GUI.manager(RUNNING)

local function close()
  prog:stop()
  term.setCursor(1, 1)
  os.exit()
end

-----New File Window-----
local newGUI = GUI.newWindow(prog, 21, 3, 42, 20, 0xcccccc, 0x000000)
newGUI.disabled = true

GUI.newLabel(newGUI, 1, 1, newGUI.width, 0x333399, 0xffffff, "Create New...")
GUI.newLabel(newGUI, 2, 3, 1, newGUI.background, 0x000000, "Path:")
GUI.newLabel(newGUI, 2, 5, 1, newGUI.background, 0x000000, "Name:")
local folderInput = GUI.newInput(newGUI, 7, 3, 35, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc)
local nameInput = GUI.newInput(newGUI, 7, 5, 35, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc)
folderInput.onReturn = function()
  folderInput.focus = false
  nameInput.focus = true
  folderInput:draw()
  nameInput:draw()
end
nameInput.onReturn = function()
  nameInput.focus = false
  nameInput:draw()
end
GUI.newLabel(newGUI, 1, 7, newGUI.width, mainGUI.background, 0x000000, "[Type (1-4)]", "-", 0x000000)
GUI.newLabel(newGUI, 2, 9, 1, newGUI.background, 0x000000, "Folder:")
local folderRadio = GUI.newRadio(newGUI, 10, 9, newGUI.background, 0x000000)
GUI.newLabel(newGUI, 2, 11, 1, newGUI.background, 0x000000, ".txt:")
local txtRadio = GUI.newRadio(newGUI, 10, 11, newGUI.background, 0x000000)
GUI.newLabel(newGUI, 2, 13, 1, newGUI.background, 0x000000, ".lua:")
local luaRadio = GUI.newRadio(newGUI, 10, 13, newGUI.background, 0x000000)
GUI.newLabel(newGUI, 2, 15, 1, newGUI.background, 0x000000, "None:")
local naRadio = GUI.newRadio(newGUI, 10, 15, newGUI.background, 0x000000)
local confirmButton = GUI.newButton(newGUI, 2, 19, 1, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "Confirm:")
local cancelButton = GUI.newButton(newGUI, 31, 19, 1, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "(C)ancel:")




-----Main Window-----
local mainGUI = GUI.newWIndow()
mainGUI.back = 0xcccccc


local title = GUI.newLabel(mainGUI, 1, 1, mainGUI.width, 0x333399, 0xffffff, PROG_NAME.." v:"..VER)
title.align = "left"
local exit = GUI.newButton(mainGUI, 80, 1, 0, 0, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
exit.onPress = close

GUI.newLabel(mainGUI, 3, 3, 17, mainGUI.background, 0x000000, "[Folder Path]", "-", 0x000000)
local dirList = GUI.newList(mainGUI, 3, 4, 16, 19, 0, 0x333399, 0xffffff, 0x9933cc, 0xffffff)
dirList.align = "left"
local dirScroll = GUI.newScroll(mainGUI, dirList, 0x333399, 0xffffff, 0x5599ff, 0xffffff)

GUI.newLabel(mainGUI, 64, 3, 15, mainGUI.background, 0x000000, "[Type]", "-", 0x000000)
local typeLabel = GUI.newLabel(mainGUI, 64, 4, 15, mainGUI.background, 0x000000, "")
typeLabel.align = "left"
GUI.newLabel(mainGUI, 64, 6, 15, mainGUI.background, 0x000000, "[Last Mod]", "-", 0x000000)
local modLabel = GUI.newLabel(mainGUI, 64, 7, 15, mainGUI.background, 0x000000, "")
modLabel.align = "left"
GUI.newLabel(mainGUI, 64, 9, 15, mainGUI.background, 0x000000, "[Notifications]", "-", 0x000000)
local notes = GUI.newText(mainGUI, 64, 10, 15, 6, 0x333399, 0xffffff, "")

local fileList = GUI.newList(mainGUI, 21, 3, 41, 20, 0, 0x333399, 0xffffff, 0x9933cc, 0xffffff)
fileList.align = "left"
local fileScroll = GUI.newScroll(mainGUI, fileList, 0x333399, 0xffffff, 0x5599ff, 0xffffff)

local manInput = GUI.newInput(mainGUI, 3, 24, 76, 1, 0x333399, 0xffffff, 0x9933cc, 0xffffff, 0x9933cc, "Manual Commands Here", 0xffffff)
manInput.onReturn = function()
end

local newButton = GUI.newButton(mainGUI, 64, 17, 4, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "(N)ew: ")
local delButton = GUI.newButton(mainGUI, 64, 18, 3, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "(Del)ete:")
delButton.confirm = false
local runButton = GUI.newButton(mainGUI, 64, 19, 4, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "(R)un: ")
runButton.disabled = true
local editButton = GUI.newButton(mainGUI, 64, 20, 4, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "(E)dit:")
editButton.disabled = true
local copyButton = GUI.newButton(mainGUI, 64, 21, 5, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "Copy:")
copyButton.switch = true
copyButton.disabled = true
local cutButton = GUI.newButton(mainGUI, 64, 22, 5, 0, 0x333399, 0xffffff, 0xffffff, 0x000000, "Cut: ")
cutButton.switch = true
cutButton.disabled = true

repeat
  os.sleep(0.25)
until not RUNNING






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
    fileList:newSub(folder[i], function(id)
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
    dirList:newSub(pathtab[i], function(id)
      if dirList.confirm == id then
        fspath = table.concat(pathtab, "", 1, id)
        listPopulate()
      else
        dirList.confirm = id
      end
    end)
  end
  fileList:draw()
  fileScroll:draw()
  dirList:draw()
  dirScroll:draw()
end

-----Pressable Init-----
newButton.onPress = function()
  fileList.disabled = true
  dirList.disabled = true
  newGUI.disabled = false
  folderInput.text[1] = fspath
  newGUI:draw()
end
cancelButton.onPress = function()
  folderInput.text = {}
  nameInput.text = {}
  folderRadio.active = false
  txtRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  fileList.disabled = false
  dirList.disabled = false
  newGUI.disabled = true
  fileList:draw()
  fileScroll:draw()
end


folderRadio.onActive = function()
  txtRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  txtRadio:draw()
  luaRadio:draw()
  naRadio:draw()
end
txtRadio.onActive = function()
  folderRadio.active = false
  luaRadio.active = false
  naRadio.active = false
  folderRadio:draw()
  luaRadio:draw()
  naRadio:draw()
end
luaRadio.onActive = function()
  txtRadio.active = false
  folderRadio.active = false
  naRadio.active = false
  txtRadio:draw()
  folderRadio:draw()
  naRadio:draw()
end
naRadio.onActive = function()
  txtRadio.active = false
  luaRadio.active = false
  folderRadio.active = false
  txtRadio:draw()
  luaRadio:draw()
  folderRadio:draw()
end

confirmButton.onPress = function()
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
  fileList.disabled = false
  dirList.disabled = false
  newGUI.disabled = true
  listPopulate()
end
delButton.onPress = function()
  if not delButton.confirm then
    delButton.confirm = true
    notes:refresh("Are you sure you want to delete that?")
    event.timer(2, function()
      delButton.confirm = false
      notes:refresh("")
    end)
  else
    delButton.confirm = false
    notes:refresh("")
    fs.remove(fspath..fileList.entries[fileList.selected].text)
    listPopulate()
  end
end
runButton.onPress = function()
  GUI.resetBack()
  mainGUI.disabled = true
  os.execute(fspath..fileList.entries[fileList.selected].text.." \""..(manInput.text[1] or "").."\"")
  mainGUI.disabled = false
  mainGUI:draw()
end
editButton.onPress = function()
  GUI.resetBack()
  mainGUI.disabled = true
  os.execute(EDIT.." \""..fspath..fileList.entries[fileList.selected].text.."\"")
  mainGUI.disabled = false
  mainGUI:draw()
end
copyButton.onPress = function()
  if not copyButton.pressed then
    copybuffer = fspath..fileList.entries[fileList.selected].text
    notes:refresh("File path copied to buffer")
  else
    fs.copy(copybuffer, appendName(fspath..copybuffer:match("([^/]-)$")))
    notes:refresh("File pasted")
    listPopulate()
    copybuffer = ""
    if editButton.disabled then
      copyButton.disabled = true
      copyButton:draw()
    end
  end
end
cutButton.onPress = function()
  if not cutButton.pressed then
    notes:refresh("File path copied to buffer")
    copybuffer = fspath..fileList.entries[fileList.selected].text
  else
    if fs.exists(fspath..copybuffer:match("([^/]-)$")) then
      notes:refresh("Filename already taken at location")
    else
      fs.copy(copybuffer, appendName(fspath..copybuffer:match("([^/]-)$")))
      fs.remove(copybuffer)
      notes:refresh("File pasted")
      listPopulate()
      copybuffer = ""
    end
    if editButton.disabled then
      cutButton.disabled = true
      cutButton:draw()
    end
  end
end

-----Event Handler-----
function touch(name, address, x, y, button, player)
  mainGUI:press(x, y)
  newGUI:press(x, y)
end
function scroll(name, address, x, y, dir, player)
  mainGUI:scroll(x, y, dir)
  newGUI:scroll(x, y, dir)
end
function key(name, address, char, code, player)
  mainGUI:key(char, code, player)
  newGUI:key(char, code, player)
end

-----Run-----
listPopulate()
mainGUI:draw()
event.listen("touch", touch)
event.listen("scroll", scroll)
event.listen("key_down", key)
while RUNNING do
  os.sleep(0.25)
end
