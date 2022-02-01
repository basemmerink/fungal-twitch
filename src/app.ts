import './env';

import { WebSocketServer } from 'ws';
import {ChatUserstate, Client} from 'tmi.js';

const PORT = 9444;
const LOG_SHIFT_RESULT_TO_TWITCH = process.env.LOG_SHIFT_RESULT_TO_TWITCH;
const TWITCH_CHANNEL = process.env.TWITCH_CHANNEL;

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

const illegalMaterials = [
    'ice_glass', 'wood_player_b2', 'wood', 'wax_b2', 'fuse', 'wood_loose', 'rock_loose', 'ice_ceiling',
    'brick', 'concrete_collapsed', 'tnt', 'tnt_static', 'meteorite', 'sulphur_box2d', 'meteorite_test', 'meteorite_green',
    'steel', 'steel_rust', 'metal_rust_rust', 'metal_rust_barrel_rust', 'plastic', 'aluminium', 'rock_static_box2d',
    'rock_box2d', 'crystal', 'magic_crystal', 'crystal_magic', 'aluminium_oxide', 'meat', 'meat_slime',
    'physics_throw_material_part2', 'ice_melting_perf_killer', 'ice_b2', 'glass_liquidcave', 'neon_tube_purple',
    'snow_b2', 'tube_physics', 'fuse_bright', 'fuse_tnt', 'fuse_holy', 'fungus_loose', 'fungus_loose_green',
    'fungus_loose_trippy', 'cloth_box2d', 'aluminium_robot', 'metal_prop', 'metal_prop_low_restitution',
    'metal_prop_loose', 'metal', 'metal_hard', 'rock_box2d', 'templebrick_box2d_edgetiles', 'rock_box2d_hard',
    'poop_box2d_hard', 'rock_box2d_nohit', 'rock_box2d_nohit_hard', 'item_box2d', 'item_box2d_glass', 'item_box2d_meat',
    'gem_box2d', 'potion_glass_box2d', 'glass_box2d', 'gem_box2d_yellow_sun', 'gem_box2d_yellow_sun_gravity',
    'gem_box2d_darksun', 'gold_box2d', 'bloodgold_box2d', 'metal_nohit', 'metal_chain_nohit', 'metal_wire_nohit',
    'metal_rust', 'metal_rust_barrel', 'bone_box2d', 'gold_b2'
]; // these materials have box2d (physics) properties and cause massive lag (or even crash noita)

let materialFrom = '';
let materialTo = '';

webSocketServer.on('connection', webSocket => {
    console.log('Noita connection opened');
});

twitchClient.on('connected', (addr, port) => console.log('Twitch API initialized'));
twitchClient.on('message', (channel: string, userState: ChatUserstate, message: string, senderIsSelf: boolean) => {
    if (senderIsSelf) {
        return; // ignore our own messages
    }
    const rewardId = userState['custom-reward-id'];
    if (!rewardId) {
        return;
    }
    if (rewardId === process.env.REWARD_FROM_ID) {
        setShiftFrom(message);
    }
    else if (rewardId === process.env.REWARD_TO_ID) {
        setShiftTo(message);
    }
    else {
        console.log(`${userState['display-name']} has redeemed channel points -- ID: ${rewardId} -- Message: ${message}`);
        console.log('If this is the channel points redemption for the from shift, set the value REWARD_FROM_ID in .env');
        console.log('If this is the channel points redemption for the to shift, set the value REWARD_TO_ID in .env');
    }
});
twitchClient.connect();

function setShiftFrom(material: string)
{
    material = material.toLowerCase().trim();
    if (illegalMaterials.indexOf(material) > -1) {
        twitchClient.say(TWITCH_CHANNEL, 'Illegal material: ' + material);
        return;
    }
    materialFrom = material;
    tryShift();
}

function setShiftTo(material: string)
{
    material = material.toLowerCase().trim();
    if (illegalMaterials.indexOf(material) > -1) {
        twitchClient.say(TWITCH_CHANNEL, 'Illegal material: ' + material);
        return;
    }
    materialTo = material;
    tryShift();
}

function tryShift()
{
    if (materialFrom.length > 0 && materialTo.length > 0)
    {
        if (LOG_SHIFT_RESULT_TO_TWITCH)
        {
            twitchClient.say(TWITCH_CHANNEL, `Shifting from ${materialFrom} to ${materialTo}`);
        }
        webSocketServer.clients.forEach(client => {
            client.send(`${materialFrom} ${materialTo}`);
        });
        materialFrom = '';
        materialTo = '';
    }
}

