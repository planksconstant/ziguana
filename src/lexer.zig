const std = @import("std");
const print = std.debug.print;

pub const TypeKind = enum {
    Int,
    Bool, //B is in Upper-case
    String,
};

pub const TokenTag = enum {
    eof,
    lparen,
    rparen,
    lbrace, // {
    rbrace, // }
    lbracket, //[
    rbracket, //]
    comma,
    plus,
    minus,
    star,
    slash,
    mod,
    equal, // =
    plus_equal, // +=
    minus_equal, // -=
    star_equal, // *=
    slash_equal, // /=
    mod_equal, // %=
    equality, // ==
    inequality, // !=
    lessthan,
    lessthan_equal, // <=
    greaterthan,
    greaterthan_equal, // >=
    return_,
    type_,
    string,
    identifier,
    number,
    colon,
    if_,
    else_,
    while_,
    func,
    semicolon,
    true_,
    false_,
    void_,
    invalid, // for collecting errors
};

pub const TokenPayload = union(TokenTag) {
    eof: void,
    lparen: void,
    rparen: void,
    lbrace: void, // {
    rbrace: void, // }
    lbracket: void, //[
    rbracket: void, //]
    comma: void,
    plus: void,
    minus: void,
    star: void,
    slash: void,
    mod: void,
    equal: void, // =
    plus_equal: void, // +=
    minus_equal: void, // -=
    star_equal: void, // *=
    slash_equal: void, // /=
    mod_equal: void, // %=
    equality: void, // ==
    inequality: void, // !=
    lessthan: void,
    lessthan_equal: void, // <=
    greaterthan: void,
    greaterthan_equal: void, // >=
    return_: void,
    type_: TypeKind,
    string: []const u8,
    identifier: []const u8,
    number: i64,
    colon: void,
    if_: void,
    else_: void,
    while_: void,
    func: void,
    semicolon: void,
    true_: void,
    false_: void,
    invalid: []const u8,
    void_: void,
};

pub const Token = struct {
    payload: TokenPayload,
    line: usize,
    column: usize,
};

