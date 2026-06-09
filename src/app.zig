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

    var backend = RaylibBackend.init(init.io, init.gpa);
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), init.gpa, backend.backend(), .{});
    defer win.deinit();

    const bg_color = rl.colorAlpha(.black, 0.0);
    const border_margin = 1;

    // Make sure window is maximized
    rl.minimizeWindow();
    rl.restoreWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(bg_color);

        try win.begin(win.backend.nanoTime());
        {
            var b = dvui.box(@src(), .{}, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 10 } });
            defer b.deinit();

            dvui.label(@src(), "dvui works!", .{}, .{});
        }

        rl.drawRectangleLines(border_margin, border_margin, rl.getRenderWidth() - border_margin, rl.getRenderHeight() - border_margin, .red);
        _ = try win.end(.{ .manage_backend = false });

        rl.drawRectangle(100, 100, 100, 100, .sky_blue);

        rl.endDrawing();
    }
}
