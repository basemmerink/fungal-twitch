# Fungal Twitch

Fungal Twitch is a Noita mod that lets Twitch chat pick the materials for a fungal shift

## Installation

- Download the files from github and extract to your Noita mod folder. Rename the folder from fungal-twitch-main to fungal-twitch
- Download (the latest version of) Nodejs if you don't have it already
- Edit the .env file
  - TWITCH_BOT_NAME - The name of your bot account on twitch
    - If you don't have a bot account you can use your main twitch account, do note that it will send messages using that account
  - TWITCH_OAUTH_TOKEN - To get your twitch oauth key go to https://twitchapps.com/tmi and login with your bot account
  - TWITCH_CHANNEL - The channel where you will livestream this mod
  - LOG_SHIFT_RESULT_TO_TWITCH - Do you want the bot account to send a message in twitch chat if a shift succeeds (true/false)
  - COOLDOWN_PER_USER_IN_SECONDS - The cooldown in seconds that users need to wait before they can perform a shift again. Set to 0 to have no cooldown
- Run the batch file RUN_THIS_THE_FIRST_TIME.bat - This will setup the nodejs environment, you only need to do this once
- Run the batch file server.bat - This will start the server and is needed for the next step
- Make 2 channel point redemptions, a template for those can be seen in the image below, at the bottom of this page
- To get the ID of these channel points, redeem the channel point reward while the server is running (make sure that user must enter a message). 
- After redeeming, the server will print the ID of the redemption
- Edit the .env file again
  - REWARD_FROM_ID - The ID of the channel point redemption for the "from" material
  - REWARD_TO_ID - The ID of the channel point redemption for the "to" material
- Stop the server - It needs to reload the .env, which can only be done by stopping it first

## Usage

- Run server.bat - You need to run this each time when you want to play this mod
- Start a new run in Noita with the Fungal Twitch mod enabled (make sure to grant it extra privileges, this is needed for websockets to work)
- If a message appears saying "Connection status: Open" then you know it works (the server will print a message too)
- !banmaterial material_name to ban a material - use this when materials create a large amount of lag
- !unbanmaterial material_name to unban a material

Chat can redeem channel point rewards with either a "from" material or a "to" material.  
If someone sets a "from" or "to" again, before the other one is set, it will override the old one  
As soon as both materials are set, the fungal shift will happen.

A message will be sent ingame to explain the shift that just happened.  
If you do not wish to see this message you can change it in the mod settings ingame

## Credits

This is made by baasbase  
https://twitch.tv/baasbase  
https://twitter.com/baasbase  
https://www.youtube.com/channel/UCd5RjtL4EJwoeLJWiofGG3Q  
https://ko-fi.com/baasbase

## Twitch Custom Reward

Make one for the "from" material, and another one for "to". I used 1 channel point as price and no cooldown, but you can obviously edit those settings as you like

![Twitch Custom Reward](https://i.imgur.com/vXgmVTD.png)
