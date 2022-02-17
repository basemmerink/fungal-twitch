local old_streaming_on_irc = _streaming_on_irc
function _streaming_on_irc(is_userstate, sender_username, message, raw)
  local messageData = {}
  for row in string.gmatch(raw, "[^;]+") do
    for key, value in string.gmatch(row, "(.+)=(.+)") do
      messageData[key] = value
    end
  end
  GlobalsSetValue("fungal-twitch.lastUser", sender_username)
  GlobalsSetValue("fungal-twitch.lastMessage", message)
  GlobalsSetValue("fungal-twitch.lastRewardId", messageData['custom-reward-id'] or "")
  GlobalsSetValue("fungal-twitch.hasNewMessage", "true")

  if (old_streaming_on_irc ~= nil) then
    old_streaming_on_irc(is_userstate, sender_username, message, raw)
  end
end
