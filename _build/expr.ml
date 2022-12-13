(* 
                         CS 51 Final Project
                        MiniML -- Expressions
*)

(*......................................................................
  Abstract syntax of MiniML expressions 
 *)

type unop =
  | Negate
;;
    
type binop =
  | IPlus
  | IMinus
  | ITimes
  | Equals
  | LessThan
  | FPlus
  | FMinus
  | FTimes
  | Or 
  | And 
;;

type varid = string ;;
  
type expr =
  | Var of varid                         (* variables *)
  | Num of int                           (* integers *)
  | Float of float 
  | Bool of bool                         (* booleans *)
  | Unop of unop * expr                  (* unary operators *)
  | Binop of binop * expr * expr         (* binary operators *)
  | Conditional of expr * expr * expr    (* if then else *)
  | Fun of varid * expr                  (* function definitions *)
  | Let of varid * expr * expr           (* local naming *)
  | Letrec of varid * expr * expr        (* recursive local naming *)
  | Raise                                (* exceptions *)
  | Unassigned                           (* (temporarily) unassigned *)
  | App of expr * expr                   (* function applications *)
;;
  
(*......................................................................
  Manipulation of variable names (varids) and sets of them
 *)

(* varidset -- Sets of varids *)
module SS = Set.Make (struct
                       type t = varid
                       let compare = String.compare
                     end ) ;;

type varidset = SS.t ;;

(* same_vars varids1 varids2 -- Tests to see if two `varid` sets have
   the same elements (for testing purposes) *)
let same_vars : varidset -> varidset -> bool =
  SS.equal;;

(* vars_of_list varids -- Generates a set of variable names from a
   list of `varid`s (for testing purposes) *)
let vars_of_list : string list -> varidset =
  SS.of_list ;;
  
(* free_vars exp -- Returns the set of `varid`s corresponding to free
   variables in `exp` *)
let rec free_vars (exp : expr) : varidset =
  match exp with
  | Num _ | Bool _ | Float _ -> SS.empty
  | Var a -> SS.singleton a
  | Conditional (a, b, c) ->
      SS.union (SS.union (free_vars a) (free_vars b)) (free_vars c)
  | Unop (_, e1) -> free_vars e1
  | Binop (_, e1, e2) 
  | App (e1, e2) -> SS.union (free_vars e1) (free_vars e2)
  | Fun (a, b) -> SS.remove a (free_vars b)
  | Let (v, e1, e2) -> SS.union (SS.remove v (free_vars e2)) (free_vars e1)
  | Letrec (v, e1, e2) -> SS.union (SS.remove v (free_vars e2)) (free_vars e1)
  | Raise 
  | Unassigned -> SS.empty ;;
  
(* new_varname () -- Returns a freshly minted `varid` constructed with
   a running counter a la `gensym`. Assumes no variable names use the
   prefix "var". (Otherwise, they might accidentally be the same as a
   generated variable name.) *)
let new_varname () : varid =
  failwith "new_varname not implemented" ;;

(*......................................................................
  Substitution 

  Substitution of expressions for free occurrences of variables is the
  cornerstone of the substitution model for functional programming
  semantics.
 *)

(* subst var_name repl exp -- Return the expression `exp` with `repl`
   substituted for free occurrences of `var_name`, avoiding variable
   capture *)
let rec subst (var_name : varid) (repl : expr) (exp : expr) : expr =
  match exp with
  | Num _ | Bool _ | Float _ -> exp
  | Var a -> if a = var_name then repl else exp
  | Unop (op, e1) -> Unop (op, subst var_name repl e1)
  | Binop (op, e1, e2) -> Binop(op, subst var_name repl e1, 
                                subst var_name repl e2)
  | Conditional (a, b, c) ->
      Conditional(subst var_name repl a, subst var_name repl b,
        subst var_name repl c)
  | App (e1, e2) -> App(subst var_name repl e1, 
                        subst var_name repl e2)
  | Fun (a, b) ->
      if a = var_name then Fun (a, b)
      else if not (SS.mem a (free_vars repl)) then
        Fun (a, subst var_name repl b)
      else let c = new_varname () in
        Fun (c, subst var_name repl (subst a (Var c) b))
  | Let (v, e1, e2) ->
      if v = var_name then Let (v, subst v repl e1, e2)
      else if not (SS.mem v (free_vars repl)) then
        Let (v, subst var_name repl e1, subst var_name repl e2)
      else let d = new_varname () in
        Let (d, subst var_name repl e1,
                subst var_name repl (subst v (Var d) e2))
  | Letrec (v, e1, e2) ->
      if v = var_name then Letrec (v, e1, e2)
      else if not (SS.mem v (free_vars repl)) then
        Letrec (v, subst var_name repl e1, subst var_name repl e2)
      else let d = new_varname () in
        Letrec (d, subst var_name repl e1, 
                subst var_name repl (subst v (Var d) e2))
  | Raise -> Raise
  | Unassigned -> Unassigned ;;
     
