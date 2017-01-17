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
  iTerm2 = { laptopScreen, fullScreen },
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
  iTerm2 = { workScreen, leftHalf },
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
  iTerm2 = { workScreen, leftHalf },
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
  [ "+69732992+69507833" ] = workLayout,
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

function connectToVPN()
	hs.applescript([[
		ignoring application responses
			tell application "System Events" to tell process "GlobalProtect"
				click menu bar item 1 of menu bar 2
			end tell
		end ignoring
		--do shell script "killall System\\ Events"
		--delay 0.1
		tell application "System Events" to tell process "GlobalProtect"
			tell menu bar item 1 of menu bar 2
				if exists menu item "Connect to" of menu 1
					tell menu item "Connect to" of menu 1
						click
						click menu item "APAC" of menu 1
					end tell
				end if
			end tell
		end tell
	]])
end

function caffeinateCallback(e)
	if e == hs.caffeinate.watcher.screensDidUnlock then
		connectToVPN()
	end
end

function wifiChanged()
	print('wifi change callback')
	connectToVPN()
end

hs.hotkey.bind(hyper, "V", function()
	print('connecting to VPN')
	connectToVPN()
end)

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
  hs.grid.set(win, place[2], hs.screen.allScreens()[place[1]])
end

function modifyWifi(identifier)
  if identifier == "+69732992+69507833" then
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

function startCaffienateWatcher()
	caffeinatewatcher = hs.caffeinate.watcher.new(caffeinateCallback):start()
end

function startWifiWatcher()
	wifiwatcher = hs.wifi.watcher.new(wifiChanged):start()
end

-- URL director
-- This makes Hammerspoon take over as the default http/https handler
-- Whenever a URL is opened, Hammerspoon will draw all of the app icons which can handle URLs and let the user choose where to direct the URL
hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    print("URL Director: "..fullURL)

    local screen = hs.screen.mainScreen():frame()
    local handlers = hs.urlevent.getAllHandlersForScheme(scheme)
		local browsers = hs.fnutils.filter(handlers, function(o, k, i)
			local name = hs.application.nameForBundleID(o)
			return name == "Chrome" or name == "Firefox"
		end)
    local numHandlers = #browsers
		print(numHandlers)
    local modalKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}

    local boxBorder = 10
    local iconSize = 72

    if numHandlers > 0 then
        local appIcons = {}
        local appNames = {}
        local modalDirector = hs.hotkey.modal.new()
        local x = screen.x + (screen.w / 2) - (numHandlers * iconSize / 2)
        local y = screen.y + (screen.h / 2) - (iconSize / 2)
        local box = hs.drawing.rectangle(hs.geometry.rect(x - boxBorder, y - boxBorder, (numHandlers * iconSize) + (boxBorder * 2), iconSize + (boxBorder * 4)))
        box:setFillColor({["red"]=0,["blue"]=0,["green"]=0,["alpha"]=0.5}):setFill(true):show()

        local exitDirector = function(bundleID, url)
            if (bundleID and url) then
                hs.urlevent.openURLWithBundle(url, bundleID)
            end
            for _,icon in pairs(appIcons) do
                icon:delete()
            end
            for _,name in pairs(appNames) do
                name:delete()
            end
            box:delete()
            modalDirector:exit()
        end

        for num,browser in pairs(browsers) do
						local appIcon = hs.drawing.appImage(hs.geometry.size(iconSize, iconSize), browser)
						local name = hs.application.nameForBundleID(browser)

						if appIcon and name and name == "Chrome" or name == "Firefox" then
								local appName = hs.drawing.text(hs.geometry.size(iconSize, boxBorder), modalKeys[num].." "..name)

                table.insert(appIcons, appIcon)
                table.insert(appNames, appName)

                appIcon:setTopLeft(hs.geometry.point(x + ((num - 1) * iconSize), y))
                appIcon:setClickCallback(function() exitDirector(browser, fullURL) end)
                appIcon:orderAbove(box)
                appIcon:show()

                appName:setTopLeft(hs.geometry.point(x + ((num - 1) * iconSize), y + iconSize))
                appName:setTextStyle({["size"]=10,["color"]={["red"]=1,["blue"]=1,["green"]=1,["alpha"]=1},["alignment"]="center",["lineBreak"]="truncateMiddle"})
                appName:orderAbove(box)
                appName:show()

                modalDirector:bind({}, modalKeys[num], function() exitDirector(browser, fullURL) end)
            end
        end

        modalDirector:bind({}, "Escape", exitDirector)
        modalDirector:enter()
    end
end
hs.urlevent.setDefaultHandler('http')
-----------------------------------------------
-- Init
-----------------------------------------------

startScreenWatcher()
screenWatcher()
startAppWatcher()
startCaffienateWatcher()
startWifiWatcher()
setupAutoReload()
