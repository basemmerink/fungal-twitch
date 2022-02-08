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

const appData = existsSync('application_data.json') ?
    JSON.parse(readFileSync('application_data.json').toString()) :
    {
        bot_name: '',
        channel: '',
        access_token: '',
        from_reward_id: '',
        to_reward_id: '',
        banned_materials: []
    };

let validMaterials;
if (existsSync('valid_materials.json')) {
    validMaterials = JSON.parse(readFileSync('valid_materials.json').toString());
} else {
    console.log('File valid_materials.json could not be found, please re-install the mod');
    process.exit(-1);
}


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
    startServer();
});
app.all('/*', (req, res, next) => {
    res.sendFile('src/login.html', {root: __dirname + '/../..'});
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
    startServer();
}

function startServer() {
    const webSocketServer = new WebSocketServer({ port: WS_PORT });
    const twitchClient = Client({
        identity: {
            username: appData.bot_name,
            password: 'oauth:' + appData.access_token
        },
        channels: [appData.channel],
        connection: {
            reconnect: true
        }
    });

    webSocketServer.on('connection', webSocket => {
        console.log();
        console.log('--------------------------------------------------------');
        console.log('Noita connection opened');
        console.log('Use !banmaterial material_name to ban a material');
        console.log('Use !unbanmaterial material_name to unban a material');
        console.log('Only the streamer can input these commands.');
        console.log('--------------------------------------------------------');

        webSocket.on('message', data => {
            twitchClient.say(appData.channel, data.toString());
        });
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
            if (message === '!materials') {
                twitchClient.say(appData.channel, 'https://pastebin.com/eAKLkG8u');
            }
            if (username.toLowerCase() === appData.channel.toLowerCase()) {
                const [command, ...args] = message.split(' ');
                switch (command.toLowerCase()) {
                    case '!banmaterial':
                        if (args.length > 0) {
                            const material = args[0].toLowerCase();
                            if (isValidMaterial(material)) {
                                appData.banned_materials.push(material);
                                saveAppData();
                                twitchClient.say(appData.channel, `Material ${material} is now banned. Use !unbanmaterial ${material} to unban it`);
                            } else {
                                twitchClient.say(appData.channel, 'Illegal material: ' + material);
                            }
                        } else {
                            twitchClient.say(appData.channel, '/me Usage: !banmaterial material_name');
                        }
                        break;
                    case '!unbanmaterial':
                        if (args.length > 0) {
                            const material = args[0].toLowerCase();
                            if (isValidMaterial(material)) {
                                appData.banned_materials = appData.banned_materials.filter(mat => mat !== material);
                                saveAppData();
                                twitchClient.say(appData.channel, `Material ${material} is now unbanned. Use !banmaterial ${material} to ban it again`);
                            } else {
                                twitchClient.say(appData.channel, 'Illegal material: ' + material);
                            }
                        } else {
                            twitchClient.say(appData.channel, '/me Usage: !unbanmaterial material_name');
                        }
                        break;
                }
            }
            return;
        }
        const material = message.toLowerCase().trim();
        let success = false;
        if (appData.from_reward_id.length === 0) {
            console.log(`${username}: ${message}`);
            if (readlineSync.keyInYN(`Is this the FROM material? `)) {
                appData.from_reward_id = rewardId;
                success = true;
                saveAppData();
            }
        }
        if (appData.to_reward_id.length === 0 && !success) {
            console.log(`${username}: ${message}`);
            if (readlineSync.keyInYN(`Is this the TO material? `)) {
                appData.to_reward_id = rewardId;
                saveAppData();
            }
        }
        if (rewardId === appData.from_reward_id) {
            setShiftFrom(material, username);
        }
        else if (rewardId === appData.to_reward_id) {
            setShiftTo(material, username);
        }
    });
    twitchClient.connect();

    function isValidMaterial(material: string): boolean
    {
        return validMaterials.indexOf(material) > -1;
    }

    function mayShift(material: string, username: string): boolean
    {
        if (!isValidMaterial(material)) {
            twitchClient.say(appData.channel, 'Illegal material: ' + material);
            return false;
        }
        if (appData.banned_materials.indexOf(material) > -1) {
            twitchClient.say(appData.channel, 'Banned material: ' + material);
            return false;
        }
        return true;
    }

    function setShiftFrom(material: string, username: string)
    {
        if (!mayShift(material, username)) {
            return;
        }
        sendWebsocketMessage(`${username} from ${material}`);
    }

    function setShiftTo(material: string, username: string)
    {
        if (!mayShift(material, username)) {
            return;
        }
        sendWebsocketMessage(`${username} to ${material}`);
    }

    function sendWebsocketMessage(msg: string): void
    {
        webSocketServer.clients.forEach(client => {
            client.send(msg);
        });
    }
}
