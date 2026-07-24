const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");
const parser = @import("parser.zig");
const cli = @import("cli.zig");
const astprinter = @import("astprinter.zig");
fn printToken(tok: lexerMod.Token) void {
    switch (tok.payload) {
        .identifier => |s| std.debug.print("{d}:{d} identifier(\"{s}\")\n", .{ tok.line, tok.column, s }),
        .string => |s| std.debug.print("{d}:{d} string(\"{s}\")\n", .{ tok.line, tok.column, s }),
        .number => |n| std.debug.print("{d}:{d} number({d})\n", .{ tok.line, tok.column, n }),
        .type_ => |t| std.debug.print("{d}:{d} type({s})\n", .{ tok.line, tok.column, @tagName(t) }),
        else => std.debug.print("{d}:{d} {s}\n", .{ tok.line, tok.column, @tagName(std.meta.activeTag(tok.payload)) }),
    }
}
pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const args = try cli.parseArgs(init);
    if (args.ask_help or args.ask_version) {
        return;
    }
    const source = try fetcher.readSource(io, arena, args.path);
    var lexer = lexerMod.Lexer.init(source);
    const tokens = try lexer.lex(arena);

    if (args.token_print) {
        for (tokens.items) |tok| {
            printToken(tok);
        }
    }
    var p = parser.Parser.init(arena, tokens.items);
    const program = p.parse() catch |err| {
        if (p.errors.items.len > 0) {
            for (p.errors.items) |e| std.debug.print("error: {s}\n", .{e.message});
        } else {
            std.debug.print("error: parsing failed ({s})\n", .{@errorName(err)});
        }
        std.process.exit(1);
    };

    if (args.ast_print) {
        var printer = astprinter.Printer.init();
        try printer.printAst(program);
    }

    var checker = @import("checker.zig").Checker.init(arena);
    try checker.check(program);
    if (args.print_checks) {
        if (checker.errors.items.len > 0) {
            for (checker.errors.items) |err| {
                std.debug.print("error: {s}\n", .{err.message});
            }
            //return error.TypeCheckFailed;
            std.process.exit(1);
            //return error.TypeCheckFailed;
        } else {
            std.debug.print("No Errors \n", .{});
        }
    }
}
