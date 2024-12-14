//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const WriteState = enum { base, do_not, mul, first_digit, second_digit };

pub fn parse_file_multiplications(file_path: []const u8, parse_do: bool) !i32 {
    var total: i32 = 0;

    const input = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, file_path, std.math.maxInt(usize));

    var index: usize = 0;
    var state: WriteState = WriteState.base;
    // std.debug.print("Input: {s}\n", .{input});

    var digit_one = std.ArrayList(u8).init(std.heap.page_allocator);
    var digit_two = std.ArrayList(u8).init(std.heap.page_allocator);
    defer digit_one.deinit();
    defer digit_two.deinit();

    while (index < input.len) {
        switch (state) {
            WriteState.base => {
                if (index + 4 >= input.len) {
                    break;
                }
                const slice = input[index .. index + 4];
                if (parse_do and index + 7 < input.len) {
                    const slice_do = input[index .. index + 7];
                    if (std.mem.eql(u8, slice_do, "don't()")) {
                        index += 7;
                        state = WriteState.do_not;
                        continue;
                    }
                }
                // std.debug.print("{s}\n", .{slice});
                if (std.mem.eql(u8, slice, "mul(")) {
                    index += 4;
                    state = WriteState.first_digit;
                } else {
                    index += 1;
                }
            },
            WriteState.first_digit => {
                const char = input[index];
                if (std.ascii.isDigit(char)) {
                    try digit_one.append(char);
                    index += 1;
                } else if (std.mem.eql(u8, &[1]u8{char}, ",")) {
                    state = WriteState.second_digit;
                    index += 1;
                } else {
                    digit_one.shrinkAndFree(0);
                    state = WriteState.base;
                }
            },
            WriteState.second_digit => {
                const char = input[index];
                if (std.ascii.isDigit(char)) {
                    try digit_two.append(char);
                    index += 1;
                } else if (std.mem.eql(u8, &[1]u8{char}, ")")) {
                    state = WriteState.base;
                    index += 1;

                    total += try std.fmt.parseInt(i32, digit_one.items, 10) * try std.fmt.parseInt(i32, digit_two.items, 10);
                    digit_one.shrinkAndFree(0);
                    digit_two.shrinkAndFree(0);
                } else {
                    digit_one.shrinkAndFree(0);
                    digit_two.shrinkAndFree(0);
                    state = WriteState.base;
                }
            },
            WriteState.do_not => {
                if (index + 4 >= input.len) {
                    break;
                }
                const slice = input[index .. index + 4];
                if (std.mem.eql(u8, slice, "do()")) {
                    index += 4;
                    state = WriteState.base;
                } else {
                    index += 1;
                }
            },
            else => {
                std.debug.print("Not supposed to get here\n", .{});
                state = WriteState.base;
                index += 1;
            },
        }
    }

    return total;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const total = try parse_file_multiplications("input.txt", false);
    const total_extra = try parse_file_multiplications("input.txt", true);

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Total: {any}\nTotal two: {any}", .{ total, total_extra });

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
