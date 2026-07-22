const std = @import("std");
const TokenTag = @import("lexer.zig").TokenTag;
const TypeKind = @import("lexer.zig").TypeKind;

pub const Literal = union(enum) {
    number: i64,
    string: []const u8,
    boolean: bool,
};

pub const Expr = union(enum) {
    variable: []const u8,

    binary: struct {
        op: TokenTag, //operator
        left: *Expr,
        right: *Expr,
    },
    call: struct {
        callee: []const u8,
        args: []*Expr,
    },
    index: struct {
        array: []const u8,
        subscript: *Expr,
    },
    literal: Literal,
    unary: UnaryExpr,
    interpolated_string: []InterpPart,
};

pub const UnaryExpr = struct {
    op: TokenTag,
    operand: *Expr,
};

pub const VarInit = union(enum) {
    expr: *Expr,
    array_literal: []*Expr,
};

pub const InterpPart = union(enum) {
    text: []const u8,
    expr: *Expr,
};

pub const Param = struct {
    ty: TypeKind,
    name: []const u8,
};

pub const Stmt = union(enum) {
    var_decl: struct {
        ty: TypeKind,
        array_size: ?usize,
        name: []const u8,
        init: ?VarInit,
    },

    assignment: struct {
        name: []const u8,
        index: ?*Expr,
        op: TokenTag,
        value: *Expr,
    },

    func_decl: struct {
        return_type: TypeKind,
        name: []const u8,
        params: []Param,
        body: *Stmt,
    },

    if_stmt: struct {
        condition: *Expr,
        then_branch: *Stmt,
        else_branch: ?*Stmt,
    },

    while_stmt: struct {
        condition: *Expr,
        body: *Stmt,
    },

    return_stmt: ?*Expr,
    block: []*Stmt,
    expr_stmt: *Expr,
    program: []*Stmt,
};

pub fn makeLiteral(a: std.mem.Allocator, lit: Literal) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .literal = lit };
    return node;
}

pub fn makeVariable(a: std.mem.Allocator, name: []const u8) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .variable = name };
    return node;
}

pub fn makeBinary(a: std.mem.Allocator, op: TokenTag, left: *Expr, right: *Expr) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .binary = .{ .op = op, .left = left, .right = right } };
    return node;
}

pub fn makeCall(a: std.mem.Allocator, callee: []const u8, args: []*Expr) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .call = .{ .callee = callee, .args = args } };
    return node;
}

pub fn makeIndex(a: std.mem.Allocator, array: []const u8, subscript: *Expr) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .index = .{ .array = array, .subscript = subscript } };
    return node;
}

pub fn makeIfStmt(a: std.mem.Allocator, condition: *Expr, then_branch: *Stmt, else_branch: ?*Stmt) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .if_stmt = .{ .condition = condition, .then_branch = then_branch, .else_branch = else_branch } };
    return node;
}

pub fn makeWhileStmt(a: std.mem.Allocator, condition: *Expr, body: *Stmt) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .while_stmt = .{ .condition = condition, .body = body } };
    return node;
}

pub fn makeBlock(a: std.mem.Allocator, stmts: []*Stmt) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .block = stmts };
    return node;
}

pub fn makeVarDecl(a: std.mem.Allocator, ty: TypeKind, array_size: ?usize, name: []const u8, init: ?VarInit) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .var_decl = .{ .ty = ty, .array_size = array_size, .name = name, .init = init } };
    return node;
}

pub fn makeAssignment(a: std.mem.Allocator, name: []const u8, index: ?*Expr, op: TokenTag, value: *Expr) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .assignment = .{ .name = name, .index = index, .op = op, .value = value } };
    return node;
}

pub fn makeFuncDecl(a: std.mem.Allocator, return_type: TypeKind, name: []const u8, params: []Param, body: *Stmt) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .func_decl = .{ .return_type = return_type, .name = name, .params = params, .body = body } };
    return node;
}

pub fn makeReturnStmt(a: std.mem.Allocator, value: ?*Expr) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .return_stmt = value };
    return node;
}

pub fn makeExprStmt(a: std.mem.Allocator, expr: *Expr) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .expr_stmt = expr };
    return node;
}

pub fn makeProgram(a: std.mem.Allocator, stmts: []*Stmt) !*Stmt {
    const node = try a.create(Stmt);
    node.* = .{ .program = stmts };
    return node;
}
pub fn makeUnary(a: std.mem.Allocator, op: TokenTag, operand: *Expr) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .unary = .{ .op = op, .operand = operand } };
    return node;
}
pub fn makeInterpolatedString(a: std.mem.Allocator, parts: []InterpPart) !*Expr {
    const node = try a.create(Expr);
    node.* = .{ .interpolated_string = parts };
    return node;
}
