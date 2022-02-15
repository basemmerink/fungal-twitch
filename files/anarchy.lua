dofile_once("mods/fungal-twitch/files/utils.lua")

local UNBALANCED_MODE = ModSettingGet("fungal-twitch.UNBALANCED_MODE")
local ANARCHY_COOLDOWN = ModSettingGet("fungal-twitch.ANARCHY_COOLDOWN")

local fromUser = ""
local toUser = ""
local anarchy_cooldowns = {}
local anarchy_users_from = {}
local anarchy_users_to = {}

local Anarchy = {}

function Anarchy:init()
  -- do nothing
end

function Anarchy:tick()
  -- do nothing
end

function Anarchy:hasUI()
  return false
end

function Anarchy:handleInput(user, method, material)
  local time = GameGetRealWorldTimeSinceStarted()
  if (anarchy_cooldowns[user] ~= nil) then
    local cooldown = anarchy_cooldowns[user] + ANARCHY_COOLDOWN - time
    if (cooldown > 0) then
      getSocket():send(user .. ", your cooldown is " .. string.format("%.0f", cooldown)  .. " seconds")
      return
    end
  end

  if (method == "from") then
    fromUser = user
    anarchy_users_from[user] = material
  end
  if (method == "to") then
    toUser = user
    anarchy_users_to[user] = material
  end

  local success = false
  if (UNBALANCED_MODE) then
    success = doShift(anarchy_users_from[user], anarchy_users_to[user])
    if (success) then
      anarchy_users_from[user] = nil
      anarchy_users_to[user] = nil
      anarchy_cooldowns[user] = time
    end
  else
    success = doShift(anarchy_users_from[fromUser], anarchy_users_to[toUser])
    if (success) then
      anarchy_users_from[fromUser] = nil
      anarchy_users_to[toUser] = nil
      anarchy_cooldowns[fromUser] = time
      anarchy_cooldowns[toUser] = time
      fromUser = ""
      toUser = ""
    end
  end
end


function Anarchy:isIllegalMaterial(material)
	return isIllegalMaterial(material)
end

function Anarchy:isBannedMaterial(material)
	return isBannedMaterial(material)
end

return Anarchy
