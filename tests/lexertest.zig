const std = @import("std");
const lexer = @import("lexer");
const Lexer = lexer.Lexer;
const Token = lexer.Token;
const TokenTag = lexer.TokenTag;
const alloc = std.testing.allocator;
test "empty file" {
    var l = Lexer.init("");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
    try std.testing.expectEqual(@as(usize, 0), tokens.items[0].column);
}
test "white spaces" {
    var l = Lexer.init("     ");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
    try std.testing.expectEqual(@as(usize, 6), tokens.items[0].column);
}
test "only tabs" {
    var l = Lexer.init("        ");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
    try std.testing.expectEqual(@as(usize, 9), tokens.items[0].column); // this thing depends on your text editor with which you write this test some insert \t when you press tab, some insert spaces result varies based on that, \t may require refactoring
}
test "only carriage returns" {
    var l = Lexer.init("\r\r\r");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
    try std.testing.expectEqual(@as(usize, 4), tokens.items[0].column);
}
test "only newlines" {
    var l = Lexer.init("\n\n\n");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 4), tokens.items[0].line);
}
test "mixed whitespace" {
    var l = Lexer.init(" \t\r\n \n\t");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 3), tokens.items[0].line);
}
test "single comment" {
    var l = Lexer.init("//testcommentshere");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .eof);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "empty comment" {
    var l = Lexer.init("//");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "multiple consecutive comments" {
    var l = Lexer.init("//testcomment\n//testagain");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 2), tokens.items[0].line);
}
test "comment followed by code" {
    var l = Lexer.init("//testcomment\nint x = 5;");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 6), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 2), tokens.items[0].line);
}
test "code followed by comment" {
    var l = Lexer.init("int x = 1;//testcomment");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 6), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "comments followed with code followed with comments" {
    var l = Lexer.init("//testcomment\nint x = 5;//testagain");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 6), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 2), tokens.items[0].line);
}
test "comment after indentation" {
    var l = Lexer.init("    //testagain");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "comment containing symbols" {
    var l = Lexer.init("//this comment will be tested with symbols like ! @ # $ % ^ & * ( ) _ - + =");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "comment containing quotes" {
    var l = Lexer.init("//\"test for quotes\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "comment containing braces" {
    var l = Lexer.init("//brace test {test}");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), tokens.items.len);
    try std.testing.expectEqual(@as(usize, 1), tokens.items[0].line);
}
test "comment between statements" {
    var l = Lexer.init("int x = 5;\n" ++ "// this is a comment\n" ++ "int y = 10;");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 11), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .type_);
    try std.testing.expect(tokens.items[1].payload == .identifier);
    try std.testing.expect(tokens.items[2].payload == .equal);
    try std.testing.expect(tokens.items[3].payload == .number);
    try std.testing.expect(tokens.items[4].payload == .semicolon);
    try std.testing.expect(tokens.items[5].payload == .type_);
    try std.testing.expectEqual(@as(usize, 3), tokens.items[5].line);
}
test "keyword int" {
    var l = Lexer.init("int");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.Int, tokens.items[0].payload.type_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword bool" {
    var l = Lexer.init("bool");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.Bool, tokens.items[0].payload.type_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword string" {
    var l = Lexer.init("string");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.String, tokens.items[0].payload.type_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword fn" {
    var l = Lexer.init("fn");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .func);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword if" {
    var l = Lexer.init("if");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .if_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword else" {
    var l = Lexer.init("else");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .else_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword while" {
    var l = Lexer.init("while");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .while_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword return" {
    var l = Lexer.init("return");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .return_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword true" {
    var l = Lexer.init("true");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .true_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "keyword false" {
    var l = Lexer.init("false");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .false_);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "all keywords together" {
    var l = Lexer.init("int bool string fn if else while return true false");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 11), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.Int, tokens.items[0].payload.type_);
    try std.testing.expect(tokens.items[1].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.Bool, tokens.items[1].payload.type_);
    try std.testing.expect(tokens.items[2].payload == .type_);
    try std.testing.expectEqual(lexer.TypeKind.String, tokens.items[2].payload.type_);
    try std.testing.expect(tokens.items[3].payload == .func);
    try std.testing.expect(tokens.items[4].payload == .if_);
    try std.testing.expect(tokens.items[5].payload == .else_);
    try std.testing.expect(tokens.items[6].payload == .while_);
    try std.testing.expect(tokens.items[7].payload == .return_);
    try std.testing.expect(tokens.items[8].payload == .true_);
    try std.testing.expect(tokens.items[9].payload == .false_);
    try std.testing.expect(tokens.items[10].payload == .eof);
}