// Lexer structure -
pub const Lexer = struct {
    input: []const u8, // file content
    position: usize = 0, // current character position
    ch: u8 = 0, // character at the current position
    line: usize = 1, // line number
    column: usize = 0, // column number

    pub fn init(input: []const u8) Lexer {
        var l = Lexer{ .input = input };
        if (input.len > 0) {
            l.ch = input[0];
            l.column = 1;
        }
        return l;
    }

    // Helper Functions -
    pub fn readChar(self: *Lexer) void {
        if (self.position + 1 >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.position + 1];
        }
        self.position += 1;
        self.column += 1;
    }
    pub fn peekChar(self: *Lexer) ?u8 {
        if (self.position + 1 >= self.input.len) {
            return 0;
        } else {
            return self.input[self.position + 1];
        }
    }
    pub fn skipWhiteSpace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            if (self.ch == '\n') {
                self.line += 1;
                self.column = 0;
            }
            self.readChar();
        }
    }
    pub fn skipComment(self: *Lexer) void {
        while (self.ch != '\n' and self.ch != 0) {
            self.readChar();
        }
        self.skipWhiteSpace();
    }
    pub fn readNumber(self: *Lexer) i64 {
        const start = self.position;
        while (std.ascii.isDigit(self.ch)) {
            self.readChar();
        }
        const number_slice: []const u8 = self.input[start..self.position];
        return std.fmt.parseInt(i64, number_slice, 10) catch 0;
    }
    pub fn readString(self: *Lexer) ?[]const u8 {
        self.readChar(); // ignoring the opening quote
        const start: usize = self.position;
        while (self.ch != '"' and self.ch != 0) {
            if (self.ch == '\n') {
                self.line += 1;
                self.column = 0;
            }
            self.readChar();
        }
        if (self.ch == 0) {
            // ** should work on this
            // return self.input[start..self.position];
            //error - did not put closing quote for the string
            return null;
        }
        const string_slice: []const u8 = self.input[start..self.position];
        self.readChar(); // ignoring the closing quote
        return string_slice;
    }
    pub fn readIdentifier(self: *Lexer) []const u8 {
        const start: usize = self.position;
        while (std.ascii.isDigit(self.ch) or std.ascii.isAlphabetic(self.ch) or self.ch == '_') {
            self.readChar();
        }
        return self.input[start..self.position];
    }
    pub fn lookUpKeyword(word: []const u8) TokenPayload {
        const keywords =
            .{
                .{ "fn", TokenPayload{ .func = {} } },
                .{ "int", TokenPayload{ .type_ = .Int } },
                .{ "bool", TokenPayload{ .type_ = .Bool } },
                .{ "string", TokenPayload{ .type_ = .String } },
                .{ "if", TokenPayload{ .if_ = {} } },
                .{ "void", TokenPayload{ .void_ = {} } },
                .{ "else", TokenPayload{ .else_ = {} } },
                .{ "while", TokenPayload{ .while_ = {} } },
                .{ "return", TokenPayload{ .return_ = {} } },
                .{ "true", TokenPayload{ .true_ = {} } },
                .{ "false", TokenPayload{ .false_ = {} } },
            };

        const map = std.StaticStringMap(TokenPayload).initComptime(keywords);

        if (map.get(word)) |payload| {
            return payload;
        }
        return .{ .identifier = word };
    }

    // main token loop function -
    pub fn nextToken(self: *Lexer) Token {
        // Whitespaces and comments -
        self.skipWhiteSpace();
        if (self.ch == '/' and self.peekChar() == '/') {
            self.skipComment();
            return self.nextToken();
        }

        const start_line: usize = self.line;
        const start_col: usize = self.column;

        // Symbols -
        switch (self.ch) {
            '(' => {
                self.readChar();
                return Token{ .payload = .{ .lparen = {} }, .line = start_line, .column = start_col };
            },
            ')' => {
                self.readChar();
                return Token{ .payload = .{ .rparen = {} }, .line = start_line, .column = start_col };
            },
            '{' => {
                self.readChar();
                return Token{ .payload = .{ .lbrace = {} }, .line = start_line, .column = start_col };
            },
            '}' => {
                self.readChar();
                return Token{ .payload = .{ .rbrace = {} }, .line = start_line, .column = start_col };
            },
            '[' => {
                self.readChar();
                return Token{ .payload = .{ .lbracket = {} }, .line = start_line, .column = start_col };
            },
            ']' => {
                self.readChar();
                return Token{ .payload = .{ .rbracket = {} }, .line = start_line, .column = start_col };
            },
            ',' => {
                self.readChar();
                return Token{ .payload = .{ .comma = {} }, .line = start_line, .column = start_col };
            },
            ';' => {
                self.readChar();
                return Token{ .payload = .{ .semicolon = {} }, .line = start_line, .column = start_col };
            },
            ':' => {
                self.readChar();
                return Token{ .payload = .{ .colon = {} }, .line = start_line, .column = start_col };
            },
            else => {},
        }

        // Operators -
        if (self.ch == '=') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .equality = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .equal = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '+') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .plus_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .plus = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '-') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .minus_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .minus = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '*') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .star_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .star = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '/') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .slash_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .slash = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '%') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .mod_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .mod = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '!' and self.peekChar() == '=') {
            self.readChar();
            self.readChar();
            return Token{ .payload = .{ .inequality = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '<') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .lessthan_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .lessthan = {} }, .line = start_line, .column = start_col };
        }
        if (self.ch == '>') {
            if (self.peekChar() == '=') {
                self.readChar();
                self.readChar();
                return Token{ .payload = .{ .greaterthan_equal = {} }, .line = start_line, .column = start_col };
            }
            self.readChar();
            return Token{ .payload = .{ .greaterthan = {} }, .line = start_line, .column = start_col };
        }

        // Identifiers, Numbers etc -
        if (self.ch == '"') {
            if (self.readString()) |stringValue| {
                return Token{ .payload = .{ .string = stringValue }, .line = start_line, .column = start_col };
            }
            return Token{ .payload = .{ .invalid = "unterminated string literal" }, .line = start_line, .column = start_col }; //return the incomplete string token
        }
        if (std.ascii.isDigit(self.ch)) {
            const numberValue: i64 = self.readNumber();
            return Token{ .payload = .{ .number = numberValue }, .line = start_line, .column = start_col };
        }
        if (std.ascii.isAlphabetic(self.ch)) {
            const wordValue: []const u8 = self.readIdentifier();
            const keyword_payload = lookUpKeyword(wordValue);
            return Token{ .payload = keyword_payload, .line = start_line, .column = start_col };
        }
        if (self.ch == 0) {
            return Token{ .payload = .{ .eof = {} }, .line = start_line, .column = start_col };
        }
        const bad_char = self.input[self.position .. self.position + 1]; // slice bad btye from the input
        self.readChar();
        return Token{ .payload = .{ .invalid = bad_char }, .line = start_line, .column = start_col }; //return the bad token
    }

    pub fn lex(self: *Lexer, allocator: std.mem.Allocator) !std.ArrayList(Token) {
        var tokens: std.ArrayList(Token) = std.ArrayList(Token).empty;
        while (true) {
            const tok = self.nextToken();
            try tokens.append(allocator, tok);
            if (tok.payload == .eof) break;
        }
        // printing the lexer errors
        for (tokens.items) |tok| {
            if (tok.payload == .invalid) {
                std.debug.print("Lexer Errors at {d}:{d}: {s}\n", .{ tok.line, tok.column, tok.payload.invalid });
            }
        }
        return tokens;
    }
};
