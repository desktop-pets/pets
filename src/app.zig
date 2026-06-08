const std = @import("std");
const dvui = @import("dvui");
const Backend = @import("glfw-backend");
const zgl = @import("zgl");
const zglfw = Backend.zglfw;

// This can optionally be added in source file to manage how opengl
// errors are handled.
pub const opengl_error_handling = zgl.ErrorHandling.assert;

var window: *zglfw.Window = undefined;

pub fn main(main_init: std.process.Init) !void {
    // I'm keeping demo as I might want to do something with it in the future
    dvui.Examples.show_demo_window = false;

    if (dvui.render_backend.kind != .opengl) @compileError("unsupported renderer");

    try zglfw.init();

    zglfw.windowHint(.context_version_major, 3);
    zglfw.windowHint(.context_version_minor, 3);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);
    zglfw.windowHint(.client_api, .opengl_api);

    // Hints needed for overlay behavior
    zglfw.windowHint(.mouse_passthrough, true);
    zglfw.windowHint(.floating, true);
    zglfw.windowHint(.transparent_framebuffer, true);
    zglfw.windowHint(.resizable, false);
    zglfw.windowHint(.decorated, false);
    zglfw.windowHint(.focused, false);
    zglfw.windowHint(.focus_on_show, false);
    zglfw.windowHint(.maximized, true);
    // Optional
    zglfw.windowHint(.doublebuffer, true);

    window = try zglfw.Window.create(600, 400, "Hello World", null);

    zglfw.makeContextCurrent(window);
    zglfw.swapInterval(1);

    const ns = struct {
        fn getProcAddressWrapper(_: void, symbol_name: [:0]const u8) ?*const anyopaque {
            return zglfw.getProcAddress(symbol_name);
        }
    };

    zgl.loadExtensions({}, ns.getProcAddressWrapper) catch |err| {
        std.debug.print("[GL] zgl.loadExtensions: {s} — some GL >4.1 functions are unavailable on this driver (harmless: we don't use them; only core GL 3.3/4.1 is required)\n", .{@errorName(err)});
    };

    var renderer = try dvui.render_backend.init(main_init.gpa, zglfw.getProcAddress, "330");
    defer renderer.deinit();

    var impl = Backend.init(main_init.io, main_init.gpa, window);
    defer impl.deinit();

    const backend = dvui.Backend.init(&impl, &renderer);
    var win = try dvui.Window.init(@src(), main_init.gpa, backend, .{});
    defer win.deinit();

    while (!window.shouldClose()) {
        zglfw.pollEvents();

        zgl.clearColor(0, 0, 0, 0.2);
        zgl.clear(.{ .color = true });

        // This needs to be called after pollEvents and before or just after win.begin
        impl.addAllEvents(&win);
        try win.begin(impl.nanoTime());

        // only shows the demo if dvui.Examples.show_demo_window is true
        // .full -> .lite or comment out to speed up compile times
        dvui.Examples.demo(.lite);

        _ = try win.end(.{ .manage_backend = false });
        window.swapBuffers();
    }
}
