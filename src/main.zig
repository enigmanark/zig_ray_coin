const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const locals = @import("./game_config.zig");
const res_art = @import("./art_cache.zig");
const ent = @import("./entity.zig");
const sys = @import("./systems.zig");
const loader = @import("./level_loader.zig");

pub fn main() !void {
    //Setup window
    rl.InitWindow(locals.WINDOW_WIDTH, locals.WINDOW_HEIGHT, locals.WINDOW_TITLE);
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);
    rl.SetExitKey(rl.KEY_NULL);

    //make allocators
    var resource_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = resource_allocator.allocator();
    defer _ = resource_allocator.deinit();
    
    var content_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var calloc = content_allocator.allocator();
    defer _ = content_allocator.deinit();

    //load resources
    var art_cache = try res_art.ArtCache.init_and_load(&gpa);
    defer art_cache.unload_and_denit();

    //load level
    var current_level = try loader.load_title_state(&calloc);
    defer current_level.unload();

    //Start main loop
    while(!rl.WindowShouldClose()) {
        const delta = rl.GetFrameTime();
        //Spawn coins
        try sys.sys_spawn_coins(&current_level, &calloc, delta);

        //Update here some stuff here
        for(current_level.entities.items) |*entity| {
            sys.sys_update_player(entity, delta);
            sys.sys_update_coin(entity, delta);
            sys.sys_update_anims(entity, delta);
        }

        //Update coin collision
        sys.sys_update_coin_collision(&current_level);

        //Clean up dead entities
        try sys.cleanup_dead_entities(&current_level, &calloc);
        
        //If we're on the title state, check if we should enter playstate
        if(current_level.engine_state == loader.EngineState.TitleState) {
            if(rl.IsKeyPressed(rl.KEY_SPACE) or rl.IsKeyPressed(rl.KEY_ENTER)) {
                current_level.unload();
                current_level = try loader.load_level_1(&calloc);
            }
        }

        //Render
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        if(current_level.game_camera != null) {
            rl.BeginMode2D(current_level.game_camera.?);
        }
        

        sys.render_tiles(&current_level, &art_cache);
        
        //Render here
        for(current_level.entities.items) |*entity| {
            sys.sys_render_coin(entity, &art_cache);
            sys.sys_render_player(entity, &art_cache);
            sys.sys_render_display_text(entity);
        }

        sys.sys_render_coin_text(&current_level);

        if(current_level.game_camera != null) {
            rl.EndMode2D();
        }
        
        rl.EndDrawing();
    }
}
