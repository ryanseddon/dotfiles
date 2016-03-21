-----------------------------------------------
-- Set up
-----------------------------------------------

local inspect = require "hs.inspect"

local currentLayout = nil
local hyper = {"cmd", "alt", "ctrl"}
local log = hs.logger.new('default', 'debug')

hs.window.animationDuration = 0

hs.grid.GRIDWIDTH  = 64
hs.grid.GRIDHEIGHT = 36
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-----------------------------------------------
-- Layouts
-----------------------------------------------

local leftHalf     = { x = 0,  y = 0, h = 36, w = 32 }
local rightHalf    = { x = 32, y = 0, h = 36, w = 32 }
local middleScreen = { x = 5,  y = 3, h = 30, w = 54 }
local fullScreen   = { x = 0,  y = 0, h = 36, w = 64 }

function clone(t)
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      target[k] = clone(v)
    else
      target[k] = v
    end
  end
  setmetatable(target, meta)
  return target
end

function joinMyTables(t1, t2)
  local t3 = clone(t1)
  for k, v in pairs(t2) do t3[k] = v end
  return t3
end

local workScreen = 2
local laptopScreen = 1

local defaultLayout = {
  Evernote = { laptopScreen, fullScreen },
  SourceTree = { laptopScreen, fullScreen },
  Slack = { laptopScreen, fullScreen },
  iTerm = { laptopScreen, fullScreen },
  MacVim = { laptopScreen, fullScreen },
  Firefox = { laptopScreen, fullScreen },
  ["Google Chrome"] = { laptopScreen, fullScreen },
  Spotify = { laptopScreen, middleScreen },
  KeePassX = { laptopScreen, middleScreen }
}

local homeLayout = {
  Evernote = { workScreen, middleScreen },
  SourceTree = { workScreen, middleScreen },
  Slack = { workScreen, middleScreen },
  iTerm = { workScreen, leftHalf },
  ["Sublime Text"] = { workScreen, middleScreen },
  Firefox = { workScreen, middleScreen },
  ["Google Chrome"] = { workScreen, rightHalf },
  Spotify = { workScreen, middleScreen },
  KeePassX = { workScreen, middleScreen }
}

local twoMonitorDefault = {
  Evernote = { laptopScreen, middleScreen },
  Spotify = { laptopScreen, middleScreen },
  KeePassX = { laptopScreen, middleScreen },

  SourceTree = { laptopScreen, middleScreen },
  Slack = { workScreen, rightHalf },
  iTerm = { workScreen, leftHalf },
  MacVim = { laptopScreen, middleScreen },

  Firefox = { laptopScreen, fullScreen },
  ["Google Chrome"] = { workScreen, rightHalf }
}

local workLayoutBase = {
  Flowdock = { laptopScreen, fullScreen },
  Slack = { laptopScreen, fullScreen }
}

workLayout = joinMyTables(twoMonitorDefault, workLayoutBase)
currentLayout = defaultLayout

local layouts = {
  -- +69732352 = laptop
  -- +69501409 = thunderbolt work
  [ "+69732992" ]          = defaultLayout,
  [ "+69732992+69501409" ] = workLayout,
  [ "+69503729" ]          = homeLayout
}

-----------------------------------------------
-- Key bindings
-----------------------------------------------

local gridset = function(frame)
  return function()
    local win = hs.window.focusedWindow()
    if win then
      hs.grid.set(win, frame, win:screen())
    end
  end
end

local hotKeyDefinitions = {
  Left  = gridset(leftHalf),
  Right = gridset(rightHalf),
  Up    = gridset(fullScreen),
  Down  = gridset(middleScreen)
}

-----------------------------------------------
-- Functions
-----------------------------------------------

function reloadConfig(files)
  hs.reload()
end

function applicationWatcher(appName, eventType, appObject)
  if ((eventType == hs.application.watcher.launching) or (eventType == hs.application.watcher.launched) or (eventType == hs.application.watcher.activated)) then
    if currentLayout then
      log:d("Applying layout..")
      applyLayout(currentLayout)
    end
  end
end

function screenWatcher()
  local identifier = ""
  for _, curScreen in pairs(hs.screen.allScreens()) do
    identifier = identifier .. "+" .. curScreen:id()
  end

  log:d("Screen unique identifier : ".. identifier)

  if layouts[identifier] then
    currentLayout = layouts[identifier]
    modifyWifi(identifier)
    applyLayout(currentLayout)
  end
end

local gridset = function(frame)
  local win = hs.window.focusedWindow()
  if win then
    hs.grid.set(win, frame, win:screen())
  end
end

function applyPlace(win, place)
  hs.grid.set(win, place[2], hs.screen:allScreens()[place[1]])
end

function modifyWifi(identifier)
  if identifier == "+69732992+69501409" then
    hs.applescript('do shell script "networksetup -setairportpower en1 off"')
  else
    hs.applescript('do shell script "networksetup -setairportpower en1 on"')
  end

end

function applyLayout(layout)
  -- hs.alert.show("Applying layout")
  for appName, place in pairs(layout) do
    -- log:d("app: " .. appName .. ", place: " .. inspect(place))
    local app = hs.appfinder.appFromName(appName)
    if app then
      for i, win in ipairs(app:allWindows()) do
        applyPlace(win, place)
      end
    end
  end
end

function createHotkeys()
  -- hs.alert.show("Setting up hotkeys")
  for key, fun in pairs(hotKeyDefinitions) do
    hs.hotkey.new(hyper, key, fun):enable()
  end
end

function setupAutoReload()
  -- hs.alert.show("Setting up auto reload")
  hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
  hs.alert.show("Config reloaded")
  hs.hotkey.bind(hyper, 'delete', function()
    reloadConfig()
  end)
end

function startAppWatcher()
  -- hs.alert.show("Setting up app watcher")
  hs.application.watcher.new(applicationWatcher):start()
end

function startScreenWatcher()
  -- hs.alert.show("Setting up screen watcher")
  screenwatcher = hs.screen.watcher.new(screenWatcher):start()
end

function sleepComp()
  hs.alert.show("Sleep")
  hs.caffeinate.systemSleep()
end

-----------------------------------------------
-- Init
-----------------------------------------------

startScreenWatcher()
screenWatcher()
startAppWatcher()
--createHotkeys()
setupAutoReload()

--hs.hotkey.bind({"cmd", "alt", "ctrl"}, 'S', sleepComp)
