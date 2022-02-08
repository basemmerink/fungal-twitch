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


server.listen(PORT, () => console.log(`Webserver running on port ${PORT}`));

// app.use('/', express.static('../../src/login.html'));
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

    const validMaterials = [
        "fire", "spark", "spark_electric", "flame", "sand_static", "nest_static", "bluefungi_static", "rock_static",
        "water_static", "endslime_static", "slime_static", "spore_pod_stalk", "lavarock_static", "meteorite_static",
        "templerock_static", "steel_static", "rock_static_glow", "snow_static", "ice_static", "ice_acid_static",
        "ice_cold_static", "ice_radioactive_static", "ice_poison_static", "ice_meteor_static", "tubematerial",
        "glass_static", "waterrock", "ice_glass_b2", "glass_brittle", "snowrock_static", "concrete_static", "wood_static",
        "cheese_static", "smoke", "cloud", "cloud_lighter", "smoke_explosion", "steam", "acid_gas", "acid_gas_static",
        "smoke_static", "blood_cold_vapour", "sand_herb_vapour", "radioactive_gas", "radioactive_gas_static",
        "magic_gas_hp_regeneration", "rainbow_gas", "water", "water_temp", "water_ice", "water_swamp", "oil", "alcohol",
        "sima", "juhannussima", "alcohol_gas", "magic_liquid", "material_confusion", "material_darkness",
        "material_rainbow", "magic_liquid_movement_faster", "magic_liquid_faster_levitation",
        "magic_liquid_faster_levitation_and_movement", "magic_liquid_worm_attractor", "magic_liquid_protection_all",
        "magic_liquid_mana_regeneration", "magic_liquid_unstable_teleportation", "magic_liquid_teleportation",
        "magic_liquid_hp_regeneration", "magic_liquid_hp_regeneration_unstable", "magic_liquid_polymorph",
        "magic_liquid_random_polymorph", "magic_liquid_unstable_polymorph", "magic_liquid_berserk", "magic_liquid_charm",
        "magic_liquid_invisibility", "cloud_radioactive", "cloud_blood", "cloud_slime", "swamp", "mud", "blood",
        "blood_fading", "blood_fungi", "blood_worm", "porridge", "blood_cold", "radioactive_liquid",
        "radioactive_liquid_fading", "plasma_fading", "gold_molten", "wax_molten", "silver_molten", "copper_molten",
        "brass_molten", "glass_molten", "glass_broken_molten", "steel_molten", "creepy_liquid", "cement", "concrete_sand",
        "sand", "bone", "soil", "sandstone", "fungisoil", "honey", "glue", "slime", "slush", "vomit", "explosion_dirt",
        "vine", "root", "snow", "snow_sticky", "rotten_meat", "meat_slime_sand", "rotten_meat_radioactive", "ice",
        "sand_herb", "wax", "gold", "silver", "copper", "brass", "diamond", "coal", "sulphur", "salt", "sodium_unstable",
        "gunpowder", "gunpowder_explosive", "gunpowder_tnt", "gunpowder_unstable", "gunpowder_unstable_big",
        "monster_powder_test", "rat_powder", "fungus_powder", "orb_powder", "gunpowder_unstable_boss_limbs", "plastic_red",
        "plastic_red_molten", "grass", "grass_ice", "grass_dry", "fungi", "spore", "moss", "mushroom_seed", "plant_seed",
        "acid", "lava", "wood_player", "trailer_text", "urine", "poo", "rocket_particles", "glass", "glass_broken",
        "blood_thick", "fungal_shift_particle_fx", "fire_blue", "spark_green", "spark_green_bright", "spark_blue",
        "spark_blue_dark", "spark_red", "spark_red_bright", "spark_white", "spark_white_bright", "spark_yellow",
        "spark_purple", "spark_purple_bright", "spark_player", "spark_teal", "sand_static_rainforest",
        "sand_static_rainforest_dark", "bone_static", "rust_static", "sand_static_bright", "sand_static_red",
        "rock_static_intro", "rock_static_trip_secret", "rock_static_trip_secret2", "rock_static_cursed",
        "rock_static_purple", "rock_hard", "rock_static_fungal", "wood_tree", "rock_static_noedge", "rock_hard_border",
        "rock_magic_gate", "rock_magic_bottom", "rock_eroding", "rock_vault", "coal_static", "rock_static_grey",
        "rock_static_radioactive", "rock_static_cursed_green", "rock_static_poison", "skullrock", "rock_static_wet",
        "templebrick_static", "templebrick_static_broken", "templebrick_static_soft", "templebrick_noedge_static",
        "templerock_soft", "templebrick_thick_static", "templebrick_thick_static_noedge", "templeslab_static",
        "templeslab_crumbling_static", "templebrickdark_static", "wizardstone", "templebrick_golden_static",
        "templebrick_diamond_static", "templebrick_static_ruined", "glowstone", "glowstone_altar",
        "glowstone_altar_hdr", "glowstone_potion", "templebrick_red", "templebrick_moss_static", "the_end",
        "steelmoss_static", "steel_rusted_no_holes", "steel_grey_static", "steelfrost_static", "steelmoss_slanted",
        "steelsmoke_static", "steelpipe_static", "steel_static_strong", "steel_static_unmeltable",
        "rock_static_intro_breakable", "ice_blood_static", "ice_slime_static", "wood_static_wet", "root_growth",
        "wood_burns_forever", "creepy_liquid_emitter", "gold_static", "gold_static_radioactive", "gold_static_dark",
        "wood_static_vertical", "wood_static_gas", "corruption_static", "smoke_magic", "steam_trailer", "poison_gas",
        "fungal_gas", "poo_gas", "water_fading", "water_salt", "void_liquid", "liquid_fire", "liquid_fire_weak",
        "midas_precursor", "midas", "blood_fading_slow", "poison", "cursed_liquid", "radioactive_liquid_yellow",
        "plasma_fading_bright", "plasma_fading_green", "plasma_fading_pink", "steel_static_molten",
        "steelmoss_slanted_molten", "steelmoss_static_molten", "steelsmoke_static_molten", "metal_sand_molten",
        "metal_molten", "metal_rust_molten", "metal_nohit_molten", "aluminium_molten", "aluminium_robot_molten",
        "metal_prop_molten", "steel_rust_molten", "aluminium_oxide_molten", "sand_blue", "sand_surface", "lavasand",
        "sand_petrify", "soil_lush", "soil_lush_dark", "soil_dead", "soil_dark", "sandstone_surface", "slime_green",
        "slime_yellow", "pea_soup", "endslime", "endslime_blood", "gold_radioactive", "steel_sand", "metal_sand", "sodium",
        "purifying_powder", "burning_powder", "fungus_powder_bad", "shock_powder", "fungi_green", "grass_dark",
        "fungi_creeping", "fungi_creeping_secret", "peat", "moss_rust"
    ]; // these materials have box2d (physics) properties and cause massive lag (or even crash noita)

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
