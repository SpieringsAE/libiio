const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const user_config = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .cwd_relative = "iio-config.h.cmakein" } },
        .include_path = "iio-config.h",
    }, .{
        .LIBIIO_VERSION_MAJOR = "1",
        .LIBIIO_VERSION_MINOR = "1",
        .LIBIIO_VERSION_GIT = "1",
        .LOG_LEVEL = "Info",
        .DEFAULT_LOG_LEVEL = "4",
        .MAX_LOG_LEVEL_VALUE = "5",
        .HAS_STRTOK_R = true,
    });

    const iio = b.addSharedLibrary(.{
        .name = "libiio",
        .version = std.SemanticVersion{ .major = 1, .minor = 0, .patch = 0 },
        .target = target,
        .optimize = mode,
        .link_libc = true,
    });
    iio.addCSourceFiles(
        .{
            .files = &.{
                "attr.c",
                "backend.c",
                "block.c",
                "buffer.c",
                "channel.c",
                "context.c",
                "device.c",
                "events.c",
                "library.c",
                "mask.c",
                "scan.c",
                "sort.h",
                "stream.c",
                "task.c",
                "utilities.c",
            },
        },
    );

    iio.addIncludePath(.{ .cwd_relative = "./" });
    iio.addIncludePath(.{ .cwd_relative = "./include" });
    iio.addConfigHeader(user_config);

    const compat = b.option(bool, "libiio_compat", "Add compatibility layer for libiio0.x") orelse true;
    if (compat) {
        const iio_compat = b.addSharedLibrary(.{
            .name = "libiio",
            .version = .{ .major = 0, .minor = 99, .patch = 0 },
            .target = target,
            .optimize = mode,
            .link_libc = true,
        });
        iio_compat.addCSourceFile(.{ .file = .{ .cwd_relative = "compat.c" } });
        if (target.result.isMinGW()) {
            iio_compat.addCSourceFile(.{ .file = .{ .cwd_relative = "dynamic-windows.c" } });
        } else {
            iio_compat.addCSourceFile(.{ .file = .{ .cwd_relative = "dynamic-unix.c" } });
        }
    }
    b.installArtifact(iio);
    //b.addInstallHeaderFile(.{ .cwd_relative = "include/iio/iio.h" }, "./");
}
