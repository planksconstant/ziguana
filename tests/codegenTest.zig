const std = @import("std");
const testing = std.testing;

const ziguana = @import("ziguana");
const ast = ziguana.ast;
const codegen = ziguana.codegen;
const lexer = ziguana.lexer;

test "CodeGen: Integer Literal" {
    // --- Setup ---
    const allocator = testing.allocator;
    var lit_expr = ast.Expr{
        .literal = .{
            .value = .{ .number = 42 },
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&lit_expr);

    // --- Verification ---
    const expected_c_code = "42";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Boolean Literal" {
    // --- Setup ---
    const allocator = testing.allocator;
    var lit_expr = ast.Expr{
        .literal = .{
            .value = .{ .boolean = true },
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&lit_expr);

    // --- Verification ---
    const expected_c_code = "true";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: String Literal" {
    // --- Setup ---
    const allocator = testing.allocator;
    var lit_expr = ast.Expr{
        .literal = .{
            .value = .{ .string = "Hello World!" },
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&lit_expr);

    // --- Verification ---
    const expected_c_code = "\"Hello World!\"";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Unary Expression" {
    // --- Setup ---
    const allocator = testing.allocator;
    var operand = ast.Expr{
        .variable = .{
            .name = "x",
            .line = 1,
            .column = 1,
        },
    };
    var un_expr = ast.Expr{
        .unary = .{
            .op = .minus,
            .operand = &operand,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&un_expr);

    // --- Verification ---
    const expected_c_code = "-x";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Binary addition" {
    // --- Setup ---
    const allocator = testing.allocator;
    var left = ast.Expr{
        .literal = .{
            .value = .{ .number = 10 },
            .line = 1,
            .column = 1,
        },
    };
    var right = ast.Expr{
        .literal = .{
            .value = .{ .number = 20 },
            .line = 1,
            .column = 1,
        },
    };
    var bin_expr = ast.Expr{
        .binary = .{
            .op = .plus,
            .left = &left,
            .right = &right,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&bin_expr);

    // --- Verification ---
    const expected_c_code = "(10 + 20)";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Binary comparison" {
    // --- Setup ---
    const allocator = testing.allocator;
    var left = ast.Expr{
        .literal = .{
            .value = .{ .number = 10 },
            .line = 1,
            .column = 1,
        },
    };
    var right = ast.Expr{
        .literal = .{
            .value = .{ .number = 20 },
            .line = 1,
            .column = 1,
        },
    };
    var bin_expr = ast.Expr{
        .binary = .{
            .op = .lessthan,
            .left = &left,
            .right = &right,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&bin_expr);

    // --- Verification ---
    const expected_c_code = "(10 < 20)";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Variable reference" {
    // --- Setup ---
    const allocator = testing.allocator;
    var var_expr = ast.Expr{
        .variable = .{
            .name = "score",
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&var_expr);

    // --- Verification ---
    const expected_c_code = "score";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Index Expression" {
    // --- Setup ---
    const allocator = testing.allocator;
    var subscript = ast.Expr{
        .literal = .{
            .value = .{ .number = 2 },
            .line = 1,
            .column = 1,
        },
    };
    var idx_expr = ast.Expr{
        .index = .{
            .array = "arr",
            .subscript = &subscript,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&idx_expr);

    // --- Verification ---
    const expected_c_code = "arr[2]";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Function Call Expression" {
    // --- Setup ---
    const allocator = testing.allocator;
    var arg1 = ast.Expr{
        .literal = .{
            .value = .{ .number = 5 },
            .line = 1,
            .column = 1,
        },
    };
    var arg2 = ast.Expr{
        .literal = .{
            .value = .{ .number = 10 },
            .line = 1,
            .column = 1,
        },
    };
    var args = [_]*ast.Expr{ &arg1, &arg2 };
    var call_expr = ast.Expr{
        .call = .{
            .callee = "add",
            .args = &args,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&call_expr);

    // --- Verification ---
    const expected_c_code = "add(5, 10)";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Interpolated String (Plain Text)" {
    // --- Setup ---
    const allocator = testing.allocator;
    var parts = [_]ast.InterpPart{
        .{ .text = "Hello World" },
    };
    var interp_expr = ast.Expr{
        .interpolated_string = .{
            .parts = &parts,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&interp_expr);

    // --- Verification ---
    const expected_c_code = "\"Hello World\"";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Interpolated String (With Expression)" {
    // --- Setup ---
    const allocator = testing.allocator;
    var val_expr = ast.Expr{
        .literal = .{
            .value = .{ .number = 100 },
            .line = 1,
            .column = 1,
        },
    };
    var parts = [_]ast.InterpPart{
        .{ .text = "Count: " },
        .{ .expr = &val_expr },
    };
    var interp_expr = ast.Expr{
        .interpolated_string = .{
            .parts = &parts,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genExpr(&interp_expr);

    // --- Verification ---
    const expected_c_code = "printf(\"Count: %\" PRId64 \"\", 100)";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Expression Statement" {
    // --- Setup ---
    const allocator = testing.allocator;
    var expr = ast.Expr{
        .literal = .{
            .value = .{ .number = 123 },
            .line = 1,
            .column = 1,
        },
    };
    var stmt = ast.Stmt{
        .expr_stmt = &expr,
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt);

    // --- Verification ---
    const expected_c_code = "123;\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Return Statement with value" {
    // --- Setup ---
    const allocator = testing.allocator;
    var ret_val = ast.Expr{
        .literal = .{
            .value = .{ .number = 0 },
            .line = 1,
            .column = 1,
        },
    };
    var stmt = ast.Stmt{
        .return_stmt = .{
            .value = &ret_val,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt);

    // --- Verification ---
    const expected_c_code = "return 0;\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Return Statement void" {
    // --- Setup ---
    const allocator = testing.allocator;
    var stmt = ast.Stmt{
        .return_stmt = .{
            .value = null,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt);

    // --- Verification ---
    const expected_c_code = "return;\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Assignment Statement" {
    // --- Setup ---
    const allocator = testing.allocator;
    var val = ast.Expr{
        .literal = .{
            .value = .{ .number = 5 },
            .line = 1,
            .column = 1,
        },
    };
    var stmt = ast.Stmt{
        .assignment = .{
            .name = "x",
            .index = null,
            .op = .equal,
            .value = &val,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt);

    // --- Verification ---
    const expected_c_code = "x = 5;\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Variable declaration" {
    // --- Setup ---
    const allocator = testing.allocator;
    var ini_expr = ast.Expr{
        .literal = .{
            .value = .{ .number = 10 },
            .line = 1,
            .column = 1,
        },
    };
    var stmt_expr = ast.Stmt{
        .var_decl = .{
            .ty = .Int,
            .name = "count",
            .array_size = null,
            .init = .{ .expr = &ini_expr },
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt_expr);

    // --- Verification ---
    const expected_c_code = "int64_t count = 10;\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Array Variable Declaration with Array Literal" {
    // --- Setup ---
    const allocator = testing.allocator;
    var e1 = ast.Expr{
        .literal = .{
            .value = .{ .number = 1 },
            .line = 1,
            .column = 1,
        },
    };
    var e2 = ast.Expr{
        .literal = .{
            .value = .{ .number = 2 },
            .line = 1,
            .column = 1,
        },
    };
    var elements = [_]*ast.Expr{ &e1, &e2 };
    var stmt = ast.Stmt{
        .var_decl = .{
            .ty = .Int,
            .name = "arr",
            .array_size = 2,
            .init = .{ .array_literal = &elements },
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&stmt);

    // --- Verification ---
    const expected_c_code = "int64_t arr[2] = {1, 2};\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Block Statement" {
    // --- Setup ---
    const allocator = testing.allocator;
    var val = ast.Expr{
        .literal = .{
            .value = .{ .number = 1 },
            .line = 1,
            .column = 1,
        },
    };
    var inner_stmt = ast.Stmt{
        .assignment = .{
            .name = "x",
            .index = null,
            .op = .equal,
            .value = &val,
            .line = 1,
            .column = 1,
        },
    };
    var stmts = [_]*ast.Stmt{&inner_stmt};
    var block_stmt = ast.Stmt{
        .block = &stmts,
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&block_stmt);

    // --- Verification ---
    const expected_c_code = "{\n    x = 1;\n}\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Function declaration (regular function)" {
    // --- Setup ---
    const allocator = testing.allocator;
    var ret_val = ast.Expr{
        .literal = .{
            .value = .{ .number = 0 },
            .line = 1,
            .column = 1,
        },
    };
    var body_stmt = ast.Stmt{
        .return_stmt = .{
            .value = &ret_val,
            .line = 1,
            .column = 1,
        },
    };
    var params = [_]ast.Param{
        .{ .ty = .Int, .name = "a", .line = 1, .column = 1 },
        .{ .ty = .Int, .name = "b", .line = 1, .column = 1 },
    };
    var func_stmt = ast.Stmt{
        .func_decl = .{
            .return_type = .Int,
            .name = "add",
            .params = &params,
            .body = &body_stmt,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&func_stmt);

    // --- Verification ---
    const expected_c_code = "int64_t add(int64_t a, int64_t b) return 0;\n\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Function declaration (main function)" {
    // --- Setup ---
    const allocator = testing.allocator;
    var ret_val = ast.Expr{
        .literal = .{
            .value = .{ .number = 0 },
            .line = 1,
            .column = 1,
        },
    };
    var body_stmt = ast.Stmt{
        .return_stmt = .{
            .value = &ret_val,
            .line = 1,
            .column = 1,
        },
    };
    var params = [_]ast.Param{};
    var func_stmt = ast.Stmt{
        .func_decl = .{
            .return_type = .Int,
            .name = "main",
            .params = &params,
            .body = &body_stmt,
            .line = 1,
            .column = 1,
        },
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&func_stmt);

    // --- Verification ---
    const expected_c_code = "int main() return 0;\n\n";
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}

test "CodeGen: Program headers" {
    // --- Setup ---
    const allocator = testing.allocator;
    var ret_val = ast.Expr{
        .literal = .{
            .value = .{ .number = 0 },
            .line = 1,
            .column = 1,
        },
    };
    var ret_stmt = ast.Stmt{
        .return_stmt = .{
            .value = &ret_val,
            .line = 1,
            .column = 1,
        },
    };
    var stmts = [_]*ast.Stmt{&ret_stmt};
    var prog_stmt = ast.Stmt{
        .program = &stmts,
    };

    // --- Execution ---
    var cg = codegen.CodeGen.init(allocator);
    defer cg.deinit();

    try cg.genStmt(&prog_stmt);

    // --- Verification ---
    const expected_c_code =
        \\#include <stdio.h>
        \\#include <stdint.h>
        \\#include <inttypes.h>
        \\#include <stdbool.h>
        \\
        \\return 0;
        \\
    ;
    const actual_c_code = cg.output.items;
    try testing.expectEqualStrings(expected_c_code, actual_c_code);
}
