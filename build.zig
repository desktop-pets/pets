const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .glfw });

    const zgl = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });

    const name = "glfw-app";
    const file = b.path("src/app.zig");

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = file,
            .target = target,
            .optimize = optimize,
        }),
        .use_llvm = true,
    });

    exe.root_module.addImport("dvui", dvui_dep.module("dvui_glfw"));
    exe.root_module.addImport("glfw-backend", dvui_dep.module("glfw")); // for zls
    exe.root_module.addImport("zgl", zgl.module("zgl"));

    const compile_step = b.step("compile-" ++ name, "Compile " ++ name);
    compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
    b.getInstallStep().dependOn(compile_step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(compile_step);

    const run_step = b.step(name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);
}
