const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const res_art = @import("./art_cache.zig");
const locals = @import("./game_config.zig");
const ent = @import("./entity.zig");

pub const Level = struct {
    entities : std.ArrayList(ent.Entity),
    game_camera : rl.Camera2D,
    width_of_tiles : i32,
    tile_start_x : i32,
    tile_start_y : i32,
    coin_spawn_delay : f32,
    coin_spawn_timer : f32,
    coins_collected : u8,

    pub fn unload(self : *Level) void {
        for(self.entities.items) |*entity| {
            entity.flags.deinit();
        }
        self.entities.deinit();
    }
};

pub fn load_level_1(calloc : *std.mem.Allocator) !Level {
    //init player
    var player = ent.Entity.new_player_entity(calloc);
    player.position.x = 0;
    player.position.y = 0;
    try player.add_flag(ent.EntityFlag.IsPlayer);
    try player.add_flag(ent.EntityFlag.IsAnimated);


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

    //Init tile vars
    const width_of_tiles = locals.WINDOW_WIDTH / locals.TILE_WIDTH;
    const tile_start_x = @divTrunc(@as(i32, @intFromFloat(player.position.x)) - 
        locals.WINDOW_WIDTH, @as(i32, @intCast(locals.TILE_WIDTH)));
    const tile_start_y = @as(i32, @intFromFloat(player.position.y)) + locals.ACTOR_HEIGHT;

    return Level {
        .entities = entities,
        .game_camera = camera,
        .tile_start_x = tile_start_x,
        .tile_start_y = tile_start_y,
        .width_of_tiles = width_of_tiles,
        .coin_spawn_delay = 1,
        .coin_spawn_timer = 0.0,
        .coins_collected = 1,
    };
}