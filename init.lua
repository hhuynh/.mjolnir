local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local application = require "mjolnir.application"
local sw = require "mjolnir._asm.watcher.screen"
local screen = require "mjolnir.screen"
local timer = require "mjolnir._asm.timer"
local setting = require "mjolnir._asm.settings"
local json = require "mjolnir._asm.data.json"
local pasteboard = require "mjolnir._asm.data.pasteboard"

screen_saves = {}
change_count = pasteboard.changecount()

function init_screen_saves()
  saved = setting.get("screen_saves")
  if saved ~= nil then
    screen_saves = json.decode(saved)
    print("Found saved screen_saves... restoring")
    restore()
  else
    print("No screen_saves found on disk")
    save()
  end
end
  

function save()
  mainscreen = screen.mainscreen()
  if mainscreen == nil or mainscreen:name() == nil then
    return
  end
  
  print("saving current windows positions for screen", mainscreen:name())
  current_desktop = {}
  local open_windows = window.visiblewindows()
  
  for k,w in pairs(open_windows) do
      local app = w:application()
      local windows_of_app = current_desktop[app:title()]
      if windows_of_app == nil then
        windows_of_app = {}
        current_desktop[app:title()] = windows_of_app
      end
      if w:id() ~= nil then
        windows_of_app[w:id()] = w:frame()
      end
  end
  
  screen_saves[mainscreen:name()] = current_desktop
  setting.set_data("screen_saves", json.encode(screen_saves))
end

function restore()
  mainscreen = screen.mainscreen()
  if mainscreen == nil or mainscreen:name() == nil then
    return
  end
  
  print("restoring windows positions for screen", mainscreen:name())
  current_desktop = screen_saves[mainscreen:name()]
  if current_desktop == nil then
    print(" ... there was no save for that screen yet, bailing.")
    return
  end
  
  local open_windows = window.visiblewindows()
  
  for k,w in pairs(open_windows) do
      local app = w:application()
      local windows_of_app = current_desktop[app:title()]
      if windows_of_app ~= nil then
        oldframe = windows_of_app[w:id()]
        if oldframe ~= nill then
          w:setframe(oldframe)
        end
      end
  end
end

-- save screens to disk
function persist_screen_save()
  print("Saving screen_saves to disk")
  setting.set_data("screen_saves", json.encode(screen_saves))
end


-- load screens from disk
function load_screen_save()
  saved = setting.get("screen_saves")
  if saved ~= nil then
    screen_saves = json.decode(saved)
    print("Found saved screen_saves. Restoring")
    restore()
  else
    print("Couldn't find any screen saves on disk")
    return
  end
end

-- clear clipboard if there's something new in the clipboard based on change count
function clear_clipboard()
  local newChangeCount = pasteboard.changecount()
  if (newChangeCount == change_count) then
    pasteboard.setcontents("")
    print("Clipboard content was cleared")
    change_count = pasteboard.changecount()
  else
    print("Clipboard was not cleared")
    change_count = newChangeCount
  end
end

------------  MAIN --------------------------------------------

save_timer = timer.new(120, save)
save_timer:start()

clear_clipboard_timer = timer.new(180, clear_clipboard)
clear_clipboard_timer:start()

-- watch for screen changes (monitor plug/unplug)
function screen_changed()
  restore()
end

screen_watcher = sw.new(screen_changed)
screen_watcher:start()

hotkey.bind({"cmd", "alt"}, "6", persist_screen_save)
hotkey.bind({"cmd", "alt"}, "7", load_screen_save)
