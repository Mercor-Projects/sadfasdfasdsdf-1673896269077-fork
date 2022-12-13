open Expr ;; 
open Evaluation ;; 
open Test_simple ;; 
open Env ;; 


let free_vars_tests () = 
    let a, b, c = "a", "b", "c" in 
    let exp1 = Binop (ITimes, Var a, Var b) in 
    let exp2 = Conditional (Var a, Var b, Var c) in 
    let exp3 = Binop (IPlus, Num 150, Num 2) in 
    let exp4 = Let(a, Bool(false), Binop(Or, Var(a), Bool(true))) in 
    unit_test (free_vars exp1 = vars_of_list ["a"; "b"]) 
              "free vars multiplication test" ; 
    unit_test (free_vars exp2 = vars_of_list ["a"; "b"; "c"]) 
              "free vars conditional test" ; 
    unit_test (free_vars exp3 = vars_of_list []) 
              "free vars IPlus blank test" ; 
    unit_test (free_vars exp4 = vars_of_list []) 
              "free vars complicated let blank test" 

let concrete_abstract_string_tests () = 
    let a, b, c  = "a", "b", "c" in 
    let exp1 = Conditional (Var a, Var b, Var c) in 
    let exp2 = Float (3.) in
    let exp3 = Num (3) in 
    let exp4 = Let(a, Bool(false), Binop(Or, Var(a), Bool(true))) in
    unit_test (exp_to_concrete_string exp1 = "if a then b else c") 
              "concrete conditional";
    unit_test (exp_to_abstract_string exp1 = 
              "Conditional(Var(a), Var(b), Var(c))") 
              "abstract conditional" ; 
    unit_test (exp_to_concrete_string exp2 = "3.")
              "concrete float" ; 
    unit_test (exp_to_abstract_string exp2 = "Float(3.)")
              "abstract float" ; 
    unit_test (exp_to_concrete_string exp3 = "3")
                "concrete num" ;
    unit_test (exp_to_abstract_string exp3 = "Num(3)")
                "abstract num" ;
    unit_test (exp_to_concrete_string exp4 = "let a = false in a || true")
                "abstract combined" ;
    unit_test (exp_to_abstract_string exp4 = "Let(a, Bool(false), Binop(Or, Var(a), Bool(true)))")
                "concrete combined" 

let eval_d_l_env_tests () =
    let open Env in 
    let x, y, z  = "x", "y", "z" in 
    let ref1, ref2, ref3 = ref (Val (Float 70.)), 
                                 ref (Val (Float 69.)), 
                                 ref (Val (Bool (false))) in
    let empty_env = empty () in 
    let env1 = (extend (empty_env) x ref1) in
    let env2 = (extend (env1) y ref2) in 
    let env3 = (extend (env1) z ref3) in 
    print_endline ("Environment 2: " ^ env_to_string env2);
    let exp1 = Binop (FMinus, Var x, Var y) in 
    let exp2 = Binop (FTimes, Var x, Var y) in
    let exp3 = Binop (And, Var z, Var z) in
    let exp4 = Binop (Or, Var z, Var z) in
    unit_test (eval_l exp2 env2 = Val (Float(4830.)))
               "multiplying two floats env test eval_d" ; 
    unit_test (eval_d exp1 env2 = Val (Float(1.)))
               "subtracting two floats env test eval_d" ; 
    unit_test (eval_l exp3 env3 = Val (Bool (false)))
               "And two booleans env test eval_d" ; 
    unit_test (eval_d exp4 env3 = Val (Bool(false)))
               "subtracting two floats env test eval_d"

let eval_s_tests ()  = 
    let x = "x" in
    let empty_env = Env.empty () in 
    let exp1 = Binop (IPlus, Num 150, Num 2) in 
    unit_test (eval_d exp1 empty_env = Val (Num 152)) 
              "add two ints eval_s";
    let exp2 = Conditional (Bool true, Binop (ITimes, Num 10, 
                            Unop (Negate, Num 10)), Num 5) in  
    unit_test (eval_d exp2 empty_env = Val (Num ~-100)) 
              "conditionals testing";
    let exp3 = Let (x, Num 10, Var x) in  
    unit_test (eval_d exp3 empty_env = Val (Num 10)) 
              "let testing";
    let exp5 = Let(x, Bool(false), Binop(Or, Var(x), Bool(true))) in 
        unit_test (eval_s exp5 empty_env = Val (Bool true)) 
                   "Or testing";
    let exp6 = Let(x, Bool(true), Binop(And, Var(x), Bool(true))) in 
        unit_test (eval_s exp6 empty_env = Val (Bool true)) 
                   "And testing"

let run_tests () = free_vars_tests () ; concrete_abstract_string_tests () ; eval_s_tests () ; 
                   eval_d_l_env_tests () ; () ;; 

let _ = run_tests () ;; 