const std = @import("std");
const lexer = @import("lexer");
const parser = @import("parser");
const ast = @import("ast");
const Lexer = lexer.Lexer;
const alloc = std.testing.allocator;
const Stmt = ast.Stmt;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const tag = std.meta.activeTag;

fn lexnparse(allocator: std.mem.Allocator, source: []const u8) !*ast.Stmt {
    var l = Lexer.init(source);
    var tokens = try l.lex(allocator);
    defer tokens.deinit(allocator);
    var p = parser.Parser.init(allocator, tokens.items);
    return try p.parse();
}
test "empty program" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "");
    try expect(tag(tree.*) == .program);
}
test "var declaration without initializer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x;");
    try expect(tag(tree.*) == .program);
    const stmt = tree.program[0];
    try expect(tag(stmt.*) == .var_decl);
    try expectEqualStrings(stmt.var_decl.name, "x");
    try expect(stmt.var_decl.init == null);
}
test "int declaration with initializer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 60;");
    const stmt = tree.program[0];
    try expect(tag(stmt.*) == .var_decl);
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .literal);
    try expectEqual(init.expr.literal.value.number, 60);
}
test "string declaration with initializer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "string s = \"test\";");
    const stmt = tree.program[0];
    try expect(tag(stmt.*) == .var_decl);
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .interpolated_string);
    try expectEqual(init.expr.interpolated_string.parts.len, 1);
    try expectEqualStrings(init.expr.interpolated_string.parts[0].text, "test");
}
test "bool declaration with initializer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool booltest = true;");
    const stmt = tree.program[0];
    try expect(tag(stmt.*) == .var_decl);
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .literal);
    try expectEqual(init.expr.literal.value.boolean, true);
}
test "multiple statements" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 67; string s = \"hi\";bool booltest = true;");
    try expectEqual(tree.program.len, 3);
    const one = tree.program[0].var_decl;
    try expectEqualStrings(one.name, "x");
    const two = tree.program[1].var_decl;
    try expectEqualStrings(two.name, "s");
    const three = tree.program[2].var_decl;
    try expectEqualStrings(three.name, "booltest");
}
test "variable expression" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int result = x + y + z;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.binary, std.meta.activeTag(init.expr.*));
    const outer = init.expr.binary;
    try expectEqual(.binary, std.meta.activeTag(outer.left.*));
    try expectEqual(.variable, std.meta.activeTag(outer.left.binary.left.*));
    try expectEqualStrings(outer.left.binary.left.variable.name, "x");
    try expectEqual(.variable, std.meta.activeTag(outer.left.binary.right.*));
    try expectEqualStrings(outer.left.binary.right.variable.name, "y");
    try expectEqual(.variable, std.meta.activeTag(outer.right.*));
    try expectEqualStrings(outer.right.variable.name, "z");
}
test "parentheses" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = (42);");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .literal);
    try expectEqual(init.expr.literal.value.number, 42);
}
test "addition" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 1 + 2;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .plus);
}
test "subtraction" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 5 - 3;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .minus);
}
test "multiplication" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 6 * 7;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .star);
}
test "division" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 8 / 2;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .slash);
}
test "mod" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = 7 % 3;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .mod);
}
test "equality" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x == y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .equality);
}
test "inequality" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x != y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .inequality);
}
test "less than" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x < y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .lessthan);
}
test "less than eq" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x <= y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .lessthan_equal);
}
test "greater than" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x > y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .greaterthan);
}
test "greater than equal" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool b = x >= y;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expect(tag(init.expr.*) == .binary);
    try expectEqual(init.expr.binary.op, .greaterthan_equal);
}
test "parse operator precedence" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "bool x = -1 + 2 * 3 % 4 / 5 < 6 + 7 >= 8 == 9 != false;");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.binary, tag(init.expr.*));
    const neq = init.expr.binary;
    try expectEqual(.inequality, neq.op);
    try expectEqual(.literal, tag(neq.right.*));
    try expectEqual(false, neq.right.literal.value.boolean);
    try expectEqual(.binary, tag(neq.left.*));
    const eq = neq.left.binary;
    try expectEqual(.equality, eq.op);
    try expectEqual(.literal, tag(eq.right.*));
    try expectEqual(@as(i64, 9), eq.right.literal.value.number);
    try expectEqual(.binary, tag(eq.left.*));
    const ge = eq.left.binary;
    try expectEqual(.greaterthan_equal, ge.op);
    try expectEqual(.literal, tag(ge.right.*));
    try expectEqual(@as(i64, 8), ge.right.literal.value.number);
    try expectEqual(.binary, tag(ge.left.*));
    const lt = ge.left.binary;
    try expectEqual(.lessthan, lt.op);
    try expectEqual(.binary, tag(lt.left.*));
    try expectEqual(.plus, lt.left.binary.op);
    try expectEqual(.binary, tag(lt.right.*));
    try expectEqual(.plus, lt.right.binary.op);
    const leftadd = lt.left.binary;
    try expectEqual(.unary, tag(leftadd.left.*));
    try expectEqual(.slash, leftadd.right.binary.op);
    const div = leftadd.right.binary;
    try expectEqual(.binary, tag(div.left.*));
    try expectEqual(.mod, div.left.binary.op);
    const mod = div.left.binary;
    try expectEqual(.binary, tag(mod.left.*));
    try expectEqual(.star, mod.left.binary.op);
}
test "function call expression" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const tree = try lexnparse(arena.allocator(), "int x = test();");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.call, tag(init.expr.*));
    try expectEqualStrings(init.expr.call.callee, "test");
    try expectEqual(@as(usize, 0), init.expr.call.args.len);
}
test "function call with arguments" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = test(1, 2, 3);");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;

    try expectEqual(.call, tag(init.expr.*));
    try expectEqualStrings(init.expr.call.callee, "test");
    try expectEqual(@as(usize, 3), init.expr.call.args.len);
}
test "array declaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int [10] arr;");
    const stmt = tree.program[0];
    try expectEqual(.var_decl, tag(stmt.*));
    try expectEqualStrings(stmt.var_decl.name, "arr");
    try expectEqual(@as(usize, 10), stmt.var_decl.array_size.?);
    try expect(stmt.var_decl.init == null);
}
test "array literal initializer" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int[3] arr = {1,2,3};");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.array_literal, tag(init));
    try expectEqual(@as(usize, 3), init.array_literal.len);
}
test "array access expression" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = arr[5];");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.index, tag(init.expr.*));
    try expectEqualStrings(init.expr.index.array, "arr");
}
test "assignment statement" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "x = 10;");
    const stmt = tree.program[0];
    try expectEqual(.assignment, tag(stmt.*));
    try expectEqualStrings(stmt.assignment.name, "x");
    try expectEqual(.equal, stmt.assignment.op);
}
test "plus assignment statement" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "x += 5;");
    const stmt = tree.program[0];
    try expectEqual(.assignment, tag(stmt.*));
    try expectEqualStrings(stmt.assignment.name, "x");
    try expectEqual(.plus_equal, stmt.assignment.op);
}
test "minus assignment statement" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "x -= 5;");
    const stmt = tree.program[0];
    try expectEqual(.assignment, tag(stmt.*));
    try expectEqualStrings(stmt.assignment.name, "x");
    try expectEqual(.minus_equal, stmt.assignment.op);
}
test "if statement without else" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "if(true){int x = 1;}");
    const stmt = tree.program[0];
    try expectEqual(.if_stmt, tag(stmt.*));
    try expect(stmt.if_stmt.else_branch == null);
    try expectEqual(.block, tag(stmt.if_stmt.then_branch.*));
}
test "if statement with else" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "if(true){int x = 1;}else{int y = 2;}");
    const stmt = tree.program[0];
    try expectEqual(.if_stmt, tag(stmt.*));
    try expect(stmt.if_stmt.else_branch != null);
    try expectEqual(.block, tag(stmt.if_stmt.then_branch.*));
    try expectEqual(.block, tag(stmt.if_stmt.else_branch.?.*));
}
test "while statement" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "while(true){int x = 1;}");
    const stmt = tree.program[0];
    try expectEqual(.while_stmt, tag(stmt.*));
    try expectEqual(.literal, tag(stmt.while_stmt.condition.*));
    try expectEqual(true, stmt.while_stmt.condition.literal.value.boolean);
    try expectEqual(.block, tag(stmt.while_stmt.body.*));
}
test "function declaration with parameters" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "fn int add(int a, int b){int placehold;}");
    const stmt = tree.program[0];
    try expectEqual(.func_decl, tag(stmt.*));
    try expectEqualStrings(stmt.func_decl.name, "add");
    try expectEqual(@as(usize, 2), stmt.func_decl.params.len);
    try expectEqualStrings(stmt.func_decl.params[0].name, "a");
    try expectEqualStrings(stmt.func_decl.params[1].name, "b");
}
test "function declaration with return statement" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "fn int add(int a,int b){return a+b;}");
    const stmt = tree.program[0];
    try expectEqual(.func_decl, tag(stmt.*));
    try expectEqual(@as(usize, 1), stmt.func_decl.body.block.len);
    try expectEqual(.return_stmt, tag(stmt.func_decl.body.block[0].*));
}
test "nested if statements" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "if(true){if(false){int x = 1;}}");
    const stmt = tree.program[0];
    try expectEqual(.if_stmt, tag(stmt.*));
    try expectEqual(.if_stmt, tag(stmt.if_stmt.then_branch.block[0].*));
}
test "nested while statements" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "while(true){while(false){int x = 1;}}");
    const stmt = tree.program[0];
    try expectEqual(.while_stmt, tag(stmt.*));
    try expectEqual(.while_stmt, tag(stmt.while_stmt.body.block[0].*));
}
test "interpolated string with multiple expressions" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "string s = \"{test1} with {test2}\";");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.interpolated_string, tag(init.expr.*));
    try expectEqual(@as(usize, 3), init.expr.interpolated_string.parts.len);
}
test "nested arithmetic expression" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = (1 + 2) * (3 - 4);");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.binary, tag(init.expr.*));
    try expectEqual(.star, init.expr.binary.op);
    try expectEqual(.binary, tag(init.expr.binary.left.*));
    try expectEqual(.binary, tag(init.expr.binary.right.*));
}
test "nested function calls" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int x = test1(test2(1), test4(2));");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.call, tag(init.expr.*));
    try expectEqualStrings(init.expr.call.callee, "test1");
    try expectEqual(@as(usize, 2), init.expr.call.args.len);
    try expectEqual(.call, tag(init.expr.call.args[0].*));
    try expectEqual(.call, tag(init.expr.call.args[1].*));
}
test "assignment to array element" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "arr[1] = 42;");
    const stmt = tree.program[0];
    try expectEqual(.assignment, tag(stmt.*));
    try expectEqualStrings(stmt.assignment.name, "arr");
    try expect(stmt.assignment.index != null);
    try expectEqual(.equal, stmt.assignment.op);
}
test "array literal with expressions" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const tree = try lexnparse(arena.allocator(), "int [3] arr = {1+2,3*4,test()};");
    const stmt = tree.program[0];
    const init = stmt.var_decl.init.?;
    try expectEqual(.array_literal, tag(init));
    try expectEqual(@as(usize, 3), init.array_literal.len);
    try expectEqual(.binary, tag(init.array_literal[0].*));
    try expectEqual(.binary, tag(init.array_literal[1].*));
    try expectEqual(.call, tag(init.array_literal[2].*));
}
//negative tests (only these ones are in the scope for parser error handling i.e. simple syntax errors, others like type checking for example will be in checker tests)
test "missing semicolon in variable declaration" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int x = 5"));
}
test "missing closing paren" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int x = (1 + 2;"));
}
test "missing closing brace" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "if(true){int x = 1;"));
}
test "assignment missing value" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedExpression, lexnparse(arena.allocator(), "x = ;"));
}
test "missing parameter identifier" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedIdentifier, lexnparse(arena.allocator(), "fn int test(int){return 0;}"));
}
test "missing condition" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedExpression, lexnparse(arena.allocator(), "if(){int x = 1;}"));
}
test "missing assign in array" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedExpression, lexnparse(arena.allocator(), "int[2] a = {1,};"));
}
test "missing closing brace in array" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int[3] a = {1,2,3;"));
}
test "missing array size" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int[] array;"));
}
test "missing closing bracket in array" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int[10 a;"));
}
test "missing comma in function parameters" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "fn int test(int a int b){return 0;}"));
}
test "missing comma in function call arguments" {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    try std.testing.expectError(error.ExpectedToken, lexnparse(arena.allocator(), "int x = test(1 2);"));
}
