local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local application = require "mjolnir.application"
local sw = require "mjolnir._asm.watcher.screen"
local screen = require "mjolnir.screen"
local timer = require "mjolnir._asm.timer"

screen_saves = {}

function save()
  mainscreen = screen.mainscreen()
  if mainscreen == nil then
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
end

function restore()
  mainscreen = screen.mainscreen()
  if mainscreen == nil then
    return
  end
  
  print("restoring windows positions for screen", mainscreen:name())
  current_desktop = screen_saves[mainscreen:name()]
  if current_desktop == nil then
    print(" ... there was no save for that screen yet, bailing.")
    return
  end
  
  local win = window.focusedwindow()
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
  win:focus()
end

-----------------------------------------------------------------------

save()

save_timer = timer.new(60, save)
save_timer:start()

-- watch for screen changes (monitor plug/unplug)
function screen_changed()
  restore()
end

screen_watcher = sw.new(screen_changed)
screen_watcher:start()
