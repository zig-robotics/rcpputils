const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("rcpputils", .{});
    var lib = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        },
        .name = "rcpputils",
        .kind = .lib,
        .linkage = linkage,
    });

    lib.linkLibCpp();
    lib.addIncludePath(upstream.path("include"));

    const rcutils_dep = b.dependency("rcutils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    lib.linkLibrary(rcutils_dep.artifact("rcutils"));

    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "src/asserts.cpp",
            "src/filesystem_helper.cpp",
            "src/find_library.cpp",
            "src/env.cpp",
            "src/shared_library.cpp",
        },
        .flags = &.{
            "--std=c++17",
            "-fvisibility=hidden",
            "-fvisibility-inlines-hidden",
        },
    });

    lib.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{ .include_extensions = &.{".hpp"} },
    );
    b.installArtifact(lib);
}
