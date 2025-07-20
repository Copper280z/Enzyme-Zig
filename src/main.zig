//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");

// Enzyme will supply this function when we run it's pass during the build
// we're basically using the C api from zig
extern fn __enzyme_autodiff(func: *anyopaque, x: f32) f32;

// enzyme uses the C calling convention, so we need to annotate the function we want to differentiate
pub fn cos(x: f32) callconv(.C) f32 {
    return std.math.cos(x);
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    var x: f32 = 3.14 / 2.0;
    if (args.len > 1) {
        if (args[1].len > 0) {
            x = std.fmt.parseFloat(f32, args[1]) catch 0;
        }
    }
    const grad_x = __enzyme_autodiff(@as(*anyopaque, @ptrCast(@constCast(&cos))), x);

    std.debug.print("grad of cos({}) = {}\n", .{ x, grad_x });
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

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
