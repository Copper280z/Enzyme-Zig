const std = @import("std");

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

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "enzyme",
        .root_module = exe_mod,
    });

    const ir_file = b.addInstallFile(exe.getEmittedLlvmIr(), "input.ll");

    // Enzyme was installed via homebrew and brought llvm-19 with it, so we'll run the AD pass using opt from it's dependency
    const enzyme_pass = b.addSystemCommand(&[_][]const u8{"/opt/homebrew/Cellar/llvm@19/19.1.7/bin/opt"});

    // llvm 20 segfaults
    // const enzyme_pass = b.addSystemCommand(&[_][]const u8{"/opt/homebrew/Cellar/llvm/20.1.7/bin/opt"});

    enzyme_pass.addFileArg(b.path("zig-out/input.ll"));
    enzyme_pass.addArg("--load-pass-plugin=/opt/homebrew/Cellar/enzyme/0.0.186/lib/LLVMEnzyme-19.dylib");
    enzyme_pass.addArg("-passes=enzyme");
    enzyme_pass.addArg("-o");
    const generated_file = enzyme_pass.addOutputFileArg("output.ll");
    enzyme_pass.addArg("-S");

    enzyme_pass.step.dependOn(&ir_file.step);

    const install_enzyme_out = b.addInstallFile(generated_file, "output.ll");
    install_enzyme_out.step.dependOn(&enzyme_pass.step);

    const real_exe = b.addExecutable(.{
        .name = "output",
        .root_module = null,
        .target = target,
        .optimize = optimize,
    });
    real_exe.addCSourceFile(.{ .file = generated_file });
    real_exe.step.dependOn(&install_enzyme_out.step);

    // // This declares intent for the executable to be installed into the
    // // standard location when the user invokes the "install" step (the default
    // // step when running `zig build`).
    b.installArtifact(real_exe);
}
