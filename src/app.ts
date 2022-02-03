import './env';

import {WebSocketServer} from 'ws';
import {ChatUserstate, Client} from 'tmi.js';

const PORT = 9444;
const LOG_SHIFT_RESULT_TO_TWITCH = process.env.LOG_SHIFT_RESULT_TO_TWITCH === 'true';
const TWITCH_CHANNEL = process.env.TWITCH_CHANNEL;
const COOLDOWN_PER_USER_IN_SECONDS = parseInt(process.env.COOLDOWN_PER_USER_IN_SECONDS);

const webSocketServer = new WebSocketServer({ port: PORT });
const twitchClient = Client({
    identity: {
        username: process.env.TWITCH_BOT_NAME,
        password: process.env.TWITCH_OAUTH_TOKEN
    },
    channels: [TWITCH_CHANNEL],
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

let materialFrom = '';
let materialTo = '';
let bannedMaterials = [];
let userFrom = '';
let userTo = '';
let users = new Map<string, number>();

webSocketServer.on('connection', webSocket => {
    console.log('Noita connection opened');
    console.log('Use !banmaterial material_name to ban a material');
    console.log('Use !unbanmaterial material_name to unban a material');
    console.log('Only the streamer can input these commands.');
});

twitchClient.on('connected', (addr, port) => console.log('Twitch API initialized'));
twitchClient.on('message', (channel: string, userState: ChatUserstate, message: string, senderIsSelf: boolean) => {
    if (senderIsSelf) {
        return; // ignore our own messages
    }
    const rewardId = userState['custom-reward-id'];
    const username = userState['display-name'];
    if (!rewardId) {
        if (message === '!materials') {
            twitchClient.say(TWITCH_CHANNEL, 'https://pastebin.com/eAKLkG8u');
        }
        if (username.toLowerCase() === TWITCH_CHANNEL.toLowerCase()) {
            const [command, ...args] = message.split(' ');
            switch (command.toLowerCase()) {
                case '!banmaterial':
                    if (args.length > 0) {
                        const material = args[0].toLowerCase();
                        bannedMaterials.push(material);
                        twitchClient.say(TWITCH_CHANNEL, `Material ${material} is now banned. Use !unbanmaterial ${material} to unban it`);
                    } else {
                        twitchClient.say(TWITCH_CHANNEL, '/me Usage: !banmaterial material_name');
                    }
                    break;
                case '!unbanmaterial':
                    if (args.length > 0) {
                        const material = args[0].toLowerCase();
                        bannedMaterials = bannedMaterials.filter(mat => mat !== material);
                        twitchClient.say(TWITCH_CHANNEL, `Material ${material} is now unbanned. Use !banmaterial ${material} to ban it again`);
                    } else {
                        twitchClient.say(TWITCH_CHANNEL, '/me Usage: !unbanmaterial material_name');
                    }
                    break;
            }
        }
        return;
    }
    const material = message.toLowerCase().trim();
    if (rewardId === process.env.REWARD_FROM_ID) {
        setShiftFrom(material, username);
    }
    else if (rewardId === process.env.REWARD_TO_ID) {
        setShiftTo(material, username);
    }
    else {
        console.log(`${userState['display-name']} has redeemed channel points -- ID: ${rewardId} -- Message: ${message}`);
        console.log('If this is the channel points redemption for the from shift, set the value REWARD_FROM_ID in .env');
        console.log('If this is the channel points redemption for the to shift, set the value REWARD_TO_ID in .env');
    }
});
twitchClient.connect();

function mayShift(material: string, username: string): boolean
{
    if (!userCanShift(username)) {
        twitchClient.say(TWITCH_CHANNEL, username + ', your cooldown is ' + Math.ceil((users.get(username) + COOLDOWN_PER_USER_IN_SECONDS * 1000 - Date.now()) / 1000) + ' seconds');
        return false;
    }
    if (validMaterials.indexOf(material) === -1) {
        twitchClient.say(TWITCH_CHANNEL, 'Illegal material: ' + material);
        return false;
    }
    if (bannedMaterials.indexOf(material) > -1) {
        twitchClient.say(TWITCH_CHANNEL, 'Banned material: ' + material);
        return false;
    }
    return true;
}

function userCanShift(username: string): boolean
{
    if (!users.has(username)) {
        return true;
    }
    return users.get(username) + COOLDOWN_PER_USER_IN_SECONDS * 1000 < Date.now();
}

function setShiftFrom(material: string, username: string)
{
    if (!mayShift(material, username)) {
        return;
    }
    materialFrom = material;
    userFrom = username;
    tryShift();
}

function setShiftTo(material: string, username: string)
{
    if (!mayShift(material, username)) {
        return;
    }
    materialTo = material;
    userTo = username;
    tryShift();
}

function tryShift()
{
    if (materialFrom.length > 0 && materialTo.length > 0)
    {
        if (LOG_SHIFT_RESULT_TO_TWITCH)
        {
            twitchClient.say(TWITCH_CHANNEL, `Shifting from ${materialFrom} to ${materialTo}`);
            console.log(`Shifting from ${materialFrom} to ${materialTo}`);
        }
        webSocketServer.clients.forEach(client => {
            client.send(`${materialFrom} ${materialTo}`);
        });
        materialFrom = '';
        materialTo = '';
        users.set(userFrom, Date.now());
        users.set(userTo, Date.now());
    }
}
