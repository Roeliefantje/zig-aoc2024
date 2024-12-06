//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

fn get_distance(arr1: []i32, arr2: []i32) !u32 {
    if (arr1.len != arr2.len) {
        return error.DifferentLengths;
    }

    var distance: u32 = 0;

    for (0..arr1.len) |i| {
        distance += @abs(arr1[i] - arr2[i]);
    }

    return distance;
}

fn get_similarity_score(arr1: []i32, arr2: []i32) !u32 {
    if (arr1.len != arr2.len) {
        return error.DifferentLengths;
    }

    var total_similarity: u32 = 0;

    for (0..arr1.len) |i| {
        const val1: u32 = @intCast(arr1[i]);
        var occurences: u32 = 0;
        for (0..arr2.len) |j| {
            const val2: u32 = @intCast(arr2[j]);
            if (val1 == val2) {
                occurences += 1;
            } else if (val2 > val1) {
                break;
            }
        }
        total_similarity += occurences * val1;
    }

    return total_similarity;
}

fn get_sorted_arrays_from_file(file_path: []const u8) ![2][]i32 {
    var arr1 = std.ArrayList(i32).init(std.heap.page_allocator);
    var arr2 = std.ArrayList(i32).init(std.heap.page_allocator);
    var arrays = [2]std.ArrayList(i32){ arr1, arr2 };

    defer arr1.deinit();
    defer arr2.deinit();

    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const buf_reader = &reader.reader();

    while (try buf_reader.readUntilDelimiterOrEofAlloc(std.heap.page_allocator, '\n', std.math.maxInt(usize))) |line| {
        defer std.heap.page_allocator.free(line);

        var values = std.mem.splitSequence(u8, line, "   ");
        var index: usize = 0;
        while (values.next()) |item| : (index += 1) {
            const parsed_value = try std.fmt.parseInt(i32, item, 10);
            try arrays[index].append(parsed_value);
        }
    }

    std.mem.sort(i32, arrays[0].items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, arrays[1].items, {}, comptime std.sort.asc(i32));

    return .{ arrays[0].items, arrays[1].items };
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const arrays = try get_sorted_arrays_from_file("input.txt");
    const arr1 = arrays[0];
    const arr2 = arrays[1];

    const result = try get_distance(arr1, arr2);
    const result2 = try get_similarity_score(arr1, arr2);

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{any}\n{any}", .{ result, result2 });

    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const global = struct {
        fn testOne(input: []const u8) anyerror!void {
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(global.testOne, .{});
}
