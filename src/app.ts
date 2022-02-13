import readlineSync from 'readline-sync';
import express from 'express';
import open from 'open';
import {existsSync, readFileSync, writeFileSync} from 'fs';
import {createServer} from 'http';
import {WebSocketServer} from 'ws';
import {ChatUserstate, Client} from 'tmi.js';

const PORT = 9443;
const WS_PORT = 9444;

const app = express();
const server = createServer(app);
const webSocketServer = new WebSocketServer({ port: WS_PORT });
let twitchClient;

const appData = existsSync('application_data.json') ?
    JSON.parse(readFileSync('application_data.json').toString()) :
    {
        bot_name: '',
        channel: '',
        access_token: '',
        from_reward_id: '',
        to_reward_id: '',
        banned_materials: [
            'air', 'bush_seed', 'glass_brittle', 'glowshroom', 'ice_meteor_static', 'mushroom_giant_red',
            'mushroom_giant_blue', 'plant_material', 'plant_material_red']
    };


server.listen(PORT, () => console.log(`Webserver running on port ${PORT}`));

app.use(express.json({
    verify: (req, res, buf) => {
        req.rawBody = buf;
    }
}));
app.get('/assets/twitch-prompt.png', (req, res, next) => {
    res.sendFile('assets/twitch-prompt.png', {root: __dirname + '/../..'});
});
app.post('/twitch', (req, res, next) => {
    const response = JSON.parse(req.rawBody);
    appData.access_token = response.access_token;
    saveAppData();
    connectToTwitch();
});
app.all('/*', (req, res, next) => {
    res.sendFile('src/login.html', {root: __dirname + '/../..'});
});

webSocketServer.on('connection', webSocket => {
    console.log();
    console.log('--------------------------------------------------------');
    console.log('Noita connection opened');
    console.log('Use !banmaterial material_name to ban a material');
    console.log('Use !unbanmaterial material_name to unban a material');
    console.log('Only the streamer can input these commands.');
    console.log('--------------------------------------------------------');

    if (appData.banned_materials.length > 0)
    {
        webSocket.send('system init_banned_materials ' + appData.banned_materials.join(','))
    }

    webSocket.on('message', data => {
        const message = data.toString();
        const [command, ...args] = message.split(' ');
        switch (command) {
            case 'ban':
                appData.banned_materials.push(args[0]);
                saveAppData();
                sendTwitchMessage(`Material ${args[0]} is now banned. Use !unbanmaterial ${args[0]} to unban it`);
                break;
            case 'unban':
                appData.banned_materials = appData.banned_materials.filter(mat => mat !== args[0]);
                saveAppData();
                sendTwitchMessage(`Material ${args[0]} is now unbanned. Use !banmaterial ${args[0]} to ban it again`);
                break;
            default:
                sendTwitchMessage(message);
                break;
        }
    });
});

function saveAppData() {
    writeFileSync('application_data.json', JSON.stringify(appData));
}

while (appData.bot_name.length === 0 || appData.channel.length === 0)
{
    var bot_name = readlineSync.question('Enter your Twitch bot name (if you don\'t have one, enter your main Twitch channel name): ');
    var channel = readlineSync.question('Enter your Twitch channel name: ');
    if (readlineSync.keyInYN(`So your Twitch bot account is ${bot_name} and your Twitch channel is ${channel}? `)) {
        appData.bot_name = bot_name;
        appData.channel = channel;
        saveAppData();
    }
}

if (!appData.access_token) {
    readlineSync.question('You will now be taken to a login page, after that process is done come back here (Enter to continue)');
    open('http://localhost:9443')
        .then(() => {})
        .catch(() => process.exit(-1));
}
else
{
    connectToTwitch();
}

function connectToTwitch() {
    twitchClient = Client({
        identity: {
            username: appData.bot_name,
            password: 'oauth:' + appData.access_token
        },
        channels: [appData.channel],
        connection: {
            reconnect: true
        }
    });

    twitchClient.on('connected', (addr, port) => {
        if (appData.from_reward_id.length === 0 || appData.to_reward_id.length === 0) {
            console.log('Go to Twitch, create 2 channel point redemptions following the guide on github, and redeem them both once');
        } else {
            console.log('Twitch API initialized')
        }
    });
    twitchClient.on('message', (channel: string, userState: ChatUserstate, message: string, senderIsSelf: boolean) => {
        if (senderIsSelf) {
            return; // ignore our own messages
        }
        const rewardId = userState['custom-reward-id'];
        const username = userState['display-name'];
        if (!rewardId) {
            const [first, ...args] = message.split(' ');
            const command = first.toLowerCase();
            if (command.length < 3 && /[1-4a-d]{1,2}/.test(command)) {
                sendWebsocketMessage(username + ' ti ' + command);
            }
            handleCommand(command, args, username);
            return;
        }
        const material = message.toLowerCase().trim();
        if (appData.from_reward_id.length === 0) {
            console.log(`${username}: ${message}`);
            if (readlineSync.keyInYN(`Is this the FROM material? `)) {
                appData.from_reward_id = rewardId;
                saveAppData();
                return;
            }
        }
        if (appData.to_reward_id.length === 0) {
            console.log(`${username}: ${message}`);
            if (readlineSync.keyInYN(`Is this the TO material? `)) {
                appData.to_reward_id = rewardId;
                saveAppData();
                return;
            }
        }
        if (rewardId === appData.from_reward_id) {
            sendWebsocketMessage(`${username} from ${material}`);
        }
        if (rewardId === appData.to_reward_id) {
            sendWebsocketMessage(`${username} to ${material}`);
        }
    });
    twitchClient.connect();
}

function handleCommand(command: string, args: string[], username: string): void
{
    const isStreamer = username.toLowerCase() === appData.channel.toLowerCase();
    switch (command) {
        case '!materials':
            sendTwitchMessage('https://pastebin.com/eAKLkG8u');
            break;
        case '!banmaterial':
            if (isStreamer)
            {
                if (args.length > 0)
                {
                    sendWebsocketMessage(username + ' ban ' + args[0].toLowerCase());
                }
                else
                {
                    sendTwitchMessage('/me Usage: !banmaterial material_name');
                }
            }
            break;
        case '!unbanmaterial':
            if (isStreamer)
            {
                if (args.length > 0)
                {
                    sendWebsocketMessage(username + ' unban ' + args[0].toLowerCase());
                }
                else
                {
                    sendTwitchMessage('/me Usage: !unbanmaterial material_name');
                }
            }
            break;
        default:
            break;
    }
}

function sendWebsocketMessage(msg: string): void
{
    webSocketServer.clients.forEach(client => {
        client.send(msg);
    });
}

function sendTwitchMessage(msg: string): void
{
    if (twitchClient) {
        twitchClient.say(appData.channel, msg);
    }
}
