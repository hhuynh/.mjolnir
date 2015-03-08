local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local application = require "mjolnir.application"

current_desktop = {}

function save()
  local open_windows = window.visiblewindows()
  
  for k,w in pairs(open_windows) do
      local app = w:application()
      local windows_of_app = current_desktop[app:title()]
      if windows_of_app == nil then
        windows_of_app = {}
        current_desktop[app:title()] = windows_of_app
      end
      windows_of_app[w:id()] = w:frame()
  end
end

function restore()
  local win = window.focusedwindow()
  local open_windows = window.visiblewindows()
  
  for k,w in pairs(open_windows) do
      local app = w:application()
      local windows_of_app = current_desktop[app:title()]
      if windows_of_app ~= nil then
        oldframe = windows_of_app[w:id()]
        if oldframe ~= nill then
          print("Restoring windows ", w:title(), "to its orginal position")
          w:setframe(oldframe)
        else
          print("Couldn't find old frame of", w:id(), "defaulting it")
          local maxWidth = 0
          local maxFrame = nil
          for t,f in pairs(windows_of_app) do
            if f["w"] > maxWidth then
              maxWidth = f["w"]
              maxFrame = f
            end
          end
          if maxFrame ~= nil then
            w:setframe(maxFrame)
          end
        end
      end
  end
  win:focus()
end

hotkey.bind({ "cmd", "alt" }, "S", function()
    save()
end)

hotkey.bind({ "cmd", "alt" }, "R", function()
    restore()
end)
