const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const path: []const u8 = "src/hi.txt"; // handle this later

    const source = try fetcher.readSource(io, init.gpa, path);
    defer init.gpa.free(source);

    var lexer = lexerMod.Lexer.init(source);

    var tokens = try lexerMod.Lexer.lex(&lexer, init.gpa);
    defer tokens.deinit(init.gpa);
}
 