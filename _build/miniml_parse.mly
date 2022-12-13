(*
                         CS 51 Final Project
                           MiniML -- Parser
*)
                  
%{
  open Expr ;;
%}

%token EOF
%token OPEN CLOSE
%token LET DOT IN REC
%token NEG
%token IPLUS IMINUS 
%token ITIMES
%token FPLUS FMINUS 
%token FTIMES
%token LESSTHAN EQUALS
%token IF THEN ELSE 
%token FUNCTION
%token RAISE
%token <string> ID
%token <int> INT 
%token <float> FLOAT
%token TRUE FALSE
%token AND 
%token OR

%nonassoc IF
%left LESSTHAN EQUALS
%left IPLUS IMINUS
%left ITIMES
%left FPLUS FMINUS
%left FTIMES

%nonassoc NEG

%start input
%type <Expr.expr> input

(* Grammar follows *)
%%
input:  exp EOF                 { $1 }

exp:    exp expnoapp            { App($1, $2) }
        | expnoapp              { $1 }

expnoapp: INT                   { Num $1 }
        | FLOAT                 { Float $1 }
        | TRUE                  { Bool true }
        | FALSE                 { Bool false }
        | ID                    { Var $1 }
        | exp AND exp                  { Binop(And, $1, $3)}
        | exp OR exp                  { Binop(Or, $1, $3)}
        | exp IPLUS exp          { Binop(IPlus, $1, $3) }
        | exp IMINUS exp         { Binop(IMinus, $1, $3) }
        | exp ITIMES exp         { Binop(ITimes, $1, $3) }
        | exp FPLUS exp          { Binop(FPlus, $1, $3) }
        | exp FMINUS exp         { Binop(FMinus, $1, $3) }
        | exp FTIMES exp         { Binop(FTimes, $1, $3) }
        | exp EQUALS exp        { Binop(Equals, $1, $3) }
        | exp LESSTHAN exp      { Binop(LessThan, $1, $3) }
        | NEG exp               { Unop(Negate, $2) }
        | IF exp THEN exp ELSE exp      { Conditional($2, $4, $6) }
        | LET ID EQUALS exp IN exp      { Let($2, $4, $6) }
        | LET REC ID EQUALS exp IN exp  { Letrec($3, $5, $7) }
        | FUNCTION ID DOT exp   { Fun($2, $4) } 
        | RAISE                 { Raise }
        | OPEN exp CLOSE        { $2 }
;

%%
