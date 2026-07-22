const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const TokenTag = lexer.TokenTag;
const TypeKind = lexer.TypeKind;

pub const Printer = struct {
    indentation: usize,
    pub fn init() Printer {
        return .{ .indentation = 0 };
    }
    pub fn printAst(self: *Printer, statement: *ast.Stmt) !void {
        try self.printStatement(statement);
    }
    fn printStatement(self: *Printer, stmt: *const ast.Stmt) !void {
        switch (stmt.*) {
            .program => |program| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Program\n", .{});

                self.addLevel();

                for (program) |childnode| {
                    try self.printStatement(childnode);
                }

                self.removeLevel();
            },
            .block => |statements| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Block\n", .{});
                self.addLevel();
                for (statements) |statement| {
                    try self.printStatement(statement);
                }
                self.removeLevel();
            },
            .func_decl => |func| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Function {s} -> {s}\n", .{ func.name, typeName(func.return_type) });
                self.addLevel();
                if (func.params.len > 0) {
                    try self.printIndent();
                    try self.printPrefix();
                    std.debug.print("Parameters\n", .{});
                    self.addLevel();
                    try self.printParameters(func.params);
                    self.removeLevel();
                }
                try self.printStatement(func.body);
                self.removeLevel();
            },

            .var_decl => |decl| {
                try self.printIndent();
                try self.printPrefix();

                std.debug.print(
                    "VarDecl {s} {s}",
                    .{ typeName(decl.ty), decl.name },
                );
                if (decl.array_size) |size| {
                    std.debug.print("[{}]", .{size});
                }
                std.debug.print("\n", .{});
                if (decl.init) |initializer| {
                    self.addLevel();

                    try self.printIndent();
                    try self.printPrefix();
                    std.debug.print("Initializer\n", .{});
                    self.addLevel();
                    switch (initializer) {
                        .expr => |expr| {
                            try self.printExpression(expr);
                        },
                        .array_literal => |elements| {
                            try self.printIndent();
                            try self.printPrefix();
                            std.debug.print("ArrayLiteral\n", .{});
                            self.addLevel();
                            for (elements) |elem| {
                                try self.printExpression(elem);
                            }
                            self.removeLevel();
                        },
                    }
                    self.removeLevel();
                    self.removeLevel();
                }
            },
            .assignment => |assign| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Assignment {s} {s}\n", .{ assign.name, operatorName(assign.op) });
                self.addLevel();
                if (assign.index) |index| {
                    try self.printIndent();
                    try self.printPrefix();
                    std.debug.print("Index\n", .{});
                    self.addLevel();
                    try self.printExpression(index);
                    self.removeLevel();
                }
                try self.printExpression(assign.value);
                self.removeLevel();
            },
            .if_stmt => |ifstmt| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("If\n", .{});
                self.addLevel();
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Condition\n", .{});
                self.addLevel();

                try self.printExpression(ifstmt.condition);
                self.removeLevel();
                try self.printStatement(ifstmt.then_branch);
                if (ifstmt.else_branch) |else_branch| {
                    try self.printStatement(else_branch);
                }
                self.removeLevel();
            },

            .while_stmt => |whilestmt| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("While\n", .{});
                self.addLevel();
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Condition\n", .{});
                self.addLevel();
                try self.printExpression(whilestmt.condition);
                self.removeLevel();
                try self.printStatement(whilestmt.body);
                self.removeLevel();
            },

            .return_stmt => |value| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Return\n", .{});
                if (value) |expr| {
                    self.addLevel();
                    try self.printExpression(expr);
                    self.removeLevel();
                }
            },
            .expr_stmt => |expr| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("ExpressionStatement\n", .{});
                self.addLevel();
                try self.printExpression(expr);
                self.removeLevel();
            },
        }
    }

    fn printExpression(self: *Printer, expr: *const ast.Expr) !void {
        switch (expr.*) {
            .variable => |name| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Variable {s}\n", .{name});
            },

            .literal => |literal| {
                try self.printIndent();
                try self.printPrefix();
                switch (literal) {
                    .number => |num| {
                        std.debug.print("Literal {d}\n", .{num});
                    },
                    .string => |str| {
                        std.debug.print("Literal \"{s}\"\n", .{str});
                    },
                    .boolean => |boolean| {
                        std.debug.print("Literal {}\n", .{boolean});
                    },
                }
            },
            .binary => |binary| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Binary {s}\n", .{operatorName(binary.op)});
                self.addLevel();
                try self.printExpression(binary.left);
                try self.printExpression(binary.right);
                self.removeLevel();
            },
            .call => |call| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Call {s}\n", .{call.callee});
                self.addLevel();
                for (call.args) |arg| {
                    try self.printExpression(arg);
                }
                self.removeLevel();
            },
            .index => |index| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Index {s}\n", .{index.array});
                self.addLevel();
                try self.printExpression(index.subscript);
                self.removeLevel();
            },
            .unary => |unary| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("Unary {s}\n", .{operatorName(unary.op)});
                self.addLevel();
                try self.printExpression(unary.operand);
                self.removeLevel();
            },
            .interpolated_string => |parts| {
                try self.printIndent();
                try self.printPrefix();
                std.debug.print("InterpolatedString\n", .{});
                self.addLevel();
                for (parts) |part| {
                    switch (part) {
                        .text => |text| {
                            try self.printIndent();
                            try self.printPrefix();
                            std.debug.print("Text \"{s}\"\n", .{text});
                        },
                        .expr => |expr1| {
                            try self.printIndent();
                            try self.printPrefix();
                            std.debug.print("Interpolation\n", .{});
                            self.addLevel();
                            try self.printExpression(expr1);
                            self.removeLevel();
                        },
                    }
                }
                self.removeLevel();
            },
        }
    }
    fn printParameters(self: *Printer, params: []const ast.Param) !void {
        for (params) |param| {
            try self.printIndent();
            try self.printPrefix();
            std.debug.print("Param {s}: {s}\n", .{ param.name, typeName(param.ty) });
        }
    }

    fn printIndent(self: *Printer) !void {
        for (0..self.indentation) |_| {
            std.debug.print("|   ", .{});
        }
    }
    fn printPrefix(self: *Printer) !void {
        _ = self;
        std.debug.print("└── ", .{});
    }
    fn addLevel(self: *Printer) void {
        self.indentation += 1;
    }

    fn removeLevel(self: *Printer) void {
        if (self.indentation > 0) {
            self.indentation -= 1;
        }
    }

    fn operatorName(tag: TokenTag) []const u8 {
        return switch (tag) {
            .plus => "+",
            .minus => "-",
            .star => "*",
            .slash => "/",
            .mod => "%",
            .equal => "=",
            .plus_equal => "+=",
            .minus_equal => "-=",
            .star_equal => "*=",
            .slash_equal => "/=",
            .mod_equal => "%=",
            .equality => "==",
            .inequality => "!=",
            .lessthan => "<",
            .lessthan_equal => "<=",
            .greaterthan => ">",
            .greaterthan_equal => ">=",
            else => "unknown",
        };
    }
    fn typeName(ty: TypeKind) []const u8 {
        return switch (ty) {
            .Int => "Int",
            .Bool => "Bool",
            .String => "String", //todo: need to add an invalid type after tanishk's pr gets merged
        };
    }
};
