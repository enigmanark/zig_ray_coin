const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const res_art = @import("./art_cache.zig");
const locals = @import("./game_config.zig");
const ent = @import("./entity.zig");

pub const EngineState = enum {
    TitleState,
    PlayState,
};

pub const Level = struct {
    engine_state : EngineState,
    entities : std.ArrayList(ent.Entity),
    game_camera : ?rl.Camera2D,
    width_of_tiles : ?i32,
    tile_start_x : ?i32,
    tile_start_y : ?i32,
    coin_spawn_delay : ?f32,
    coin_spawn_timer : ?f32,
    coins_collected : ?u8,


    pub fn unload(self : *Level) void {
        for(self.entities.items) |*entity| {
            entity.flags.deinit();
        }
        self.entities.deinit();
    }
};

pub fn load_title_state(calloc : *std.mem.Allocator) !Level {
    //init title text
    var title_text = ent.Entity.new_default_entity(calloc);
    title_text.display_text_size = locals.TITLE_SIZE;
    title_text.display_text = "Zigray Coin";
    
    const title_text_size = rl.MeasureText(title_text.display_text.ptr, locals.TITLE_SIZE);
    title_text.position.x = @as(f32, @floatFromInt(locals.WINDOW_WIDTH / 2)) - 
        @as(f32, @floatFromInt(@divTrunc(title_text_size, 2)));
    title_text.position.y = locals.WINDOW_HEIGHT / 2 - 75;

    title_text.add_flag(ent.EntityFlag.IsDisplayText);

    var entities = std.ArrayList(ent.Entity).init(calloc.*);
    try entities.append(title_text);

    return Level {
        .engine_state = EngineState.TitleState,
        .entities = entities,
        .game_camera = null,
        .tile_start_x = null,
        .tile_start_y = null,
        .width_of_tiles = null,
        .coin_spawn_delay = null,
        .coin_spawn_timer = null,
        .coins_collected = null,
    };
}

pub fn load_level_1(calloc : *std.mem.Allocator) !Level {
    //init player
    var player = ent.Entity.new_player_entity(calloc);
    player.position.x = 0;
    player.position.y = 0;
    player.add_flag(ent.EntityFlag.IsPlayer);
    player.add_flag(ent.EntityFlag.IsAnimated);


    //init camera
    const zoom = locals.ZOOM_LEVEL;
    const camera = rl.Camera2D {
        .offset = rl.Vector2 {
            .x = locals.WINDOW_WIDTH / 2,
            .y = locals.WINDOW_HEIGHT - 110,
        },
        .target = player.position,
        .zoom = zoom,
    };

    //Init entities
    var entities = std.ArrayList(ent.Entity).init(calloc.*);

    //add player to entity array of level
    try entities.append(player);

    //Find shortcut to player with a pointer and assign to level
    var player_shortcut : *ent.Entity = undefined;
    for (entities.items) |entity| {
        for (entity.flags.items) |flag| {
            if(flag == ent.EntityFlag.IsPlayer) {
                player_shortcut = @constCast(&entity);
            }
        }
    }
 

    //Init tile vars
    const width_of_tiles = locals.WINDOW_WIDTH / locals.TILE_WIDTH;
    const tile_start_x = @divTrunc(@as(i32, @intFromFloat(player.position.x)) - 
        locals.WINDOW_WIDTH, @as(i32, @intCast(locals.TILE_WIDTH)));
    const tile_start_y = @as(i32, @intFromFloat(player.position.y)) + locals.ACTOR_HEIGHT;

    return Level {
        .engine_state = EngineState.PlayState,
        .entities = entities,
        .game_camera = camera,
        .tile_start_x = tile_start_x,
        .tile_start_y = tile_start_y,
        .width_of_tiles = width_of_tiles,
        .coin_spawn_delay = 1,
        .coin_spawn_timer = 0.0,
        .coins_collected = 0,
    };
}