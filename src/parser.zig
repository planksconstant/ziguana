const ast = @import("ast.zig");
const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenTag = lexer.TokenTag;
const TokenPayload = lexer.TokenPayload;

const Stmt = ast.Stmt;
const Param = ast.Param;
const VarInit = ast.VarInit;
const Expr = ast.Expr;
const Literal = ast.Literal;

//errors
const ParserErrors = error{
    ExpectedAssignmentOperator,
    ExpectedExpression,
    UnexpectedLiteral,
    UnexpectedStatementStart,
    ExpectedToken,
    ExpectedType,
    ExpectedIdentifier,
    UnexpectedToken,
} || std.mem.Allocator.Error;

//all parser declarations and implementation in this file
pub const ParseErr = struct {
    message: []const u8,
    token: Token,
};

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    errors: std.ArrayList(ParseErr),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, tokens: []const Token) Parser {
        return .{ .tokens = tokens, .current = 0, .errors = std.ArrayList(ParseErr).empty, .allocator = allocator };
    }

    fn getTag(token: Token) TokenTag {
        return std.meta.activeTag(token.payload);
    }
    //Parser helper functions start here

    fn peek(self: *Self) Token {
        return self.tokens[self.current];
    }

    fn isAtEnd(self: *const Self) bool {
        if (getTag(self.tokens[self.current]) == .eof) {
            return true;
        }
        return false;
    }

    fn previous(self: *Self) Token {
        return self.tokens[self.current - 1];
    }

    fn advance(self: *Self) Token {
        if (!self.isAtEnd()) {
            self.current += 1;
            return self.tokens[self.current - 1];
        } else {
            return self.tokens[self.current];
        }
    }
    fn consume(self: *Self, expected: TokenTag) !Token {
        if (getTag(self.peek()) != expected)
            return error.ExpectedToken;

        return self.advance();
    }
    fn peekNext(self: *Self) Token {
        if (self.current + 1 >= self.tokens.len) {
            return self.tokens[self.current];
        }

        return self.tokens[self.current + 1];
    }

    fn parseProgram(self: *Self) ParserErrors!*Stmt {
        var stmts = std.ArrayList(*Stmt).empty;

        while (!self.isAtEnd()) {
            if (getTag(self.peek()) == .func) {
                try stmts.append(self.allocator, try self.parseFunction());
            } else {
                try stmts.append(self.allocator, try self.parseStatement());
            }
        }

        return try ast.makeProgram(
            self.allocator,
            try stmts.toOwnedSlice(self.allocator),
        );
    }
    fn parseFunction(self: *Self) ParserErrors!*Stmt {
        const funcTok = try self.consume(.func);

        const typeToken = try self.consume(.type_);
        const return_type = typeToken.payload.type_;

        const nameToken = try self.consume(.identifier);
        const name = nameToken.payload.identifier;

        _ = try self.consume(.lparen);
        var params = std.ArrayList(Param).empty;

        if (getTag(self.peek()) != .rparen) {
            try params.append(self.allocator, try self.parseParameter());

            while (getTag(self.peek()) == .comma) {
                _ = try self.consume(.comma);
                try params.append(self.allocator, try self.parseParameter());
            }
        }

        _ = try self.consume(.rparen);

        const body = try self.parseBlock();

        return try ast.makeFuncDecl(
            self.allocator,
            return_type,
            name,
            try params.toOwnedSlice(self.allocator),
            body,
            funcTok.line,
            funcTok.column,
        );
    }
    fn parseBlock(self: *Self) ParserErrors!*Stmt {
        _ = try self.consume(.lbrace);
        var stmts = std.ArrayList(*Stmt).empty;
        while (getTag(self.peek()) != .rbrace and !self.isAtEnd()) {
            try stmts.append(self.allocator, try self.parseStatement());
        }
        _ = try self.consume(.rbrace);
        return ast.makeBlock(self.allocator, try stmts.toOwnedSlice(self.allocator));
    }
    fn parseStatement(self: *Self) ParserErrors!*Stmt {
        return switch (getTag(self.peek())) {
            .type_ => self.parseVarDecl(),
            .if_ => self.parseIfStatement(),
            .while_ => self.parseWhileStatement(),
            .return_ => self.parseReturnStatement(),
            .identifier => blk: {
                const after = self.peekNext();
                break :blk switch (getTag(after)) {
                    .lparen => self.parseCallStatement(),
                    .lbracket, .equal, .plus_equal, .minus_equal => self.parseAssignment(),
                    else => error.UnexpectedToken,
                };
            },
            else => error.UnexpectedStatementStart,
        };
    }
    fn parseParameter(self: *Self) !Param {
        const typeToken = self.advance();
        if (getTag(typeToken) != .type_) {
            return error.ExpectedType;
        }
        const ty = typeToken.payload.type_;
        const identToken = self.advance();
        if (getTag(identToken) != .identifier) {
            return error.ExpectedIdentifier;
        }
        const ident = identToken.payload.identifier;

        return .{ .ty = ty, .name = ident, .line = typeToken.line, .column = typeToken.column };
    }
    fn parseLiteral(self: *Self) ParserErrors!*Expr {
        const token = self.advance();
        switch (token.payload) {
            .number => |value| {
                return try ast.makeLiteral(self.allocator, .{ .number = value }, token.line, token.column);
            },
            .string => |value| {
                return try ast.makeLiteral(self.allocator, .{
                    .string = value,
                }, token.line, token.column);
            },
            .true_ => {
                return try ast.makeLiteral(self.allocator, .{
                    .boolean = true,
                }, token.line, token.column);
            },
            .false_ => {
                return try ast.makeLiteral(self.allocator, .{
                    .boolean = false,
                }, token.line, token.column);
            },
            else => return error.UnexpectedLiteral,
        }
    }
    fn parseVarInit(self: *Self) !VarInit {
        if (getTag(self.peek()) != .lbrace) {
            return .{
                .expr = try self.parseExpression(),
            };
        }
        _ = try self.consume(.lbrace);
        var elements = std.ArrayList(*ast.Expr).empty;
        if (getTag(self.peek()) != .rbrace) {
            try elements.append(self.allocator, try self.parseExpression());
            while (getTag(self.peek()) == .comma) {
                _ = try self.consume(.comma);
                try elements.append(self.allocator, try self.parseExpression());
            }
        }
        _ = try self.consume(.rbrace);
        return .{
            .array_literal = try elements.toOwnedSlice(self.allocator),
        };
    }
    fn parseVarDecl(self: *Self) !*Stmt {
        const typeToken = try self.consume(.type_);
        const ty = typeToken.payload.type_;

        const identToken = try self.consume(.identifier);
        const name = identToken.payload.identifier;

        var array_size: ?usize = null;

        if (getTag(self.peek()) == .lbracket) {
            _ = try self.consume(.lbracket);

            const sizeToken = try self.consume(.number);
            array_size = @intCast(sizeToken.payload.number);

            _ = try self.consume(.rbracket);
        }

        var vinit: ?ast.VarInit = null;

        if (getTag(self.peek()) == .equal) {
            _ = try self.consume(.equal);
            vinit = try self.parseVarInit();
        }

        _ = try self.consume(.semicolon);

        return try ast.makeVarDecl(
            self.allocator,
            ty,
            array_size,
            name,
            vinit,
            typeToken.line,
            typeToken.column,
        );
    }
    fn parseExpression(self: *Self) ParserErrors!*Expr {
        return self.parseEquality();
    }
    fn parseEquality(self: *Self) ParserErrors!*Expr {
        var left = try self.parseComparison();
        while (getTag(self.peek()) == .equality or getTag(self.peek()) == .inequality) {
            const operator = self.advance();
            const right = try self.parseComparison();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right, operator.line, operator.column);
        }
        return left;
    }
    fn parseComparison(self: *Self) ParserErrors!*Expr {
        var left = try self.parseTerm();

        while (getTag(self.peek()) == .lessthan or getTag(self.peek()) == .lessthan_equal or getTag(self.peek()) == .greaterthan or getTag(self.peek()) == .greaterthan_equal) {
            const operator = self.advance();
            const right = try self.parseTerm();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right, operator.line, operator.column); //chk line column pa//rameters
        }

        return left;
    }
    fn parseTerm(self: *Self) ParserErrors!*Expr {
        var left = try self.parseFactor();

        while (getTag(self.peek()) == .plus or getTag(self.peek()) == .minus) {
            const operator = self.advance();
            const right = try self.parseFactor();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right, operator.line, operator.column);
        }
        return left;
    }
    fn parseFactor(self: *Self) ParserErrors!*Expr {
        var left = try self.parseUnary();
        while (getTag(self.peek()) == .star or getTag(self.peek()) == .slash or getTag(self.peek()) == .mod) {
            const operator = self.advance();
            const right = try self.parseUnary();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right, operator.line, operator.column); //chk parameters
        }
        return left;
    }

    fn parseArrayAccess(self: *Self) ParserErrors!*Expr {
        const nameToken = try self.consume(.identifier);
        const array = nameToken.payload.identifier;
        _ = try self.consume(.lbracket);
        const subscript = try self.parseExpression();
        _ = try self.consume(.rbracket);
        return ast.makeIndex(self.allocator, array, subscript, nameToken.line, nameToken.column);
    }
    fn parsePrimary(self: *Self) ParserErrors!*Expr {
        var token = self.peek();
        switch (getTag(token)) {
            .number, .string, .true_, .false_ => {
                return self.parseLiteral();
            },
            .identifier => {
                if (getTag(self.peekNext()) == .lparen) {
                    return self.parseFunctionCall();
                }
                if (getTag(self.peekNext()) == .lbracket) {
                    return self.parseArrayAccess();
                }

                token = self.advance();
                return try ast.makeVariable(self.allocator, token.payload.identifier, token.line, token.column);
            },
            .lparen => {
                _ = self.advance();
                const expression = try self.parseExpression();
                _ = try self.consume(.rparen);
                return expression;
            },
            .string_start => {
                return self.parseInterpolatedString();
            },
            else => {
                return error.ExpectedExpression;
            },
        }
    }
    fn parseUnary(self: *Self) ParserErrors!*Expr {
        const tag = getTag(self.peek());
        if (tag == .minus or tag == .plus) {
            const op = self.advance();
            const operand = try self.parseUnary();
            return ast.makeUnary(
                self.allocator,
                getTag(op),
                operand,
                op.line,
                op.column,
            );
        }
        return self.parsePrimary();
    }
    fn parseAssignment(self: *Self) !*Stmt {
        const nameToken = try self.consume(.identifier);
        const name = nameToken.payload.identifier;
        var index: ?*Expr = null;
        if (getTag(self.peek()) == .lbracket) {
            _ = try self.consume(.lbracket);
            index = try self.parseExpression();
            _ = try self.consume(.rbracket);
        }
        const opToken = self.advance();
        const op = getTag(opToken);
        if (op != .equal and op != .plus_equal and op != .minus_equal) {
            return error.ExpectedAssignmentOperator;
        }
        const value = try self.parseExpression();
        _ = try self.consume(.semicolon);
        return ast.makeAssignment(self.allocator, name, index, op, value, nameToken.line, nameToken.column);
    }

    fn parseCallStatement(self: *Self) ParserErrors!*Stmt {
        const call_exp = try self.parseFunctionCall();
        _ = try self.consume(.semicolon);
        return ast.makeExprStmt(self.allocator, call_exp);
    }
    fn parseIfStatement(self: *Self) ParserErrors!*Stmt {
        const ifToken = try self.consume(.if_);
        // _ = try self.consume(.if_);//patch not required
        _ = try self.consume(.lparen);
        const condition = try self.parseExpression();
        _ = try self.consume(.rparen);

        const if_branch = try self.parseBlock(); //just parse the thing in {..}
        //check for else
        var else_branch: ?*Stmt = null;
        if (getTag(self.peek()) == .else_) {
            _ = try self.consume(.else_);
            else_branch = try self.parseBlock();
        }
        return ast.makeIfStmt(self.allocator, condition, if_branch, else_branch, ifToken.line, ifToken.column);
    }
    fn parseWhileStatement(self: *Self) ParserErrors!*Stmt {
        const whileTok = try self.consume(.while_);

        _ = try self.consume(.lparen);
        const condition = try self.parseExpression();
        _ = try self.consume(.rparen);
        const content = try self.parseBlock();
        return ast.makeWhileStmt(self.allocator, condition, content, whileTok.line, whileTok.column);
    }
    fn parseReturnStatement(self: *Self) ParserErrors!*Stmt {
        const returnKeyword = try self.consume(.return_);
        var value: ?*Expr = null;
        if (getTag(self.peek()) != .semicolon) {
            value = try self.parseExpression();
        }
        _ = try self.consume(.semicolon);
        return ast.makeReturnStmt(self.allocator, value, returnKeyword.line, returnKeyword.column);
    }

    fn parseFunctionCall(self: *Self) ParserErrors!*Expr {
        const nameToken = try self.consume(.identifier);
        const callee = nameToken.payload.identifier;
        _ = try self.consume(.lparen);
        var args = std.ArrayList(*Expr).empty;
        if (getTag(self.peek()) != .rparen) {
            try args.append(self.allocator, try self.parseExpression());
            while (getTag(self.peek()) == .comma) {
                _ = try self.consume(.comma);
                try args.append(self.allocator, try self.parseExpression());
            }
        }
        _ = try self.consume(.rparen);
        return ast.makeCall(self.allocator, callee, try args.toOwnedSlice(self.allocator), nameToken.line, nameToken.column);
    }
    fn parseInterpolatedString(self: *Self) ParserErrors!*Expr {
        const startToken = try self.consume(.string_start);
        var parts = std.ArrayList(ast.InterpPart).empty;
        while (true) {
            switch (getTag(self.peek())) {
                .string_segment => {
                    const tok = self.advance();
                    try parts.append(self.allocator, .{
                        .text = tok.payload.string_segment,
                    });
                },
                .interpolation_start => {
                    _ = try self.consume(.interpolation_start);
                    const expr = try self.parseExpression();
                    _ = try self.consume(.interpolation_end);
                    try parts.append(self.allocator, .{
                        .expr = expr,
                    });
                },

                .string_end => {
                    _ = try self.consume(.string_end);
                    break;
                },
                else => return error.ExpectedExpression,
            }
        }
        return ast.makeInterpolatedString(self.allocator, try parts.toOwnedSlice(self.allocator), startToken.line, startToken.column);
    }

    pub fn parse(self: *Self) ParserErrors!*Stmt {
        return try self.parseProgram();
    }
};
