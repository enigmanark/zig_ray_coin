const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const res_art = @import("./art_cache.zig");
const locals = @import("./game_config.zig");
const ent = @import("./entity.zig");
const loader = @import("./level_loader.zig");

pub fn sys_render_display_text(entity : *ent.Entity) void {
    for(entity.flags.items) |flag| {
        if(flag == ent.EntityFlag.IsDisplayText) {
            rl.DrawText(
                entity.display_text.ptr, 
                @as(c_int, @intFromFloat(entity.position.x)),
                @as(c_int, @intFromFloat(entity.position.y)),
                @as(c_int, @intCast(entity.display_text_size)),
                rl.WHITE
            );
        }
    }
}

pub fn sys_render_coin_text(level : *loader.Level) void {
    if(level.coins_collected == null) {
        return;
    }
    std.debug.assert(level.coins_collected.? <= locals.MAX_POSSIBLE_COINS);
    const count = comptime std.fmt.count("Coins: {}", .{locals.MAX_POSSIBLE_COINS});
    
    var buf : [count + 1]u8 = undefined;

    const string_text = std.fmt.bufPrintZ(&buf, "Coins: {}", .{level.coins_collected.?}) catch unreachable;
    const x = 0 - locals.GAME_WIDTH / 2;
    const y = 0 - locals.GAME_HEIGHT + 37;
    rl.DrawText(string_text.ptr, x, y, locals.COIN_TEXT_FONT_SIZE, rl.WHITE);
}

//Spawn coins based on a timer at random x positions on the screen, clamped
pub fn sys_spawn_coins(level : *loader.Level, calloc : *std.mem.Allocator, delta : f32) !void {
    if(level.coin_spawn_timer == null) {
        return;
    }
    level.coin_spawn_timer.? += delta;
    if(level.coin_spawn_timer.? >= level.coin_spawn_delay.?) {
        level.coin_spawn_timer = 0.0;

        var coin_entity = ent.Entity.new_coin_entity(calloc);
        const left_side : f32 = 0 - (locals.GAME_WIDTH / 2);
        const right_side : f32 = 0 + (locals.GAME_WIDTH / 2);
        coin_entity.position.x = @as(f32, @floatFromInt(rl.GetRandomValue(left_side, right_side)));
        coin_entity.position.y = -locals.GAME_HEIGHT;

        coin_entity.add_flag(ent.EntityFlag.IsCoin);
        coin_entity.add_flag(ent.EntityFlag.IsAnimated);
        try level.entities.append(coin_entity);
    }
}

//Any entity that has it's alive flag set to false will be cleaned up
pub fn cleanup_dead_entities(level : *loader.Level, calloc : *std.mem.Allocator) !void {
    var alive_entities = std.ArrayList(ent.Entity).init(calloc.*);

    for (0..level.entities.items.len) |i| {
        var entity : ent.Entity = level.entities.items[i];
        if(entity.alive) {
            try alive_entities.append(entity);
        }
        else {
            entity.unload_and_denit();
        }
    }

    level.entities.deinit();
    level.entities = alive_entities;
}

//Update all entity animations, must have the tag isAnimated
pub fn sys_update_anims(entity : *ent.Entity, delta : f32) void {
    //update anims
    entity.anim_timer += delta;
    if(entity.anim_timer >= entity.anim_delay) {
        entity.anim_timer = 0;
        entity.current_h_frame += 1;
        if(entity.current_h_frame >= 2) {
            entity.current_h_frame = 0;
        }
    }
}

//Update player's movement
pub fn sys_update_player(player : *ent.Entity, delta : f32) void {
    for (player.flags.items) |flag| {
        if(flag == ent.EntityFlag.IsPlayer) {
            //update movement
            var move_x : f32 = 0;
            if(rl.IsKeyDown(rl.KEY_A)) {
                move_x += -1;
            }

            if(rl.IsKeyDown(rl.KEY_D)) {
                move_x += 1;
            }

            player.position.x += move_x * locals.PLAYER_MOVE_SPEED * delta;

            //clamp to screen
            const left_side : f32 = 0 - (locals.GAME_WIDTH / 2);
            const right_side : f32 = 0 + (locals.GAME_WIDTH / 2);
            player.position.x = std.math.clamp(player.position.x, left_side, right_side - locals.ACTOR_WIDTH);
        }
    }

}

//Update player collision with coins
pub fn sys_update_coin_collision(level : *loader.Level) void {
    const entities = &level.entities;
    var player : ?*ent.Entity = null;
    for (entities.items) |*entity| {
        for (entity.flags.items) |flag| {
            if(flag == ent.EntityFlag.IsPlayer) {
                player = entity;
                break;
            }

        }
        if(player != null) {
            break;
        }
    }

    //If player is null, we're probably on the title screen or something
    if(player != null) {
        const player_rect = rl.Rectangle {
            .x = player.?.position.x,
            .y = player.?.position.y,
            .width = player.?.width,
            .height = player.?.height,
        };

        for(entities.items) |*entity| {
            for (entity.flags.items) |flag| {
                if(flag == ent.EntityFlag.IsCoin) {
                    const coin_rect = rl.Rectangle {
                        .x = entity.position.x,
                        .y = entity.position.y,
                        .width = entity.width,
                        .height = entity.height,
                    };

                    if(rl.CheckCollisionRecs(player_rect, coin_rect)) {
                        level.coins_collected.? += 1;
                        entity.alive = false;
                    }
                }
            }
        }
    }
}

//Update coin movement and also set them to not alive if they go to far offscreen
pub fn sys_update_coin(coin : *ent.Entity, delta : f32) void {
    for (coin.flags.items) |flag| {
        if(flag == ent.EntityFlag.IsCoin) {
            coin.position.y += 1.0 * locals.COIN_MOVE_SPEED * delta;
            if(coin.position.y > 100) {
                coin.alive = false;
            }
        }
    }
    
}

//Render the coin
pub fn sys_render_coin(coin : *ent.Entity, art_cache : *res_art.ArtCache) void {
    for( coin.flags.items) |flag| {
        if(flag == ent.EntityFlag.IsCoin) {
            //draw coin
            rl.DrawTexturePro(
                art_cache.get_art(coin.art).*, 
                coin.get_source_rect(),
                coin.get_dest_rect(), 
                rl.Vector2 {
                    .x = 0,
                    .y = 0,
                }, 
                0, 
                rl.WHITE
            );
        }
    }
}

//Render tiles
pub fn render_tiles(level : *loader.Level, art_cache : *res_art.ArtCache) void {
    if(level.width_of_tiles == null) {
        return;
    }

    //Draw tiles
    var i = level.tile_start_x.?;
    while(i < level.width_of_tiles.?) : (i += 1) {
        const texture = art_cache.get_art(res_art.ArtAsset.TileSheet);
        const i_as_int : i32 = @intCast(i);
        const x : i32  = i_as_int * locals.TILE_WIDTH;
        rl.DrawTexture(texture.*, x, level.tile_start_y.?, rl.WHITE);
    }
}

//Render the player
pub fn sys_render_player(player : *ent.Entity, art_cache : *res_art.ArtCache) void {
    for (player.flags.items) |flag| {
        if(flag == ent.EntityFlag.IsPlayer) {
            //Draw player
            rl.DrawTexturePro(
                art_cache.get_art(player.art).*, 
                player.get_source_rect(), 
                player.get_dest_rect(),
                rl.Vector2{
                    .x = 0,
                    .y = 0,
                }, 
                0,
                rl.WHITE,
            );
        }
    } 

}