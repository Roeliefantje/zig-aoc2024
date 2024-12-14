//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
pub fn see_valid_word(
    word_search: [][]u8,
    string_left: []const u8,
    direction_x: i32,
    direction_y: i32,
    curr_x: i32,
    curr_y: i32,
) !bool {
    // std.debug.print("string left: {any}\n", .{string_left});
    if (string_left.len == 0) {
        return true;
    }

    const new_pos_y = curr_y + direction_y;
    const new_pos_x = curr_x + direction_x;

    if (new_pos_y < 0 or new_pos_y >= word_search.len or new_pos_x < 0 or new_pos_x >= word_search[0].len) {
        return false;
    }

    const next_char = string_left[0];

    const new_pos_char = word_search[@intCast(new_pos_y)][@intCast(new_pos_x)];

    if (next_char == new_pos_char) {
        return try see_valid_word(word_search, string_left[1..], direction_x, direction_y, new_pos_x, new_pos_y);
    } else {
        return false;
    }
}

pub fn get_mas_crosses(word_search: [][]u8) !i32 {
    var total_occurences: i32 = 0;

    for (word_search, 0..) |line, y| {
        const y_i32: i32 = @intCast(y);
        // if (y == 0 or y == word_search.len - 1) {
        //     continue;
        // }

        for (line, 0..) |char, x| {
            // if (x == 0 or x == line.len - 1) {
            //     continue;
            // }

            if (char == 'A') {
                const x_i32: i32 = @intCast(x);
                const string_left_array = [3]u8{ 'M', 'A', 'S' };

                //-2 because the curr_x does not get checked
                const bot_left_top_right = try see_valid_word(word_search, &string_left_array, 1, 1, x_i32 - 2, y_i32 - 2);
                const top_right_bot_left = try see_valid_word(word_search, &string_left_array, -1, -1, x_i32 + 2, y_i32 + 2);

                const top_left_bot_right = try see_valid_word(word_search, &string_left_array, 1, -1, x_i32 - 2, y_i32 + 2);
                const bot_right_top_left = try see_valid_word(word_search, &string_left_array, -1, 1, x_i32 + 2, y_i32 - 2);

                if ((bot_left_top_right or top_right_bot_left) and (top_left_bot_right or bot_right_top_left)) {
                    total_occurences += 1;
                }
            }
        }
    }

    return total_occurences;
}

pub fn get_xmas_occurences(word_search: [][]u8) !i32 {
    var total_occurences: i32 = 0;

    for (word_search, 0..) |line, y| {
        const y_i32: i32 = @intCast(y);
        for (line, 0..) |char, x| {
            if (char == 'X') {
                const x_i32: i32 = @intCast(x);
                const string_left_array = [3]u8{ 'M', 'A', 'S' };
                //Todo: use an array for the different combinations instead of this shit lol.
                if (try see_valid_word(word_search, &string_left_array, -1, 0, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, -1, -1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, -1, 1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, 1, 0, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, 1, -1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, 1, 1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, 0, -1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
                if (try see_valid_word(word_search, &string_left_array, 0, 1, x_i32, y_i32)) {
                    total_occurences += 1;
                }
            }
        }
    }

    return total_occurences;
}

pub fn read_file_into_2d_array(file_path: []const u8) ![][]u8 {
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    defer lines.deinit();

    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const buf_reader = &reader.reader();

    while (try buf_reader.readUntilDelimiterOrEofAlloc(std.heap.page_allocator, '\n', std.math.maxInt(usize))) |line| {
        // defer std.heap.page_allocator.free(line);
        try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)

    const lines = try read_file_into_2d_array("input.txt");
    defer {
        for (lines) |line| {
            std.heap.page_allocator.free(line);
        }
        std.heap.page_allocator.free(lines);
    }
    const occurences = try get_xmas_occurences(lines);
    const crosses = try get_mas_crosses(lines);

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Total occurences: {any}\n Crosses {any}", .{ occurences, crosses });

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
