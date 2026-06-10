const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    {
        const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .raylib_zig });

        const name = "app";

        const file = b.path("src/app.zig");

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = file,
                .target = b.resolveTargetQuery(.{ .os_tag = .windows }),
                .optimize = optimize,
            }),
        });
        exe.subsystem = .Windows;

        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });

        const raylib = raylib_dep.module("raylib");
        const raygui = raylib_dep.module("raygui");
        const raylib_artifact = raylib_dep.artifact("raylib");

        exe.root_module.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);

        exe.root_module.addImport("dvui", dvui_dep.module("dvui_raylib_zig"));
        exe.root_module.addImport("raylib-zig-backend", dvui_dep.module("raylib_zig")); // for zls

        const known_folders = b.dependency("known_folders", .{
            .target = target,
            .optimize = optimize,
        }).module("known-folders");

        exe.root_module.addImport("known-folders", known_folders);

        const compile_step = b.step("compile-" ++ name, "Compile " ++ name);
        compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
        b.getInstallStep().dependOn(compile_step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(compile_step);

        const run_step = b.step(name, "Run " ++ name);
        run_step.dependOn(&run_cmd.step);
    }
}
