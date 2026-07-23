const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

const Stmt = ast.Stmt;
const Expr = ast.Expr;
const TypeKind = lexer.TypeKind;
const TokenTag = lexer.TokenTag;

const test1 = error{
    TypeCheckFailed,
} || std.mem.Allocator.Error;

pub const CheckErr = struct {
    message: []const u8,
};

const FuncSig = struct {
    return_type: TypeKind,
    param_types: []const TypeKind,
};

const Symbol = struct {
    ty: TypeKind,
    is_array: bool,
};

const Scope = std.StringHashMap(Symbol);
pub const Checker = struct {
    allocator: std.mem.Allocator,
    functions: std.StringHashMap(FuncSig),
    scopes: std.ArrayList(Scope),
    errors: std.ArrayList(CheckErr),
    current_return_type: ?TypeKind = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Checker {
        return .{
            .allocator = allocator,
            .functions = std.StringHashMap(FuncSig).init(allocator),
            .scopes = std.ArrayList(Scope).empty,
            .errors = std.ArrayList(CheckErr).empty,
        };
    }
    fn addError(self: *Self, line: usize, column: usize, comptime fmt: []const u8, args: anytype) !void {
        const msg = try std.fmt.allocPrint(self.allocator, "{d}:{d}: " ++ fmt, .{ line, column } ++ args);
        try self.errors.append(self.allocator, .{ .message = msg });
    }

    fn pushScope(self: *Self) !void {
        try self.scopes.append(self.allocator, Scope.init(self.allocator));
    }

    fn popScope(self: *Self) void {
        var scope = self.scopes.pop().?;
        scope.deinit();
    }
    fn declare(self: *Self, name: []const u8, ty: TypeKind, is_array: bool, line: usize, column: usize) !void {
        var top = &self.scopes.items[self.scopes.items.len - 1];
        if (top.contains(name)) {
            try self.addError(line, column, "redeclaration of variable '{s}' in the same scope", .{name});
            return;
        }
        try top.put(name, .{ .ty = ty, .is_array = is_array });
    }
    fn lookup(self: *Self, name: []const u8) ?Symbol {
        var i = self.scopes.items.len;
        while (i > 0) {
            i -= 1;
            if (self.scopes.items[i].get(name)) |sym| return sym;
        }
        return null;
    }
    pub fn collectFunctions(self: *Self, top_level: []const *Stmt) !void {
        for (top_level) |stmt| {
            if (stmt.* != .func_decl) continue;
            const f = stmt.func_decl;

            if (self.functions.contains(f.name)) {
                try self.addError(f.line, f.column, "redeclaration of function '{s}'", .{f.name});
                continue;
            }

            var param_types = try self.allocator.alloc(TypeKind, f.params.len);
            for (f.params, 0..) |p, i| param_types[i] = p.ty;

            try self.functions.put(f.name, .{
                .return_type = f.return_type,
                .param_types = param_types,
            });
        }
    }
    pub fn check(self: *Self, program: *const Stmt) !void {
        std.debug.assert(program.* == .program);
        try self.collectFunctions(program.program);

        try self.pushScope(); // global scope, for future globals if you add them
        for (program.program) |stmt| try self.checkStmt(stmt);
        self.popScope();
    }
    fn checkStmt(self: *Self, stmt: *const Stmt) !void {
        switch (stmt.*) {
            .var_decl => |v| {
                if (v.ty == .void_) { // if/when you add Void back into TypeKind
                    try self.addError(v.line, v.column, "variable '{s}' cannot have type void", .{v.name});
                }
                if (v.init) |init_val| {
                    switch (init_val) {
                        .expr => |ex| {
                            const ety = try self.checkExpr(ex);
                            if (ety != v.ty) {
                                try self.addError(
                                    v.line,
                                    v.column,
                                    "cannot initialize '{s}' ({s}) with value of type {s}",
                                    .{ v.name, @tagName(v.ty), @tagName(ety) },
                                );
                            }
                        },
                        .array_literal => |elems| {
                            for (elems) |el| {
                                const ety = try self.checkExpr(el);
                                if (ety != v.ty) {
                                    try self.addError(
                                        v.line,
                                        v.column,
                                        "array element for '{s}' has type {s}, expected {s}",
                                        .{ v.name, @tagName(ety), @tagName(v.ty) },
                                    );
                                }
                            }
                        },
                    }
                }
                try self.declare(v.name, v.ty, v.array_size != null, v.line, v.column);
            },

            .assignment => |a| {
                const sym = self.lookup(a.name) orelse {
                    try self.addError(a.line, a.column, "assignment to undeclared variable '{s}'", .{a.name});
                    return;
                };
                if (a.index) |idx| {
                    if (!sym.is_array) {
                        try self.addError(a.line, a.column, "'{s}' is not an array", .{a.name});
                    }
                    const sub_ty = try self.checkExpr(idx);
                    if (sub_ty != .Int) {
                        try self.addError(a.line, a.column, "array subscript for '{s}' must be int, got {s}", .{ a.name, @tagName(sub_ty) });
                    }
                }
                const vty = try self.checkExpr(a.value);
                if (vty != sym.ty) {
                    try self.addError(
                        a.line,
                        a.column,
                        "cannot assign {s} to '{s}' of type {s}",
                        .{ @tagName(vty), a.name, @tagName(sym.ty) },
                    );
                }
            },

            .func_decl => |f| {
                const prev_return = self.current_return_type;
                self.current_return_type = f.return_type;

                try self.pushScope();
                for (f.params) |p| {
                    if (p.ty == .void_) {
                        try self.addError(p.line, p.column, "parameter '{s}' cannot have type void", .{p.name});
                    }
                    try self.declare(p.name, p.ty, false, p.line, p.column);
                }
                try self.checkStmt(f.body);
                self.popScope();

                self.current_return_type = prev_return;
            },

            .if_stmt => |i| {
                const cty = try self.checkExpr(i.condition);
                if (cty != .Bool) {
                    try self.addError(i.line, i.column, "if condition must be bool, got {s}", .{@tagName(cty)});
                }
                try self.checkStmt(i.then_branch);
                if (i.else_branch) |eb| try self.checkStmt(eb);
            },

            .while_stmt => |w| {
                const cty = try self.checkExpr(w.condition);
                if (cty != .Bool) {
                    try self.addError(w.line, w.column, "while condition must be bool, got {s}", .{@tagName(cty)});
                }
                try self.checkStmt(w.body);
            },

            .return_stmt => |ret| {
                const expected = self.current_return_type orelse .void_;
                if (ret.value) |ex| {
                    const rty = try self.checkExpr(ex);
                    if (expected == .void_) {
                        try self.addError(
                            ret.line,
                            ret.column,
                            "cannot return a value from a function returning void",
                            .{},
                        );
                    } else if (rty != expected) {
                        try self.addError(
                            ret.line,
                            ret.column,
                            "return type {s} does not match function's declared return type {s}",
                            .{ @tagName(rty), @tagName(expected) },
                        );
                    }
                } else {
                    if (expected != .void_) {
                        try self.addError(
                            ret.line,
                            ret.column,
                            "non-void function must return a value of type {s}",
                            .{@tagName(expected)},
                        );
                    }
                }
            },
            .block => |stmts| {
                try self.pushScope();
                for (stmts) |s| try self.checkStmt(s);
                self.popScope();
            },

            .expr_stmt => |ex| {
                _ = try self.checkExpr(ex);
            },

            .program => unreachable, // handled by check()
        }
    }
    fn checkExpr(self: *Self, expr: *const Expr) !TypeKind {
        return switch (expr.*) {
            .literal => |lit| switch (lit.value) {
                .number => .Int,
                .string => .String,
                .boolean => .Bool,
            },

            .variable => |v| blk: {
                const sym = self.lookup(v.name) orelse {
                    try self.addError(v.line, v.column, "undeclared identifier '{s}'", .{v.name});
                    break :blk .Int; // placeholder so the walk can continue
                };
                break :blk sym.ty;
            },
            .unary => |u| blk: {
                const operand_ty = try self.checkExpr(u.operand);
                break :blk switch (u.op) {
                    .minus, .plus => ty: {
                        if (operand_ty != .Int) {
                            try self.addError(u.line, u.column, "unary {s} requires int operand, got {s}", .{ if (u.op == .minus) "-" else "+", @tagName(operand_ty) });
                        }
                        break :ty .Int;
                    },
                    else => ty: {
                        try self.addError(u.line, u.column, "unsupported unary operator", .{});
                        break :ty .Int;
                    },
                };
            },

            .index => |idx| blk: {
                const sym = self.lookup(idx.array) orelse {
                    try self.addError(idx.line, idx.column, "undeclared identifier '{s}'", .{idx.array});
                    break :blk .Int;
                };
                if (!sym.is_array) {
                    try self.addError(idx.line, idx.column, "'{s}' is not an array", .{idx.array});
                }
                const sub_ty = try self.checkExpr(idx.subscript);
                if (sub_ty != .Int) {
                    try self.addError(idx.line, idx.column, "array subscript for '{s}' must be int", .{idx.array});
                }
                break :blk sym.ty;
            },

            .binary => |b| blk: {
                const lty = try self.checkExpr(b.left);
                const rty = try self.checkExpr(b.right);
                break :blk try self.checkBinaryOp(b.op, lty, rty, b.line, b.column);
            },

            .call => |c| blk: {
                if (std.mem.eql(u8, c.callee, "print")) {
                    // builtin: accepts any number of args of any type, returns void
                    for (c.args) |arg| _ = try self.checkExpr(arg);
                    break :blk .void_;
                }
                const sig = self.functions.get(c.callee) orelse {
                    try self.addError(c.line, c.column, "call to undeclared function '{s}'", .{c.callee});
                    for (c.args) |arg| _ = try self.checkExpr(arg);
                    break :blk .Int;
                };

                if (c.args.len != sig.param_types.len) {
                    try self.addError(
                        c.line,
                        c.column,
                        "'{s}' expects {d} argument(s), got {d}",
                        .{ c.callee, sig.param_types.len, c.args.len },
                    );
                }

                const n = @min(c.args.len, sig.param_types.len);
                for (c.args[0..n], sig.param_types[0..n], 0..) |arg, expected_ty, i| {
                    const arg_ty = try self.checkExpr(arg);
                    if (arg_ty != expected_ty) {
                        try self.addError(
                            c.line,
                            c.column,
                            "'{s}' argument {d}: expected {s}, got {s}",
                            .{ c.callee, i + 1, @tagName(expected_ty), @tagName(arg_ty) },
                        );
                    }
                }
                // in case there are extra unchecked args (arity already reported)
                if (c.args.len > sig.param_types.len) {
                    for (c.args[n..]) |arg| _ = try self.checkExpr(arg);
                }

                break :blk sig.return_type;
            },
        };
    }

    fn checkBinaryOp(self: *Self, op: TokenTag, lty: TypeKind, rty: TypeKind, line: usize, column: usize) !TypeKind {
        return switch (op) {
            .plus, .minus, .star, .slash, .mod => blk: {
                if (lty != .Int or rty != .Int) {
                    try self.addError(line, column, "arithmetic operator requires int operands, got {s} and {s}", .{ @tagName(lty), @tagName(rty) });
                }
                break :blk .Int;
            },
            .lessthan, .lessthan_equal, .greaterthan, .greaterthan_equal => blk: {
                if (lty != .Int or rty != .Int) {
                    try self.addError(line, column, "comparison operator requires int operands, got {s} and {s}", .{ @tagName(lty), @tagName(rty) });
                }
                break :blk .Bool;
            },
            .equality, .inequality => blk: {
                if (lty != rty) {
                    try self.addError(line, column, "cannot compare {s} with {s}", .{ @tagName(lty), @tagName(rty) });
                }
                break :blk .Bool;
            },
            else => blk: {
                try self.addError(line, column, "unsupported binary operator", .{});
                break :blk .Int;
            },
        };
    }
};

fn exprPos(expr: *const Expr) struct { line: usize, column: usize } {
    return switch (expr.*) {
        .variable => |v| .{ .line = v.line, .column = v.column },
        .binary => |b| .{ .line = b.line, .column = b.column },
        .call => |c| .{ .line = c.line, .column = c.column },
        .index => |i| .{ .line = i.line, .column = i.column },
        .literal => |l| .{ .line = l.line, .column = l.column },
        .unary => |u| .{ .line = u.line, .column = u.column },
    };
}
