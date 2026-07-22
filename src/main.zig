const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");
const parser = @import("parser.zig");
const cli = @import("cli.zig");
const astprinter = @import("astprinter.zig");

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
        for (tokens.items) |token| {
            std.debug.print("{}\n", .{token});
        }
    }
    var p = parser.Parser.init(arena, tokens.items);
    const program = try p.parse();
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
        } else {
            std.debug.print("No Errors \n", .{});
        }
    }
}
