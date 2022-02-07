# Fungal Twitch

Fungal Twitch is a Noita mod that lets Twitch chat pick the materials for a fungal shift.  
**Make sure to read this page carefully, all your questions should be answered here.**

## Installation

### Download

- Download the files from github and extract to your Noita mod folder. **Rename the folder from fungal-twitch-main to fungal-twitch**
- Download the LTS version of [Nodejs](https://nodejs.org/en/download/) if you don't have it already

### Twitch
- Make 2 channel point redemptions, a template (img) can be found at the bottom of this page
  - One redemption is needed for the *from* material, and one redemption is needed for the *to* material
  - Make sure that the user must enter a message
  - Set it to not have a cooldown (you can change the cooldown settings in game)

### Run
- Run the batch file *RUN_THIS_THE_FIRST_TIME.bat* - This will setup the NodeJS environment, you only need to do this once
- Run the batch file *server.bat* - This will start the server
  - If this file closes immediately you either forgot to rename the folder from *fungal-twitch-main* to *fungal-twitch* or an unknown error has occurred.
  - The server will prompt you with several questions
  - If you ever make a mistake in the installation process, delete *fungal-twitch/application_data.json* and restart the server

## Starting the mod

- Run *server.bat* - You need to run this each time when you want to play this mod
- Start a new run in Noita with the Fungal Twitch mod enabled (make sure to grant it extra privileges, this is needed for websockets to work)
- If a message appears saying "Connection status: Open" then you know it works (the server will print a message too)

## How it works

Chat can redeem channel point rewards with either a *from* material or a *to* material.  
If someone sets a *from* or *to* again, before the other one is set, it will override the old one  
As soon as both materials are set, the fungal shift will happen.  
When a shift happens, the users that entered the materials that are used, will be put into a cooldown  
If you redeem a *from* shift, but then someone else redeems a *from* shift, and *then* a shift happens, you will not be put into cooldown

## Commands

- *!materials* to get a list of all materials - Everyone can use this command
- *!banmaterial material_name* to ban a material - Use this when materials create a large amount of lag - Only the streamer can use this command
- *!unbanmaterial material_name* to unban a material - Only the streamer can use this command

## Mod settings (ingame)

- *The cooldown per user* - The cooldown per user in seconds
- *Log a shift result ingame* - A message with the materials from the shift will be sent to the player 
- *Log a shift result in Twitch* - A message with the materials from the shift will be sent to Twitch chat 
- *Start with Peace with the gods* - The player will start with the perk *Peace with the gods*
- *Start with Breathless* - The player will start with the perk *Breathless*

## Credits

This is made by baasbase  
https://twitch.tv/baasbase  
https://twitter.com/baasbase  
https://www.youtube.com/channel/UCd5RjtL4EJwoeLJWiofGG3Q  
https://ko-fi.com/baasbase

## Twitch Custom Rewards

Make one for the *from* material, and another one for *to*. I used 1 channel point as price and no cooldown, but you can obviously edit those settings as you like

![Twitch Custom Reward](https://i.imgur.com/vXgmVTD.png)
