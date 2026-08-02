const std = @import("std");
const lexer = @import("lexer");
const parser = @import("parser");
const checker = @import("checker");
const ast = @import("ast");
const Lexer = lexer.Lexer;
const Checker = checker.Checker;
const alloc = std.testing.allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

fn lexparsecheck(allocator: std.mem.Allocator, source: []const u8) !checker.Checker {
    var l = Lexer.init(source);
    var tokens = try l.lex(allocator);
    defer tokens.deinit(allocator);
    var p = parser.Parser.init(allocator, tokens.items);
    const tree = try p.parse();
    var c = Checker.init(allocator);
    try c.check(tree);
    return c;
}
