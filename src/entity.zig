const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const res_art = @import("./art_cache.zig");
const locals = @import("./game_config.zig");

pub const EntityFlag = enum {
    IsPlayer,
    IsCoin,
    IsAnimated,
};

pub const Entity = struct {
    alive : bool,
    flags : std.ArrayList(EntityFlag),
    position : rl.Vector2,
    width : f32,
    height : f32,
    art : res_art.ArtAsset,
    current_h_frame : i8,
    anim_delay : f32,
    anim_timer : f32,
    source_x : f32,
    source_y : f32,
    source_width : f32,
    source_height : f32,

    pub fn add_flag(self : *Entity, flag : EntityFlag) !void {
        try self.flags.append(flag);
    }

    pub fn new_coin_entity(allocator : *std.mem.Allocator) Entity {
        var coin = new_default_entity(allocator);
        coin.position.x = 0;
        coin.position.y = - 300;
        coin.anim_delay = 0.5;
        coin.art = res_art.ArtAsset.Coin;
        coin.width = locals.COIN_WIDTH;
        coin.height = locals.COIN_HEIGHT;
        coin.source_height = locals.COIN_HEIGHT;
        coin.source_width = locals.COIN_WIDTH;

        return coin;
    }

    pub fn new_player_entity(allocator : *std.mem.Allocator) Entity {
        var entity = new_default_entity(allocator);
        entity.anim_delay = 0.5;
        entity.art = res_art.ArtAsset.Player;
        entity.width = locals.ACTOR_WIDTH;
        entity.height = locals.ACTOR_HEIGHT;
        entity.source_height = locals.ACTOR_HEIGHT;
        entity.source_width = locals.ACTOR_WIDTH;

        return entity;
    }

    pub fn new_default_entity(allocator : *std.mem.Allocator) Entity {
        return Entity {
            .alive = true,
            .flags = std.ArrayList(EntityFlag).init(allocator.*),
            .position = rl.Vector2 {
                .x = 0, 
                .y = 0
            },
            .width = 0,
            .height = 0,
            .art = res_art.ArtAsset.Player,
            .current_h_frame = 0,
            .anim_delay = 0,
            .anim_timer = 0,
            .source_x = 0,
            .source_y = 0,
            .source_width = 0,
            .source_height = 0,
        };
    }

    pub fn get_source_rect(self : *Entity) rl.Rectangle {
        const source_x : f32 = @as(f32, @floatFromInt(self.current_h_frame)) * self.source_width;
        const source_y : f32 = 0;
        const s_width  : f32 = self.source_width;
        const s_height : f32 = self.source_height;
        return rl.Rectangle {
            .x = source_x ,
            .y = source_y,
            .width = s_width,
            .height = s_height,
        };
    }

    pub fn get_dest_rect(self : *Entity) rl.Rectangle {
        const dest_x = self.position.x;
        const dest_y = self.position.y;
        const d_width = self.width;
        const d_height = self.height;
        return rl.Rectangle {
            .x = dest_x,
            .y = dest_y,
            .width = d_width,
            .height = d_height,
        };        
    }

    pub fn unload_and_denit(self : *Entity) void {
        self.flags.deinit();
    }
};