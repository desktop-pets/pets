const std = @import("std");
const known_folders = @import("known-folders");

pub const AppConfig = struct {
    title: [:0]const u8,
    data_dir: [:0]const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, environ: *const std.process.Environ.Map, name: [:0]const u8) !AppConfig {
        const root_dir = (try known_folders.getPath(io, allocator, environ, known_folders.KnownFolder.data)) orelse return error.DataDirNotFound;
        defer allocator.free(root_dir);

        const data_dir = try std.fs.path.joinZ(allocator, &.{ root_dir, name });
        const cwd = std.Io.Dir.cwd();
        try cwd.createDirPath(io, data_dir);

        return .{ .title = name, .data_dir = data_dir, .allocator = allocator };
    }

    pub fn deinit(self: AppConfig) void {
        self.allocator.free(self.data_dir);
    }
};
