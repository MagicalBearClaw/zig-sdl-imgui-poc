const std = @import("std");

pub const IMGUI_C_DEFINES: []const [2][]const u8 = &.{
    .{ "IMGUI_DISABLE_OBSOLETE_FUNCTIONS", "1" },
    .{ "IMGUI_DISABLE_OBSOLETE_KEYIO", "1" },
    .{ "IMGUI_IMPL_API", "extern \"C\"" },
    .{ "IMGUI_USE_WCHAR32", "1" },
    .{ "ImTextureID", "ImU64" },
    .{ "CIMGUI_USE_SDL2", "1" },
    .{ "IMGUI_DEFINE_MATH_OPERATORS", "1" },
    //.{ "IMGUI_DEFINE_MATH_OPERATORS", "" },
};

pub const IMGUI_C_FLAGS: []const []const u8 = &.{
    "-std=c++11",
    "-fvisibility=hidden",
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const sdl2_dep = b.dependency("sdl2", .{});

    const imgui_dep = b.dependency("imgui", .{});

    const imguizmo_dep = b.dependency("imguizmo", .{});

    const imgui_lib = b.addStaticLibrary(.{
        .name = "imgui",
        .target = target,
        .optimize = optimize,
    });

    imgui_lib.root_module.link_libcpp = true;

    for (IMGUI_C_DEFINES) |c_define| {
        imgui_lib.root_module.addCMacro(c_define[0], c_define[1]);
    }

    const imgui_sources: []const std.Build.LazyPath = &.{
        b.path("external/cimgui/cimguizmo.cpp"),
        b.path("external/cimgui/cimgui.cpp"),
        imgui_dep.path("imgui.cpp"),
        imgui_dep.path("imgui_demo.cpp"),
        imgui_dep.path("imgui_draw.cpp"),
        imgui_dep.path("imgui_tables.cpp"),
        imgui_dep.path("imgui_widgets.cpp"),
        imgui_dep.path("backends/imgui_impl_sdl2.cpp"),
        imgui_dep.path("backends/imgui_impl_sdlrenderer2.cpp"),
        imguizmo_dep.path("ImGuizmo.cpp"),
        //        b.path("external/cimgui/ImGuizmo.cpp"),
    };

    imgui_lib.addIncludePath(sdl2_dep.path("include"));
    imgui_lib.addIncludePath(imguizmo_dep.path("."));
    imgui_lib.addIncludePath(b.path("external/cimgui/"));
    imgui_lib.addIncludePath(imgui_dep.path("."));
    for (imgui_sources) |file| {
        imgui_lib.addCSourceFile(.{
            .file = file,
            .flags = IMGUI_C_FLAGS,
        });
    }

    b.installArtifact(imgui_lib);

    const exe = b.addExecutable(.{
        .name = "zig-sdl-test",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(b.path("external/cimgui/"));
    exe.addIncludePath(sdl2_dep.path("include"));
    exe.addLibraryPath(sdl2_dep.path("lib/x64"));

    const p = sdl2_dep.path("lib/x64/SDL2.dll");

    const sdl_install_step = b.addInstallBinFile(p, "SDL2.dll");

    b.getInstallStep().dependOn(&sdl_install_step.step);

    exe.linkSystemLibrary("SDL2");
    exe.linkLibrary(imgui_lib);
    //    exe.linkLibrary(imgizmo_lib);
    exe.linkLibC();

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
