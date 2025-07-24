//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");

// Enzyme will supply this function when we run it's pass during the build
// we're basically using the C api from zig
extern fn __enzyme_autodiff(func: *const anyopaque, x: f32) f32;
extern fn __enzyme_autodiff_float2(func: *const anyopaque, s: c_int, x: f32, s2: c_int, y: f32) float2;
extern var enzyme_dup: c_int;
extern var enzyme_out: c_int;
extern var enzyme_const: c_int;

const float2 = extern struct { x: f32 = 0, y: f32 = 0 };

// enzyme uses the C calling convention, so we need to annotate the function we want to differentiate
pub fn cos(x: f32) callconv(.C) f32 {
    return std.math.cos(x);
}

pub fn rosen(x: f32, y: f32) callconv(.C) f32 {
    const a: f32 = 1.0;
    const b: f32 = 100.0;
    return ((a - x) * (a - x)) + b * ((y - x * x) * (y - x * x));
}

pub fn zig_pow2(x: f32) callconv(.C) f32 {
    return std.math.pow(f32, x, 2.0);
}

pub fn simple_pow2(x: f32) callconv(.C) f32 {
    return x * x;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    var x: f32 = 3.14 / 2.0;
    var y: f32 = 1.0;
    if (args.len > 1) {
        if (args[1].len > 0) {
            x = std.fmt.parseFloat(f32, args[1]) catch 1.57;
        }
    }
    if (args.len > 2) {
        if (args[2].len > 0) {
            y = std.fmt.parseFloat(f32, args[2]) catch 1.0;
        }
    }
    const grad_cos_x = __enzyme_autodiff(&cos, x);
    std.debug.print("grad of cos({}) = {}\n", .{ x, grad_cos_x });

    const grad_rosen = __enzyme_autodiff_float2(&rosen, enzyme_out, x, enzyme_out, y);
    std.debug.print("grad of rosen({},{}) = {},{}\n", .{ x, y, grad_rosen.x, grad_rosen.y });

    const grad_simple_pow2 = __enzyme_autodiff(&simple_pow2, x);
    std.debug.print("grad of simple pow2({}) = {}\n", .{ x, grad_simple_pow2 });

    // using the Zig std lib pow function seems to break enzyme, so we'll need to define a custom derivative
    // const grad_zig_pow2 = __enzyme_autodiff(@as(*anyopaque, @ptrCast(@constCast(&zig_pow2))), x);
    // std.debug.print("grad of zig pow2({}) = {}\n", .{ x, grad_zig_pow2 });
}

test "cosine diff" {}

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
