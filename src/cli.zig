const std = @import("std");
const print = std.debug.print;
const Arguments = struct {
    path: []const u8 = "",
    token_print: bool = false,
    ast_print: bool = false,
    output_file: bool = false,
    ask_help: bool = false,
    ask_version: bool = false,
    c_file: bool = false,
    print_checks: bool = false,
};
pub fn parseArgs(init: std.process.Init) !Arguments {
    const banner =
        \\_________ ___
        \\\$$$$$$$$\\$$\                                                
        \\ \____$$  |\__|                                                
        \\     $$  / $$\ $$$$$$\  $$\   $$\ $$$$$$\  $$$$$$$\   $$$$$$\  
        \\    $$  /  $$ |$$  __$$\ $$ |  $$ | \____$$\ $$  __$$\ \____$$\ 
        \\   $$  /   $$ |$$ /  $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ | $$$$$$$ |
        \\  $$  /    $$ |$$ |  $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$  __$$ |
        \\ $$$$$$$$\ $$ |\$$$$$$$ |\$$$$$$  |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |
        \\ \________|\__| \____$$ | \______/  \_______|\__|  \__| \_______|
        \\               $$\   $$ |                                      
        \\               \$$$$$$  |                                      
        \\                \______/                                       
        \\
        \\ Ziguana
        \\ 1) --version  : Shows ziguana Version
        \\ 2) --help     : Shows the available flags
        \\ 1) --tokens   : Prints lexed tokens from the source file
        \\ 2) --astprint : Print abstract syntax tree parsed from source file 
        \\ 3) --check    : Prints Syntax errors from the source file
    ;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var arguments = Arguments{};
    if (args.len < 2) {
        return error.pathNotProvided;
    }
    var pathSet = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            print("{s}\n", .{banner});
            arguments.ask_help = true;
        } else if (std.mem.eql(u8, arg, "--astprint")) {
            arguments.ast_print = true;
        } else if (std.mem.eql(u8, arg, "--tokens")) {
            arguments.token_print = true;
        } else if (std.mem.eql(u8, arg, "--version")) {
            print("Version : 0.0.0\n", .{});
            arguments.ask_version = true;
        } else if (!pathSet) {
            arguments.path = arg;
            pathSet = true;
        } else if (std.mem.eql(u8, arg, "--check")) { //cn be changed later
            arguments.print_checks = true;
        }
    }
    if (!pathSet and !arguments.ask_help and !arguments.ask_version) {
        return error.pathNotProvided;
    }
    return arguments;
}
