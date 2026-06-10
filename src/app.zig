const std = @import("std");
const dvui = @import("dvui");
const RaylibBackend = @import("raylib-zig-backend");
pub const rl = @import("raylib");
pub const raygui = @import("raygui");

comptime {
    std.debug.assert(@hasDecl(RaylibBackend, "RaylibBackend"));
}

const window_icon_png = @embedFile("zig-favicon.png");

pub fn main(init: std.process.Init) !void {
    if (@import("builtin").os.tag == .windows) {
        try dvui.Backend.Common.windowsAttachConsole();
    }

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

    rl.initWindow(800, 600, "Desktop Pets");
    defer rl.closeWindow();

    const monitor = rl.getCurrentMonitor();
    rl.setWindowSize(rl.getMonitorWidth(monitor), rl.getMonitorHeight(monitor) - 1);

    var backend = RaylibBackend.init(init.io, init.gpa);
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), init.gpa, backend.backend(), .{});
    defer win.deinit();

    const bgColor = rl.colorAlpha(.black, 0.2);
    rl.minimizeWindow();
    rl.restoreWindow();

    const position = rl.Vector2.init(350.0, 280.0);
    const scarfy = try rl.Texture.init("scarfy.png");
    defer rl.unloadTexture(scarfy);

    var frameRec = rl.Rectangle{
        .width = @as(f32, @floatFromInt(@divFloor(scarfy.width, 7))),
        .height = @as(f32, @floatFromInt(scarfy.height)),
        .x = 100,
        .y = 100,
    };

    var currentFrame: u32 = 0;
    var framesCounters: u32 = 0;
    const framesSpeed = 8;

    rl.setTargetFPS(60);

    std.debug.print("before loop", .{});
    while (!rl.windowShouldClose()) {

        // frame work
        framesCounters += 1;
        if (framesCounters >= (60 / framesSpeed)) {
            framesCounters = 0;
            currentFrame += 1;

            if (currentFrame > 5) {
                currentFrame = 0;
            }

            frameRec.x = @as(f32, @floatFromInt(currentFrame)) * @as(f32, @floatFromInt(@divFloor(scarfy.width, 6)));
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        try win.begin(win.backend.nanoTime());
        {
            var b = dvui.box(@src(), .{}, .{ .expand = .horizontal, .margin = .{ .x = 10 } });
            defer b.deinit();

            dvui.label(@src(), "dvui works!", .{}, .{});
        }

        rl.drawRectangleLines(0, 0, rl.getRenderWidth() - 5, rl.getRenderHeight() - 5, .red);
        _ = try win.end(.{ .manage_backend = false });

        scarfy.drawRec(frameRec, position, .white); // Draw part of the texture

    }
}
