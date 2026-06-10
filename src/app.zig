const std = @import("std");
const rl = @import("raylib");
const raygui = @import("raygui");

const AppConfig = @import("config.zig").AppConfig;


const SpriteAnim = struct {
    rows: i32,
    cols: i32,
    frame_idx: i32,
    frame_count: i32,
    frame_rect: rl.Rectangle,
    texture: rl.Texture,

    pub fn init(texture_path: [:0]const u8, frame_count: i32, rows: i32, cols: i32) !SpriteAnim {
        const texture = try rl.Texture.init(texture_path);
        const frame_rect = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(@divFloor(texture.width, cols))),
            .height = @as(f32, @floatFromInt(@divFloor(texture.height, rows))),
        };
        return .{ .frame_count = frame_count, .rows = rows, .cols = cols, .frame_idx = 0, .frame_rect = frame_rect, .texture = texture };
    }
    pub fn deinit(self: SpriteAnim) void {
        rl.unloadTexture(self.texture);
    }
    pub fn advance(self: *SpriteAnim) void {
        self.frame_idx = @rem(self.frame_idx + 1, self.frame_count);
        self.frame_rect.x = @as(f32, @floatFromInt(@rem(self.frame_idx, self.cols))) * self.frame_rect.width;
        self.frame_rect.y = @as(f32, @floatFromInt(@divFloor(self.frame_idx, self.cols))) * self.frame_rect.height;
    }
    pub fn draw(self: *SpriteAnim, position: rl.Vector2, tint: rl.Color) void {
        self.texture.drawRec(self.frame_rect, position, tint);
    }
};

pub fn main(init: std.process.Init) !void {

    const fps = 60;
    const animation_speed = 6;
    const bg_color = rl.colorAlpha(.black, 0.0);
    const border_margin = 1;
    const arena: std.mem.Allocator = init.arena.allocator();

    const app_conf = try AppConfig.init(arena, init.io, init.environ_map, "Desktop Pets");
    defer app_conf.deinit();
    std.debug.print("Data Directory: '{s}'\n", .{app_conf.data_dir});

    rl.setConfigFlags(.{
        .borderless_windowed_mode = true,
        .vsync_hint = true,
        .window_mouse_passthrough = true,
        .window_unfocused = true,
        .window_maximized = true,
        .window_transparent = true,
        .window_undecorated = true,
        .window_topmost = true,
        .window_resizable = true,
        .fullscreen_mode = false,
    });

    rl.initWindow(800, 600, app_conf.title);
    defer rl.closeWindow();



    rl.minimizeWindow();
    rl.restoreWindow();
    rl.setTargetFPS(fps);

    const scarfy_path = try std.fs.path.joinZ(arena, &.{ app_conf.data_dir, "scarfy.png" });
    var scarfy: SpriteAnim = try .init(scarfy_path, 6, 1, 6);
    defer scarfy.deinit();
    arena.free(scarfy_path);

    const slime_path = try std.fs.path.joinZ(arena, &.{ app_conf.data_dir, "slime_green.png" });
    var slime: SpriteAnim = try .init(slime_path, 12, 3, 4);
    defer slime.deinit();
    arena.free(slime_path);

    var scarfy_pos = rl.Vector2.init(350.0, 280.0);
    const slime_pos = rl.Vector2.init(270.0, 420.0);

    var frames_counters: u32 = 0;

    while (!rl.windowShouldClose()) {
        frames_counters += 1;
        if (frames_counters >= (fps / animation_speed)) {
            frames_counters = 0;
            scarfy.advance();
            scarfy_pos.x = @rem(scarfy_pos.x + 10, @as(f32, @floatFromInt(rl.getRenderWidth())));
            slime.advance();
        }

        rl.beginDrawing();
        {
            rl.clearBackground(bg_color);

            rl.drawRectangleLines(
                border_margin,
                border_margin,
                rl.getRenderWidth() - border_margin,
                rl.getRenderHeight() - border_margin, .red
            );

            scarfy.draw(scarfy_pos, .white);
            slime.draw(slime_pos, .white);
        }
        rl.endDrawing();
    }
}
