local gui = {
  guiObj = nil,
  guiId = nil
}

function gui:init()
  self.guiObj = GuiCreate()
  self.guiId = 7755
end

function gui:getObject()
  return self.guiObj
end

function gui:getId()
  return self.guiId
end

function gui:start()
  self.guiId = 7755
	GuiStartFrame(self.guiObj)
	GuiIdPushString(self.guiObj, "fungal-twitch")
end

function gui:finish()
  GuiIdPop(self.guiObj)
end

return gui
