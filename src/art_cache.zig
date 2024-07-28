const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const ArtAsset = enum {
    TileSheet,
    Player,
    Coin,
};

pub const ArtCache = struct {
    cache : std.AutoHashMap(ArtAsset, rl.Texture2D),

    pub fn init_and_load(allocator : *const std.mem.Allocator) !ArtCache {
        var art_cache = ArtCache {
            .cache = std.AutoHashMap(ArtAsset, rl.Texture2D).init(allocator.*),
        };

        try art_cache.cache.put(ArtAsset.Coin, rl.LoadTexture("res/coin.png"));
        try art_cache.cache.put(ArtAsset.Player, rl.LoadTexture("res/sprite.png"));
        try art_cache.cache.put(ArtAsset.TileSheet, rl.LoadTexture("res/tiles.png"));

        return art_cache;
    }

    pub fn get_art(self : *ArtCache, art : ArtAsset) *const rl.Texture2D {
        return &self.cache.get(art).?;
    }

    pub fn unload_and_denit(self : *ArtCache) void {
        rl.UnloadTexture(self.get_art(ArtAsset.Coin).*);
        rl.UnloadTexture(self.get_art(ArtAsset.Player).*);
        rl.UnloadTexture(self.get_art(ArtAsset.TileSheet).*);

        self.cache.deinit();
    }
};
