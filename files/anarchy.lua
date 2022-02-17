dofile_once("mods/fungal-twitch/files/utils.lua")

local UNBALANCED_MODE = ModSettingGet("fungal-twitch.UNBALANCED_MODE")
local ANARCHY_COOLDOWN = ModSettingGet("fungal-twitch.ANARCHY_COOLDOWN")

local REWARD_FROM_ID = ModSettingGet("fungal-twitch.REWARD_FROM_ID")
local REWARD_TO_ID = ModSettingGet("fungal-twitch.REWARD_TO_ID")

local Anarchy = {
  fromUser = "",
  toUser = "",
  cooldowns = {},
  users_from = {},
  users_to = {}
}

function Anarchy:init()
  REWARD_FROM_ID = ModSettingGet("fungal-twitch.REWARD_FROM_ID")
  REWARD_TO_ID = ModSettingGet("fungal-twitch.REWARD_TO_ID")
end

function Anarchy:tick()
  -- do nothing
end

function Anarchy:hasUI()
  return false
end

function Anarchy:handleInput(user, message, rewardId)
  if (self:getCooldown(user) > 0) then
    return
  end

  if (rewardId == nil) then
    return
  elseif (rewardId == REWARD_FROM_ID) then
    self.fromUser = user
    self.users_from[user] = message
  elseif (rewardId == REWARD_TO_ID) then
    self.toUser = user
    self.users_to[user] = message
  else
    return
  end

  local success = false
  local time = GameGetRealWorldTimeSinceStarted()
  if (UNBALANCED_MODE) then
    success = doShift(self.users_from[user], self.users_to[user])
    if (success) then
      self.users_from[user] = nil
      self.users_to[user] = nil
      self.cooldowns[user] = time
    end
  else
    success = doShift(self.users_from[self.fromUser], self.users_to[self.toUser])
    if (success) then
      self.users_from[self.fromUser] = nil
      self.users_to[self.toUser] = nil
      self.cooldowns[self.fromUser] = time
      self.cooldowns[self.toUser] = time
      self.fromUser = ""
      self.toUser = ""
    end
  end
end

function Anarchy:isIllegal(material)
	return isIllegalMaterial(material) or isBannedMaterial(material)
end

function Anarchy:getCooldown(user)
  if (self.cooldowns[user] ~= nil) then
    return self.cooldowns[user] + ANARCHY_COOLDOWN - GameGetRealWorldTimeSinceStarted()
  end
  return 0
end

function Anarchy:getUsersOnCooldown()
  local ret = {}
  for k,v in pairs(self.cooldowns) do
    if (self:getCooldown(k) > 0) then
      table.insert(ret, k)
    end
  end
  return ret
end

return Anarchy
