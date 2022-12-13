
(* The type of tokens. *)

type token = 
  | TRUE
  | THEN
  | REC
  | RAISE
  | OR
  | OPEN
  | NEG
  | LET
  | LESSTHAN
  | ITIMES
  | IPLUS
  | INT of (int)
  | IN
  | IMINUS
  | IF
  | ID of (string)
  | FUNCTION
  | FTIMES
  | FPLUS
  | FMINUS
  | FLOAT of (float)
  | FALSE
  | EQUALS
  | EOF
  | ELSE
  | DOT
  | CLOSE
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val input: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Expr.expr)