test "single letter identifier" {
    var l = Lexer.init("x");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("x", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "multi letter identifier" {
    var l = Lexer.init("hello");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("hello", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "internal underscore identifier" {
    var l = Lexer.init("test_ident");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("test_ident", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "ending underscore identifier" {
    var l = Lexer.init("test_");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("test_", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier with digits" {
    var l = Lexer.init("hello123");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("hello123", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "long identifier" {
    var l = Lexer.init("this_is_a_really_long_identifier_name_6767");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("this_is_a_really_long_identifier_name_6767", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier after newline" {
    var l = Lexer.init("\nhello");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("hello", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier after comment" {
    var l = Lexer.init("// comment\nhellotest");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("hellotest", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier beside punctuation" {
    var l = Lexer.init("(hello)");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lparen);
    try std.testing.expect(tokens.items[1].payload == .identifier);
    try std.testing.expectEqualStrings("hello", tokens.items[1].payload.identifier);
    try std.testing.expect(tokens.items[2].payload == .rparen);
    try std.testing.expect(tokens.items[3].payload == .eof);
}

test "identifier beginning with keyword int" {
    var l = Lexer.init("integer");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("integer", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier beginning with keyword return" {
    var l = Lexer.init("returnValue");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("returnValue", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier beginning with keyword while" {
    var l = Lexer.init("whileLoop");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("whileLoop", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "identifier beginning with keyword if" {
    var l = Lexer.init("ifCondition");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("ifCondition", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "identifier beginning with keyword true" {
    var l = Lexer.init("truecondition");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("truecondition", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "identifier beginning with keyword false" {
    var l = Lexer.init("falsecondition");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("falsecondition", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "integer zero" {
    var l = Lexer.init("0");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 0), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "single digit integer" {
    var l = Lexer.init("9");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 9), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "multiple digit integer" {
    var l = Lexer.init("67");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 67), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "leading zero integer" {
    var l = Lexer.init("067");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 67), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "large integer" {
    var l = Lexer.init("123456789");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 123456789), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "integer before operator" {
    var l = Lexer.init("50+");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 3), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 50), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .plus);
    try std.testing.expect(tokens.items[2].payload == .eof);
}
test "integer after operator" {
    var l = Lexer.init("+50");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 3), tokens.items.len);
    try std.testing.expect(tokens.items[1].payload == .number);
    try std.testing.expect(tokens.items[0].payload == .plus);
    try std.testing.expectEqual(@as(i64, 50), tokens.items[1].payload.number);
    try std.testing.expect(tokens.items[2].payload == .eof);
}
test "integer before punctuation" {
    var l = Lexer.init("50,");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 3), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .number);
    try std.testing.expectEqual(@as(i64, 50), tokens.items[0].payload.number);
    try std.testing.expect(tokens.items[1].payload == .comma);
    try std.testing.expect(tokens.items[2].payload == .eof);
}
test "empty string" {
    var l = Lexer.init("\"\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 3), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_end);
    try std.testing.expect(tokens.items[2].payload == .eof);
}
test "simple string" {
    var l = Lexer.init("\"hello\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("hello", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "string with spaces" {
    var l = Lexer.init("\"    \"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("    ", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "string with punctuation" {
    var l = Lexer.init("\".,;\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings(".,;", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "string with numbers" {
    var l = Lexer.init("\"123456789\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("123456789", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "string with operators" {
    var l = Lexer.init("\"+-%*/+=-=><\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("+-%*/+=-=><", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "string with braces" {
    var l = Lexer.init("\"{}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 5), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start); // no support for string with braces in the string rn
    try std.testing.expect(tokens.items[2].payload == .interpolation_end);
    try std.testing.expect(tokens.items[3].payload == .string_end);
    try std.testing.expect(tokens.items[4].payload == .eof);
}
test "long string" {
    var l = Lexer.init("\"this string is supposed to test a long string\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 4), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("this string is supposed to test a long string", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .eof);
}
test "multiple strings" {
    var l = Lexer.init("\"multiple\" \"string\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 7), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("multiple", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .string_start);
    try std.testing.expect(tokens.items[4].payload == .string_segment);
    try std.testing.expectEqualStrings("string", tokens.items[4].payload.string_segment);
    try std.testing.expect(tokens.items[5].payload == .string_end);
    try std.testing.expect(tokens.items[6].payload == .eof);
}
test "string followed by identifier" {
    var l = Lexer.init("\"stringtest\"; ident");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 6), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("stringtest", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .string_end);
    try std.testing.expect(tokens.items[3].payload == .semicolon);
    try std.testing.expect(tokens.items[4].payload == .identifier);
    try std.testing.expect(tokens.items[5].payload == .eof);
}
test "identifier followed by string" {
    var l = Lexer.init("ident\"teststring\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 5), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .identifier);
    try std.testing.expectEqualStrings("ident", tokens.items[0].payload.identifier);
    try std.testing.expect(tokens.items[1].payload == .string_start);
    try std.testing.expect(tokens.items[2].payload == .string_segment);
    try std.testing.expect(tokens.items[3].payload == .string_end);
    try std.testing.expect(tokens.items[4].payload == .eof);
}
test "interpolation at beginning" {
    var l = Lexer.init("\"{name} hello\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 7), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .identifier);
    try std.testing.expectEqualStrings("name", tokens.items[2].payload.identifier);
    try std.testing.expect(tokens.items[3].payload == .interpolation_end);
    try std.testing.expect(tokens.items[4].payload == .string_segment);
    try std.testing.expectEqualStrings(" hello", tokens.items[4].payload.string_segment);
    try std.testing.expect(tokens.items[5].payload == .string_end);
    try std.testing.expect(tokens.items[6].payload == .eof);
}
test "interpolation in middle" {
    var l = Lexer.init("\"hello {name} world\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 8), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("hello ", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .interpolation_start);
    try std.testing.expect(tokens.items[3].payload == .identifier);
    try std.testing.expectEqualStrings("name", tokens.items[3].payload.identifier);
    try std.testing.expect(tokens.items[4].payload == .interpolation_end);
    try std.testing.expect(tokens.items[5].payload == .string_segment);
    try std.testing.expectEqualStrings(" world", tokens.items[5].payload.string_segment);
    try std.testing.expect(tokens.items[6].payload == .string_end);
    try std.testing.expect(tokens.items[7].payload == .eof);
}
test "interpolation at end" {
    var l = Lexer.init("\"hello {name}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 7), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("hello ", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .interpolation_start);
    try std.testing.expect(tokens.items[3].payload == .identifier);
    try std.testing.expectEqualStrings("name", tokens.items[3].payload.identifier);
    try std.testing.expect(tokens.items[4].payload == .interpolation_end);
    try std.testing.expect(tokens.items[5].payload == .string_end);
    try std.testing.expect(tokens.items[6].payload == .eof);
}
test "multiple interpolations" {
    var l = Lexer.init("\"{a} + {b}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .identifier);
    try std.testing.expectEqualStrings("a", tokens.items[2].payload.identifier);
    try std.testing.expect(tokens.items[3].payload == .interpolation_end);
    try std.testing.expect(tokens.items[4].payload == .string_segment);
    try std.testing.expectEqualStrings(" + ", tokens.items[4].payload.string_segment);
    try std.testing.expect(tokens.items[5].payload == .interpolation_start);
    try std.testing.expect(tokens.items[6].payload == .identifier);
    try std.testing.expectEqualStrings("b", tokens.items[6].payload.identifier);
    try std.testing.expect(tokens.items[7].payload == .interpolation_end);
    try std.testing.expect(tokens.items[8].payload == .string_end);
    try std.testing.expect(tokens.items[9].payload == .eof);
}
test "expression inside interpolation" {
    var l = Lexer.init("\"{x + y}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .identifier);
    try std.testing.expectEqualStrings("x", tokens.items[2].payload.identifier);
    try std.testing.expect(tokens.items[3].payload == .plus);
    try std.testing.expect(tokens.items[4].payload == .identifier);
    try std.testing.expectEqualStrings("y", tokens.items[4].payload.identifier);
    try std.testing.expect(tokens.items[5].payload == .interpolation_end);
    try std.testing.expect(tokens.items[6].payload == .string_end);
    try std.testing.expect(tokens.items[7].payload == .eof);
}
test "function call inside interpolation" {
    var l = Lexer.init("\"{foo(x, y)}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .identifier);
    try std.testing.expectEqualStrings("foo", tokens.items[2].payload.identifier);
    try std.testing.expect(tokens.items[3].payload == .lparen);
    try std.testing.expect(tokens.items[4].payload == .identifier);
    try std.testing.expectEqualStrings("x", tokens.items[4].payload.identifier);
    try std.testing.expect(tokens.items[5].payload == .comma);
    try std.testing.expect(tokens.items[6].payload == .identifier);
    try std.testing.expectEqualStrings("y", tokens.items[6].payload.identifier);
    try std.testing.expect(tokens.items[7].payload == .rparen);
    try std.testing.expect(tokens.items[8].payload == .interpolation_end);
    try std.testing.expect(tokens.items[9].payload == .string_end);
    try std.testing.expect(tokens.items[10].payload == .eof);
}
test "nested expression in interpolation" {
    var l = Lexer.init("\"{(a + b) * c}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .lparen);
    try std.testing.expect(tokens.items[3].payload == .identifier);
    try std.testing.expectEqualStrings("a", tokens.items[3].payload.identifier);
    try std.testing.expect(tokens.items[4].payload == .plus);
    try std.testing.expect(tokens.items[5].payload == .identifier);
    try std.testing.expectEqualStrings("b", tokens.items[5].payload.identifier);
    try std.testing.expect(tokens.items[6].payload == .rparen);
    try std.testing.expect(tokens.items[7].payload == .star);
    try std.testing.expect(tokens.items[8].payload == .identifier);
    try std.testing.expectEqualStrings("c", tokens.items[8].payload.identifier);
    try std.testing.expect(tokens.items[9].payload == .interpolation_end);
    try std.testing.expect(tokens.items[10].payload == .string_end);
    try std.testing.expect(tokens.items[11].payload == .eof);
}
test "empty interpolation" {
    var l = Lexer.init("\"{}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 5), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .interpolation_end);
    try std.testing.expect(tokens.items[3].payload == .string_end);
    try std.testing.expect(tokens.items[4].payload == .eof);
}
test "adjacent interpolations" {
    var l = Lexer.init("\"{a}{b}\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 9), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .interpolation_start);
    try std.testing.expect(tokens.items[2].payload == .identifier);
    try std.testing.expectEqualStrings("a", tokens.items[2].payload.identifier);
    try std.testing.expect(tokens.items[3].payload == .interpolation_end);
    try std.testing.expect(tokens.items[4].payload == .interpolation_start);
    try std.testing.expect(tokens.items[5].payload == .identifier);
    try std.testing.expectEqualStrings("b", tokens.items[5].payload.identifier);
    try std.testing.expect(tokens.items[6].payload == .interpolation_end);
    try std.testing.expect(tokens.items[7].payload == .string_end);
    try std.testing.expect(tokens.items[8].payload == .eof);
}
test "plus operator" {
    var l = Lexer.init("+");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .plus);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "minus operator" {
    var l = Lexer.init("-");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .minus);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "star operator" {
    var l = Lexer.init("*");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .star);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "divide operator" {
    var l = Lexer.init("/");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .slash);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "modulus operator" {
    var l = Lexer.init("%");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .mod);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "assignment operator" {
    var l = Lexer.init("=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "equality operator" {
    var l = Lexer.init("==");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .equality);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "inequality operator" {
    var l = Lexer.init("!=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .inequality);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "less than operator" {
    var l = Lexer.init("<");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lessthan);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "less than equal operator" {
    var l = Lexer.init("<=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lessthan_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "greater than operator" {
    var l = Lexer.init(">");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .greaterthan);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "greater than equal operator" {
    var l = Lexer.init(">=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .greaterthan_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "plus equal operator" {
    var l = Lexer.init("+=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .plus_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "minus equal operator" {
    var l = Lexer.init("-=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .minus_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "star equal operator" {
    var l = Lexer.init("*=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .star_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "divide equal operator" {
    var l = Lexer.init("/=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .slash_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "modulus equal operator" {
    var l = Lexer.init("%=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .mod_equal);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "all operators together" {
    var l = Lexer.init("+ - * / % = == != < <= > >= += -= *= /= %=");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 18), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .plus);
    try std.testing.expect(tokens.items[1].payload == .minus);
    try std.testing.expect(tokens.items[2].payload == .star);
    try std.testing.expect(tokens.items[3].payload == .slash);
    try std.testing.expect(tokens.items[4].payload == .mod);
    try std.testing.expect(tokens.items[5].payload == .equal);
    try std.testing.expect(tokens.items[6].payload == .equality);
    try std.testing.expect(tokens.items[7].payload == .inequality);
    try std.testing.expect(tokens.items[8].payload == .lessthan);
    try std.testing.expect(tokens.items[9].payload == .lessthan_equal);
    try std.testing.expect(tokens.items[10].payload == .greaterthan);
    try std.testing.expect(tokens.items[11].payload == .greaterthan_equal);
    try std.testing.expect(tokens.items[12].payload == .plus_equal);
    try std.testing.expect(tokens.items[13].payload == .minus_equal);
    try std.testing.expect(tokens.items[14].payload == .star_equal);
    try std.testing.expect(tokens.items[15].payload == .slash_equal);
    try std.testing.expect(tokens.items[16].payload == .mod_equal);
    try std.testing.expect(tokens.items[17].payload == .eof);
}
test "left parenthesis" {
    var l = Lexer.init("(");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lparen);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "right parenthesis" {
    var l = Lexer.init(")");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .rparen);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "left brace" {
    var l = Lexer.init("{");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lbrace);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "right brace" {
    var l = Lexer.init("}");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .rbrace);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "left bracket" {
    var l = Lexer.init("[");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lbracket);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "right bracket" {
    var l = Lexer.init("]");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .rbracket);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "comma" {
    var l = Lexer.init(",");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .comma);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "semicolon" {
    var l = Lexer.init(";");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .semicolon);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "colon" {
    var l = Lexer.init(":");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .colon);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "all punctuation together" {
    var l = Lexer.init("()}{[],;:");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 10), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .lparen);
    try std.testing.expect(tokens.items[1].payload == .rparen);
    try std.testing.expect(tokens.items[2].payload == .rbrace);
    try std.testing.expect(tokens.items[3].payload == .lbrace);
    try std.testing.expect(tokens.items[4].payload == .lbracket);
    try std.testing.expect(tokens.items[5].payload == .rbracket);
    try std.testing.expect(tokens.items[6].payload == .comma);
    try std.testing.expect(tokens.items[7].payload == .semicolon);
    try std.testing.expect(tokens.items[8].payload == .colon);
    try std.testing.expect(tokens.items[9].payload == .eof);
}
//these tests test for malformed/incorrect input soucre stream
test "leading underscore identifier" {
    var l = Lexer.init("_test");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 3), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("_", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .identifier);
    try std.testing.expectEqualStrings("test", tokens.items[1].payload.identifier);
    try std.testing.expect(tokens.items[2].payload == .eof);
}
test "unexpected character at sign" {
    var l = Lexer.init("@");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("@", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .eof);
}
test "unexpected character dollar" {
    var l = Lexer.init("$");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("$", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "unexpected character backtick" {
    var l = Lexer.init("`");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("`", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "unexpected character tilde" {
    var l = Lexer.init("~");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("~", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "unexpected character caret" {
    var l = Lexer.init("^");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 2), tokens.items.len);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("^", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .eof);
}

test "unterminated string" {
    var l = Lexer.init("\"hello");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .string_start);
    try std.testing.expect(tokens.items[1].payload == .string_segment);
    try std.testing.expectEqualStrings("hello", tokens.items[1].payload.string_segment);
    try std.testing.expect(tokens.items[2].payload == .invalid);
    try std.testing.expectEqualStrings("Unterminated string literal", tokens.items[2].payload.invalid);
}

test "unterminated interpolation" {
    var l = Lexer.init("\"Hello {name\"");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    const last = tokens.items[tokens.items.len - 2];
    try std.testing.expect(last.payload == .invalid);
    try std.testing.expectEqualStrings("Unterminated interpolation - missing }", last.payload.invalid);
}

test "invalid identifier" {
    var l = Lexer.init("_abc");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqualStrings("_", tokens.items[0].payload.invalid);
    try std.testing.expect(tokens.items[1].payload == .identifier);
    try std.testing.expectEqualStrings("abc", tokens.items[1].payload.identifier);
}

test "error location line" {
    var l = Lexer.init("\n@");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqual(@as(usize, 2), tokens.items[0].line);
}

test "error location column" {
    var l = Lexer.init("   @");
    var tokens = try l.lex(alloc);
    defer tokens.deinit(alloc);
    try std.testing.expect(tokens.items[0].payload == .invalid);
    try std.testing.expectEqual(@as(usize, 4), tokens.items[0].column);
}
