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
test "right variable declaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x = 5;");
    try expectEqual(@as(usize, 0), c.errors.items.len);
}
test "variable type mismatch initialization" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "bool x = 5;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "array initializer type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int[2] a = {1, true};");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "void variable declaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "void x;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "variable redeclaration in same scope" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x; int x;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "variable in diff scopes" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x;if(x<60){ int x; }");
    try expectEqual(@as(usize, 0), c.errors.items.len);
}
test "assignment to undeclared variable" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "x=5;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "assignment type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x; x = true;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "assignment to array with non integer index" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int[2] a; a[true]= 1;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "assignment to non array using index" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x; x[0] =1;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "assignment with negative array index" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int[2] a; a[-1] = 1;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "undeclared identifier in expression" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x =y;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "unary minus on non integer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "bool x = -true;");
    try expect(c.errors.items.len >= 1);
}
test "array access on non array" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x; int y = x[0];");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "array access with non integer index" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int[2] a; int x =a[false];");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "array access with negative index" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int[2] a; int x =a[-1];");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "arithmetic operator type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x = true + 1;");
    try expect(c.errors.items.len >= 1);
}
test "comparison operator type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "bool x = true < false;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "equality operator type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "bool x = 1 == true;");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "valid function declaration and call" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn int add(int a,int b){return a+b;} int x=add(1,2);");
    try expectEqual(@as(usize, 0), c.errors.items.len);
}
test "function redeclaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn void f(){} fn void f(){}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "call to undeclared function" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "foo();");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "function argument count mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn void f(int a){} f();");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "function argument type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn void f(int a){} f(true);");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "void parameter declaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn void f(void x){}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "if condition not boolean" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "if(5){}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "while condition is not boolean" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "while(5){}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "void function returning value" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn void f(){return 5;}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "non void function missing return value" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn int f(){return;}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "return type mismatch" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn int f(){return true;}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "non void function w/o guaranteed return" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "fn int f(){if(true){return 1;}}");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "valid interpolated string" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "int x=5; string s=\"{x}\";");
    try expectEqual(@as(usize, 1), c.errors.items.len);
}
test "interpolated string with undeclared identifier" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const c = try lexparsecheck(arena.allocator(), "string s=\"{x}\";");
    try expectEqual(@as(usize, 2), c.errors.items.len);
}
