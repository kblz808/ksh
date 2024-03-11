const std = @import("std");

pub fn main() !u8 {
    const max_input = 1024;
    const max_args = 10;

    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print(">", null);

        var input_buffer: [max_input]u8 = undefined;

        var input_str = (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) orelse {
            try stdout.print("\n", .{});
            return 0;
        };

        if (input_str.len == 0) continue;

        var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

        var i: usize = 0;
        var n: usize = 0;
        var ofs: usize = 0;
        while (i <= input_str.len) : (i += 1) {
            if (input_buffer[i] == 0x20 or input_buffer[i] == 0xa) {
                input_buffer[i] = 0;
                args_ptrs[n] = @as(*align(1) const [*:0]u8, @ptrCast(&input_buffer[ofs..i :0])).*;
                n += 1;
                ofs = i + 1;
            }
        }
        args_ptrs[n] = null;

        const fork_pid = try std.os.fork();

        if (fork_pid == 0) {
            const env = [_:null]?[*:0]u8{null};

            const result = std.os.execvpeZ(args_ptrs[0].?, &args_ptrs, &env);

            try stdout.print("ERROR: {}\n", .{result});
            return 1;
        } else {
            const wait_result = std.os.waitpid(fork_pid, 0);
            if (wait_result.status != 0) {
                try stdout.print("Command returned {}.\n", .{wait_result.status});
            }
        }
    }

    return 0;
}
