# Fungal Twitch

Fungal Twitch lets Twitch chat pick the materials for a fungal shift

## Installation

- Edit the .env file
  - TWITCH_BOT_NAME - The name of your bot account on twitch
    - If you don't have a bot account you can use your main twitch account, do note that it will send messages using that account
  - TWITCH_OAUTH_TOKEN - To get your twitch oauth key go to https://twitchapps.com/tmi and login with your bot account
  - TWITCH_CHANNEL - The channel where you will livestream this mod
  - REWARD_FROM_ID - The ID of the channel point redemption for the "from" material
  - REWARD_TO_ID - The ID of the channel point redemption for the "to" material
    - First you should make 2 channel point redemptions, a template for those can be seen in the image below
    - To get the IDs, you can run the server and redeem the channel point reward (make sure that user must enter a message). After redeeming the channel point reward, the server will print the reward ID in the console
  - LOG_SHIFT_RESULT_TO_TWITCH - Do you want the bot account to send a message in twitch chat if a shift succeeds (true/false)
- Run the batch file RUN_THIS_THE_FIRST_TIME.bat - This will setup the nodejs environment
- Run server.bat - You need to run this each time when you want to play this mod
- Start a new run in Noita with the Fungal Twitch mod enabled (make sure to grant it extra privileges, this is needed for websockets to work)
- If you don't want to a message with information on the shifts, you can edit init.lua and change the first 2 lines to your liking

## Credits

This is made by baasbase  
https://twitch.tv/baasbase  
https://twitter.com/baasbase  
https://www.youtube.com/channel/UCd5RjtL4EJwoeLJWiofGG3Q  
https://ko-fi.com/baasbase

## Twitch Custom Reward

Make one for the "from" material, and another one for "to". I used 1 channel point as price and no cooldown, but you can obviously edit those settings as you like

![Twitch Custom Reward](https://i.imgur.com/vXgmVTD.png)
