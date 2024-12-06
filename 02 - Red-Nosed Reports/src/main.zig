//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

fn check_valid_report(line: []u8, skip_index: ?usize) !bool {
    var values = std.mem.splitSequence(u8, line, " ");
    var index: usize = 0;

    var opt_prev_value: ?i32 = null;
    var opt_is_increasing: ?bool = null;
    var valid_line = true;

    while (values.next()) |item| : (index += 1) {
        if (skip_index) |skip| {
            if (skip == index) {
                continue;
            }
        }

        const parsed_value = try std.fmt.parseInt(i32, item, 10);
        // std.debug.print("Parsed Value: {any}\n", .{parsed_value});
        if (opt_prev_value) |prev_value| {
            const diff = parsed_value - prev_value;
            if (@abs(diff) > 3 or diff == 0) {
                valid_line = false;
                break;
            }

            if (opt_is_increasing) |is_increasing| {
                if ((is_increasing and diff < 0) or
                    (!is_increasing and diff > 0))
                {
                    valid_line = false;
                    break;
                }
            } else {
                opt_is_increasing = diff > 0;
            }
        }
        opt_prev_value = parsed_value;
    }

    return valid_line;
}

fn get_valid_reports(file_path: []const u8, with_damperer: bool) !u32 {
    var valid_lines: u32 = 0;

    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const buf_reader = &reader.reader();

    while (try buf_reader.readUntilDelimiterOrEofAlloc(std.heap.page_allocator, '\n', std.math.maxInt(usize))) |line| {
        defer std.heap.page_allocator.free(line);
        var is_valid = try check_valid_report(line, null);

        if (with_damperer) {
            // bit unneccesary but idk how to get the len otherwise;
            var values = std.mem.splitSequence(u8, line, " ");
            const len = values.rest().len;
            var index_to_skip: usize = 0;

            while (!is_valid and index_to_skip < len) : (index_to_skip += 1) {
                is_valid = try check_valid_report(line, index_to_skip);
            }
        }

        if (is_valid) {
            valid_lines += 1;
        }
    }

    return valid_lines;
}

pub fn main() !void {
    const valid_lines = try get_valid_reports("input.txt", false);
    const valid_damp_lines = try get_valid_reports("input.txt", true);

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{any}\n{any}", .{ valid_lines, valid_damp_lines });

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
