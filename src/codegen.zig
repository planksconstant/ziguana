const std = @import("std");
const ast = @import("ast");
const lexer = @import("lexer");
const TokenTag = lexer.TokenTag;
const TypeKind = lexer.TypeKind;

pub const CodeGen = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indentation: usize,
    symbol_types: std.StringHashMap(lexer.TypeKind),
    pub fn init(allocator: std.mem.Allocator) CodeGen {
        return .{
            .allocator = allocator,
            .output = .empty,
            .indentation = 0,
            .symbol_types = std.StringHashMap(lexer.TypeKind).init(allocator),
        };
    }
    pub fn deinit(self: *CodeGen) void {
        self.output.deinit(self.allocator);
        self.symbol_types.deinit();
    }
    pub fn generate(self: *CodeGen, program: *ast.Stmt) ![]const u8 {
        try self.genStmt(program);
        return self.output.items;
    }
    pub fn genExpr(self: *CodeGen, expr: *ast.Expr) !void {
        switch (expr.*) {
            .literal => |lit| {
                switch (lit.value) {
                    .number => |num| try self.writeFmt("{d}", .{num}),
                    .boolean => |b| try self.write(if (b) "true" else "false"),
                    .string => |str| try self.writeFmt("\"{s}\"", .{str}),
                }
            },
            .variable => |var_| try self.write(var_.name),
            .unary => |un| {
                try self.write(mapOp(un.op));
                try self.genExpr(un.operand);
            },
            .binary => |bin| {
                try self.write("(");
                try self.genExpr(bin.left);
                try self.writeFmt(" {s} ", .{mapOp(bin.op)});
                try self.genExpr(bin.right);
                try self.write(")");
            },
            .index => |idx| {
                try self.write(idx.array);
                try self.write("[");
                try self.genExpr(idx.subscript);
                try self.write("]");
            },
            .call => |call| {
                if (std.mem.eql(u8, call.callee, "print") and call.args.len == 1) {
                    if (call.args[0].* == .interpolated_string) {
                        var has_expr = false;
                        for (call.args[0].interpolated_string.parts) |p| {
                            if (p == .expr) {
                                has_expr = true;
                                break;
                            }
                        }
                        if (has_expr) {
                            try self.genExpr(call.args[0]);
                        } else {
                            try self.write("printf(\"%s\", \"");
                            for (call.args[0].interpolated_string.parts) |p| {
                                switch (p) {
                                    .text => |text| try self.writeEscapedText(text, false),
                                    .expr => {},
                                }
                            }
                            try self.write("\")");
                        }
                    } else if (call.args[0].* == .literal) {
                        if (call.args[0].literal.value == .string) {
                            try self.write("printf(\"%s\", ");
                            try self.genExpr(call.args[0]);
                            try self.write(")");
                        }
                    }
                } else {
                    try self.writeFmt("{s}(", .{call.callee});
                    for (call.args, 0..) |arg, i| {
                        if (i > 0) {
                            try self.write(", ");
                        }
                        try self.genExpr(arg);
                    }
                    try self.write(")");
                }
            },
            .interpolated_string => |interp| {
                var has_expr = false;
                for (interp.parts) |p| {
                    if (p == .expr) {
                        has_expr = true;
                        break;
                    }
                }
                if (!has_expr) {
                    try self.write("\"");
                    for (interp.parts) |p| {
                        switch (p) {
                            .text => |text| try self.writeEscapedText(text, false),
                            .expr => {},
                        }
                    }
                    try self.write("\"");
                } else {
                    try self.write("printf(\"");
                    for (interp.parts) |p| {
                        switch (p) {
                            .text => |text| try self.writeEscapedText(text, true),
                            .expr => |ex| try self.write(getFormatSpecifier(self.inferExprType(ex))),
                        }
                    }
                    try self.write("\"");
                    for (interp.parts) |p| {
                        switch (p) {
                            .text => {},
                            .expr => |e| {
                                try self.write(", ");
                                if (self.inferExprType(e) == .Bool) {
                                    try self.write("(");
                                    try self.genExpr(e);
                                    try self.write(" ? \"true\" : \"false\")");
                                } else {
                                    try self.genExpr(e);
                                }
                            },
                        }
                    }
                    try self.write(")");
                }
            },
        }
    }
    pub fn genStmt(self: *CodeGen, stmt: *ast.Stmt) !void {
        switch (stmt.*) {
            .expr_stmt => |e| {
                try self.writeIndent();
                try self.genExpr(e);
                try self.write(";\n");
            },
            .return_stmt => |expr| {
                try self.writeIndent();
                try self.write("return");
                if (expr.value) |e| {
                    try self.write(" ");
                    try self.genExpr(e);
                }
                try self.write(";\n");
            },
            .assignment => |assign| {
                try self.writeIndent();
                try self.write(assign.name);
                if (assign.index) |idx| {
                    try self.write("[");
                    try self.genExpr(idx);
                    try self.write("]");
                }
                try self.writeFmt(" {s} ", .{mapOp(assign.op)});
                try self.genExpr(assign.value);
                try self.write(";\n");
            },
            .var_decl => |d| {
                try self.symbol_types.put(d.name, d.ty);
                try self.writeIndent();
                try self.write(mapType(d.ty));
                try self.writeFmt(" {s}", .{d.name});
                if (d.array_size) |s| {
                    try self.writeFmt("[{d}]", .{s});
                }
                if (d.init) |ini| {
                    try self.write(" = ");
                    switch (ini) {
                        .expr => |e| try self.genExpr(e),
                        .array_literal => |ele| {
                            try self.write("{");
                            for (ele, 0..) |item, idx| {
                                if (idx > 0) {
                                    try self.write(", ");
                                }
                                try self.genExpr(item);
                            }
                            try self.write("}");
                        },
                    }
                }
                try self.write(";\n");
            },
            .block => |stmts| {
                try self.writeIndent();
                try self.write("{\n");
                self.addLevel();
                for (stmts) |s| {
                    try self.genStmt(s);
                }
                self.removeLevel();
                try self.writeIndent();
                try self.write("}\n");
            },
            .if_stmt => |if_node| {
                try self.writeIndent();
                try self.write("if (");
                try self.genExpr(if_node.condition);
                try self.write(") ");
                if (if_node.then_branch.* == .block) {
                    try self.write("{\n");
                    self.addLevel();
                    for (if_node.then_branch.block) |s| {
                        try self.genStmt(s);
                    }
                    self.removeLevel();
                    try self.writeIndent();
                    try self.write("}\n");
                } else {
                    try self.write("\n");
                    self.addLevel();
                    try self.genStmt(if_node.then_branch);
                    self.removeLevel();
                }
                if (if_node.else_branch) |else_stmt| {
                    try self.write("else ");
                    try self.genStmt(else_stmt);
                }
            },
            .while_stmt => |while_node| {
                try self.writeIndent();
                try self.write("while (");
                try self.genExpr(while_node.condition);
                try self.write(") ");
                if (while_node.body.* == .block) {
                    try self.write("{\n");
                    self.addLevel();
                    for (while_node.body.block) |s| {
                        try self.genStmt(s);
                    }
                    self.removeLevel();
                    try self.writeIndent();
                    try self.write("}\n");
                } else {
                    try self.write("\n");
                    self.addLevel();
                    try self.genStmt(while_node.body);
                    self.removeLevel();
                }
            },
            .func_decl => |func| {
                try self.writeIndent();
                if (std.mem.eql(u8, func.name, "main")) {
                    try self.write("int");
                } else {
                    try self.write(mapType(func.return_type));
                }
                try self.writeFmt(" {s}(", .{func.name});
                for (func.params, 0..) |param, idx| {
                    try self.symbol_types.put(param.name, param.ty);
                    if (idx > 0) {
                        try self.write(", ");
                    }
                    try self.writeFmt("{s} {s}", .{ mapType(param.ty), param.name });
                }
                try self.write(") ");
                try self.genStmt(func.body);
                try self.write("\n");
            },
            .program => |stmts| {
                try self.write("#include <stdio.h>\n");
                try self.write("#include <stdint.h>\n");
                try self.write("#include <inttypes.h>\n");
                try self.write("#include <stdbool.h>\n\n");
                for (stmts) |stm| {
                    try self.genStmt(stm);
                }
            },
        }
    }
    fn mapType(ty: TypeKind) []const u8 {
        return switch (ty) {
            .Int => "int64_t",
            .Bool => "bool",
            .String => "const char*",
            .void_ => "void",
            .Auto => unreachable,
        };
    }
    fn mapOp(op: TokenTag) []const u8 {
        return switch (op) {
            .plus => "+",
            .minus => "-",
            .star => "*",
            .slash => "/",
            .mod => "%",
            .equality => "==",
            .inequality => "!=",
            .lessthan => "<",
            .greaterthan => ">",
            .lessthan_equal => "<=",
            .greaterthan_equal => ">=",
            .equal => "=",
            .plus_equal => "+=",
            .minus_equal => "-=",
            .star_equal => "*=",
            .slash_equal => "/=",
            .mod_equal => "%=",
            else => "",
        };
    }
    fn inferExprType(self: *CodeGen, expr: *ast.Expr) lexer.TypeKind {
        return switch (expr.*) {
            .literal => |lit| switch (lit.value) {
                .number => .Int,
                .string => .String,
                .boolean => .Bool,
            },
            .variable => |v| self.symbol_types.get(v.name) orelse .Int,
            .binary => |b| switch (b.op) {
                .equality, .inequality, .lessthan, .greaterthan, .lessthan_equal, .greaterthan_equal => .Bool,
                else => .Int,
            },
            .unary => |u| switch (u.op) {
                .minus, .plus => .Int,
                else => .Int,
            },
            .index => |idx| self.symbol_types.get(idx.array) orelse .Int,
            .interpolated_string => .String,
            .call => .Int,
        };
    }
    fn getFormatSpecifier(ty: lexer.TypeKind) []const u8 {
        return switch (ty) {
            .Int => "%\" PRId64 \"",
            .String => "%s",
            .Bool => "%s",
            .void_ => "%s",
            .Auto => unreachable,
        };
    }

    fn write(self: *CodeGen, bytes: []const u8) !void {
        try self.output.appendSlice(self.allocator, bytes);
    }
    fn writeFmt(self: *CodeGen, comptime fmt: []const u8, args: anytype) !void {
        const text = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(text);
        try self.output.appendSlice(self.allocator, text);
    }
    fn writeEscapedText(self: *CodeGen, text: []const u8, is_format_string: bool) !void {
        var i: usize = 0;
        while (i < text.len) : (i += 1) {
            const c = text[i];
            if (c == '%' and is_format_string) {
                try self.write("%%");
            } else if (c == '\\' and i + 1 < text.len) {
                const next = text[i + 1];
                if (next == '{' or next == '}' or next == '"' or next == '\\' or next == 'n' or next == 't' or next == 'r') {
                    switch (next) {
                        'n' => try self.write("\\n"),
                        't' => try self.write("\\t"),
                        'r' => try self.write("\\r"),
                        '"' => try self.write("\\\""),
                        else => try self.writeFmt("{c}", .{next}),
                    }
                    i += 1;
                } else {
                    try self.writeFmt("{c}", .{c});
                }
            } else if (c == '"') {
                try self.write("\\\"");
            } else {
                try self.writeFmt("{c}", .{c});
            }
        }
    }
    fn writeIndent(self: *CodeGen) !void {
        for (0..self.indentation) |_| {
            try self.write("    ");
        }
    }
    fn addLevel(self: *CodeGen) void {
        self.indentation += 1;
    }
    fn removeLevel(self: *CodeGen) void {
        if (self.indentation > 0) {
            self.indentation -= 1;
        }
    }
};
