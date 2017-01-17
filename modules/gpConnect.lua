local hyper = {"cmd", "alt", "ctrl"}

hs.hotkey.bind(hyper, "E", function()
	hs.applescript([[
		ignoring application responses
			tell application "System Events" to tell process "GlobalProtect"
				click menu bar item 1 of menu bar 2
			end tell
		end ignoring
		do shell script "killall System\\ Events"
		delay 0.1
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
end)

function caffeinateCallback(e)
	if e == hs.caffeinate.watcher.screensDidWake then
		print('screen woke')
	end
end

caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
caffeinateWatcher:start()


