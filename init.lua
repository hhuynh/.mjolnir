local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local application = require "mjolnir.application"
local sw = require "mjolnir._asm.watcher.screen"
local screen = require "mjolnir.screen"
local timer = require "mjolnir._asm.timer"
local setting = require "mjolnir._asm.settings"
local json = require "mjolnir._asm.data.json"

screen_saves = {}

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

function persist_screen_save()
  print("Saving screen_saves to disk")
  setting.set_data("screen_saves", json.encode(screen_saves))
end

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
-----------------------------------------------------------------------

save()

save_timer = timer.new(120, save)
save_timer:start()

-- watch for screen changes (monitor plug/unplug)
function screen_changed()
  restore()
end

screen_watcher = sw.new(screen_changed)
screen_watcher:start()

hotkey.bind({"cmd", "alt"}, "6", persist_screen_save)
hotkey.bind({"cmd", "alt"}, "7", load_screen_save)