(*......................................................................
  String representations of expressions
 *)

let match_abstract_binop (bin : binop) : string = 
  match bin with
  | IPlus | FPlus -> "Plus" 
  | IMinus | FMinus -> "Minus" 
  | ITimes | FTimes -> "Times"
  | LessThan -> "LessThan"
  | Equals -> "Equals"
  | Or -> "Or" 
  | And -> "And" ;;

let match_concrete_binop (bin : binop) : string = 
  match bin with
  | IPlus -> "+"
  | IMinus -> "-"
  | ITimes -> "*"
  | FPlus -> "+."
  | FMinus -> "-."
  | FTimes -> "*."
  | LessThan -> "<"
  | Equals -> "=" 
  | And -> "&&"
  | Or -> "||" ;;

(* exp_to_concrete_string exp -- Returns a string representation of
   the concrete syntax of the expression `exp` *)
let rec exp_to_concrete_string (exp : expr) : string =
  match exp with 
  | Var a -> a
  | Num a ->  string_of_int a
  | Float a -> string_of_float a
  | Bool a -> string_of_bool a
  | Unop (_, e1) -> "~-" ^ (exp_to_concrete_string e1)
  | Binop (op, e1, e2) -> 
      (exp_to_concrete_string e1) ^ " " ^ 
      (match_concrete_binop op) ^
      " " ^ (exp_to_concrete_string e2)
  | Conditional (a, b, c) -> 
      "if " ^ (exp_to_concrete_string a) ^ 
      " then " ^ (exp_to_concrete_string b) ^ 
      " else " ^ (exp_to_concrete_string c)
  | Fun (a, b) -> "fun " ^ a ^ " -> " ^ exp_to_concrete_string b
  | App (e1, e2) -> (exp_to_concrete_string e1) ^ 
                    " " ^ (exp_to_concrete_string e2)
  | Let (v, e1, e2) -> "let " ^ v ^ " = " ^ 
                       (exp_to_concrete_string e1) ^ 
                       " in " ^ (exp_to_concrete_string e2)
  | Letrec (v, e1, e2) -> "let rec " ^ v ^ " = " ^ 
                          (exp_to_concrete_string e1) ^ 
                          " in " ^ (exp_to_concrete_string e2)
  | Raise -> "Raise " 
  | Unassigned -> "Unassigned" ;;
     
(* exp_to_abstract_string exp -- Return a string representation of the
   abstract syntax of the expression `exp` *)
let rec exp_to_abstract_string (exp : expr) : string =
  match exp with
  | Var a -> "Var(" ^ a ^ ")"
  | Num a -> "Num(" ^ (string_of_int a) ^ ")"
  | Float a -> "Float(" ^ (string_of_float a) ^ ")"
  | Bool a -> "Bool(" ^ (string_of_bool a) ^ ")"
  | Unop (_, e1) -> 
      "Unop(" ^ "Negate" ^ ", " ^ (exp_to_abstract_string e1) ^ ")"
  | Binop (op, e1, e2) ->
      "Binop(" ^ (match_abstract_binop op) ^ ", " 
      ^ (exp_to_abstract_string e1) ^ ", " ^ (exp_to_abstract_string e2) ^ ")"
  | Conditional (a, b, c) ->
      "Conditional(" ^ (exp_to_abstract_string a) ^ ", " ^
      (exp_to_abstract_string b) ^ ", " ^ (exp_to_abstract_string c) ^ ")"
  | Fun (a, b) -> "Fun(" ^ a ^ ", " ^ (exp_to_abstract_string b) ^ ")"
  | App (e1, e2) -> 
      "App(" ^ (exp_to_abstract_string e1) ^ ", " 
      ^ (exp_to_abstract_string e2) ^ ")"
  | Let (v, e1, e2) ->
      "Let(" ^ v ^ ", " ^ (exp_to_abstract_string e1) ^ ", " 
      ^ (exp_to_abstract_string e2) ^ ")"
  | Letrec (v, e1, e2) ->
      "Letrec(" ^ v ^ ", " ^ (exp_to_abstract_string e1) ^ ", " 
      ^ (exp_to_abstract_string e2) ^ ")"
  | Raise -> "Raise "
  | Unassigned -> "Unassigned" ;; 
