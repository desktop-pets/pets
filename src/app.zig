const std = @import("std");
const dvui = @import("dvui");
const RaylibBackend = @import("raylib-zig-backend");
pub const rl = @import("raylib");
pub const raygui = @import("raygui");
pub const known_folders = @import("known-folders");

comptime {
    std.debug.assert(@hasDecl(RaylibBackend, "RaylibBackend"));
}

const AppConfig = struct {
    title: [:0]const u8,
    data_dir: [:0]const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, environ: *const std.process.Environ.Map, name: [:0]const u8) !AppConfig {
        const root_dir = (try known_folders.getPath(io, allocator, environ, known_folders.KnownFolder.data)) orelse return error.DataDirNotFound;
        defer allocator.free(root_dir);

        const data_dir = try std.fs.path.joinZ(allocator, &.{ root_dir, app_name });
        const cwd = std.Io.Dir.cwd();
        try cwd.createDirPath(io, data_dir);

        return .{ .title = name, .data_dir = data_dir, .allocator = allocator };
    }

    pub fn deinit(self: AppConfig) void {
        self.allocator.free(self.data_dir);
    }
};

const app_name = "Desktop Pets";
const window_icon_png = @embedFile("zig-favicon.png");

pub fn main(init: std.process.Init) !void {
    if (@import("builtin").os.tag == .windows) {
        try dvui.Backend.Common.windowsAttachConsole();
    }

    const fps = 60;
    const arena: std.mem.Allocator = init.arena.allocator();
    const app_conf = try AppConfig.init(arena, init.io, init.environ_map, "Desktop Pets");
    defer app_conf.deinit();
    errdefer std.debug.print("Data Directory: '{s}'\n", .{app_conf.data_dir});

    rl.setConfigFlags(.{
        .borderless_windowed_mode = true,
        .vsync_hint = true,
        // .window_hidden = dvui.accesskit_enabled,
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

    var backend = RaylibBackend.init(init.io, init.gpa);
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), init.gpa, backend.backend(), .{});
    defer win.deinit();

    const bg_color = rl.colorAlpha(.black, 0.0);
    const border_margin = 1;

    // Make sure window is maximized
    rl.minimizeWindow();
    rl.restoreWindow();

    const texture_path = try std.fs.path.joinZ(arena, &.{ app_conf.data_dir, "scarfy.png" });
    const scarfy = try rl.Texture.init(texture_path);
    defer rl.unloadTexture(scarfy);
    arena.free(texture_path);

    const position = rl.Vector2.init(350.0, 280.0);

    var frame_rect = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(@divFloor(scarfy.width, 7))),
        .height = @as(f32, @floatFromInt(scarfy.height)),
    };

    var current_frame: u32 = 0;
    var frames_counters: u32 = 0;
    const frame_count = 5;
    const frames_speed = 6;

    rl.setTargetFPS(fps);

    while (!rl.windowShouldClose()) {

        // frame work

        frames_counters += 1;
        if (frames_counters >= (fps / frames_speed)) {
            frames_counters = 0;
            current_frame = (current_frame + 1) % frame_count;
            frame_rect.x = @as(f32, @floatFromInt(current_frame)) * @as(f32, @floatFromInt(@divFloor(scarfy.width, 6)));
        }

        rl.beginDrawing();
        {
            rl.clearBackground(bg_color);

            try win.begin(win.backend.nanoTime());
            {
                var b = dvui.box(@src(), .{}, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 10 } });
                defer b.deinit();

                dvui.label(@src(), "dvui works!", .{}, .{});
            }

            rl.drawRectangleLines(border_margin, border_margin, rl.getRenderWidth() - border_margin, rl.getRenderHeight() - border_margin, .red);
            _ = try win.end(.{ .manage_backend = false });

            scarfy.drawRec(frame_rect, position, .white); // Draw part of the texture

            rl.drawRectangle(100, 100, 100, 100, .sky_blue);
        }
        rl.endDrawing();
    }
}
