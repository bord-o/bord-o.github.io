---
theme: themes/modus-operandi.css
---

<style>
.cols { display: flex; gap: 40px; align-items: flex-start; }
.cols > * { flex: 1; min-width: 0; }
.rules { display: grid; grid-template-columns: repeat(2, 1fr); gap: 0 60px; }
.small pre, .small code { font-size: 0.78em; }
.takeaway { font-size: 1.25em; border-left: 6px solid #a60000; padding-left: 24px; }
.muted { color: #595959; }
.center { text-align: center; }
.lang-table {
  border-collapse: collapse;
  width: 100%;
}
.lang-table th,
.lang-table td {
  border: 1px solid #9f9f9f;
  padding: 6px 10px;
  text-align: left;
}
.lang-table tbody tr:nth-child(6) {
  background: #f8f0d0;
}
</style>

{#title center}
> {.center}
> # Building Heft
>
> {.center}
> ### a HOL theorem prover with special effects
>
> {.center style="margin-top: 80px"}
> Brody Little
>
> {.center style="margin-bottom: 80px"}
> [bord-o.github.io](https://bord-o.github.io/index/index.xml) · [github.com/bord-o/heft](https://github.com/bord-o/heft)

{speaker-note}
testing speaker notes

{pause up=about}
{#about}
# About me

{pause}

- Mechanical engineer from Michigan 

{pause}

- *Wait, programming is fun?* (CAD/CAE software, functional programming)

{pause}

- Software engineer, most recently at SEL


{pause up=question}
{#question}
# Why this project?

{pause}

Most software is not formally verified in any capacity. Not even close.

{pause}

- **Isabelle:** powerful, but outer syntax + Isar + inner syntax + ML, and docs not aimed at beginners

{pause}

- **Lean 4:** one language, but a sharp learning curve. A basic understanding of dependent types, universes, `Prop` vs `Bool`, elaboration, and type classes up front

{pause}

- **Either way:** there is a distinction between writing code to run it and writing code to reason about it

{pause}

{#the-question .block title="The question"}
Is the stratified, multi-language experience of HOL provers an inevitable consequence of the LCF architecture? Or can a HOL prover integrate cleanly into an existing language ecosystem?


{pause up=claim}
{#claim}
# The claim 

{pause}

{#thesis .takeaway}
HOL's usability problems are mostly **engineering** problems, not limits of the theory.

{pause}

*Heft is one experiment in that engineering.*

{pause up=background}
{#background}
# Background: HOL vs DTT

{.cols}
> {.block title="Dependent type theory"}
> > - Larger, more complex trusted base
> > - The elaborator does a lot, so errors can be opaque
> > - Need to learn a large amount of theory **up front** in order to be productive 
>
> {.block title="Higher-order logic"}
> > - Tiny kernel, simple types
> > - Close to the logic people learned in school
> > - A handful of constructs, then write functions like any FP language


{pause up=lcf}
{#lcf}
## LCF in one slide

{pause}

- `thm` is an **abstract type** and only kernel rules construct it

{pause}

- Tactics can produce multiple subgoals

{pause}

- Tactic result carries justifications: `goal -> goal list * (thm list -> thm)`

{pause}

- Three languages: **object** (the logic), **meta** (ML usually), **tactic** (the proof DSL)

{pause up=comparison}
{#comparison}
## Where the languages live

{.lang-table}
> | Prover | Logic | Object syntax | Tactics | Meta language |
> | --- | --- | --- | --- | --- |
> | HOL Light | HOL | quotations | OCaml | OCaml |
> | Isabelle/HOL | HOL on Pure | inner syntax | Isar | Isabelle/ML |
> | Rocq | CIC | Gallina | Ltac / Ltac2 | OCaml (plugins) |
> | Lean 4 | DTT | Lean | Lean | Lean |
> | *Heft* | *HOL* | *OCaml (PPX)* | *OCaml + effects* | *OCaml* |

{pause}

PPX blurs object and meta language syntactically. Effects make tactics more composable without a full DSL.


{pause up=kernel}
{#kernel}
# Design: the kernel

{pause}
A port of John Harrison's HOL Light `fusion.ml` (**596 lines**)

{style="height:20vh"}

{pause}
{carousel #kernel-rules .small change-page=~n:all style="font-size: 50px"}
> > $$\dfrac{}{\vdash t = t}\;\mathsf{refl}$$
> ---
> > $$\dfrac{}{\{p\} \vdash p}\;\mathsf{assume}$$
> ---
> > $$\dfrac{\Gamma \vdash s = t \quad \Delta \vdash t = u}{\Gamma \cup \Delta \vdash s = u}\;\mathsf{trans}$$
> ---
> > $$\dfrac{\Gamma \vdash p = q \quad \Delta \vdash p}{\Gamma \cup \Delta \vdash q}\;\mathsf{eq\_mp}$$
> ---
> > $$\dfrac{\Gamma \vdash f = g \quad \Delta \vdash x = y}{\Gamma \cup \Delta \vdash f\,x = g\,y}\;\mathsf{mk\_comb}$$
> ---
> > $$\dfrac{\Gamma \vdash s = t}{\Gamma \vdash (\lambda x.\,s) = (\lambda x.\,t)}\;\mathsf{lam}\quad x \notin \mathrm{FV}(\Gamma)$$
> ---
> > $$\dfrac{\Gamma \vdash p \quad \Delta \vdash q}{(\Gamma - \{q\}) \cup (\Delta - \{p\}) \vdash p = q}\;\mathsf{deduct\_antisym}$$
> ---
> > $$\dfrac{\Gamma \vdash p}{\Gamma[\theta] \vdash p[\theta]}\;\mathsf{inst\_type}$$
> ---
> > $$\dfrac{}{\vdash (\lambda x.\,t)\,x = t}\;\mathsf{beta}$$
> ---
> > $$\dfrac{\Gamma \vdash p}{\Gamma[t/x] \vdash p[t/x]}\;\mathsf{inst}$$

{pause}

{style="height:20vh"}

Plus about 80 derived rules and basic constructs needed to lay the ground work for tactics. I derived these differently from HOL Light in most cases, for clarity.


{pause up=trust}
{#trust}
## Trust

{pause}

{.block title="The LCF argument"}
`thm` is abstract, so no tactic or handler can forge a theorem. A buggy handler can hurt **completeness**: it can fail, loop, or pick badly. It can never hurt **soundness**.

{pause}

What is trusted at this very moment:

- The kernel
- System wide axioms: excluded middle, choice, eta
- Datatype theorems **generated at runtime** (strict positivity + base case checked), not derived as in HOL Light
- Anything calling `new_axiom` (e.g. `sorry`)


{pause up=effects-intro}
{#effects-intro}
# Design: tactics as effects

{pause}

```ocaml
type tactic = goal -> thm
```

{pause}

A tactic needing justification for a subgoal **performs** the subgoal effect, and gets back a `thm`.

**The continuation is the justification.**

{pause}

{.small}
```ocaml
type _ Effect.t +=
  | Subgoal  : goal -> thm Effect.t
  | Choose   : 'a choosable -> 'a Effect.t
  | Fail     : 'a Effect.t
  | Rules    : thm list Effect.t
  | Name     : (term * (string * term) list) -> (string * term) Effect.t
  | Trace    : (level * string) -> unit Effect.t
  | Register : tactic_info -> unit Effect.t
  | Quiet    : bool Effect.t
```

{pause up=effects-title}

{#effects-title}
## What's so special about these effects?

{carousel #effects }
> ### `Subgoal`: ask the context to prove something
>
> ```ocaml
> let rec induct : tactic = fun (asms, concl) ->
>   register ~prob:0.3 "induct" (Unsafe 8);
>   (* ... instantiate the induction theorem ... *)
>   let solved =
>     cases |> List.map (fun case ->
>       perform (Subgoal (asms, case)))   (* one per constructor *)
>   in
>   (* fold D.mp over the case theorems *)
> ```
>
> ---
>
> ### `Choose`: let the handler decide
>
> ```ocaml
> let pick (tacs : tactic list) : tactic = fun goal ->
>   let tac = choose_tactics tacs in   (* performs Choose *)
>   tac goal
>
> let with_term (t : term) : tactic_combinator = fun tac goal ->
>   match tac goal with
>   | effect Choose (Term _), k -> continue k t
>   | x -> x
> ```
>
> ---
>
> ### `Fail`: backtrack
>
> ```ocaml
> let with_first : tactic_combinator = fun tac goal ->
>   match tac goal with
>   | effect Choose choices, k ->
>       let r = Multicont.Deep.promote k in
>       let rec try_each = function
>         | [] -> fail ()
>         | c :: cs ->
>           (match Multicont.Deep.resume r c with
>            | effect Fail, k -> cleanup k; try_each cs
>            | thm -> thm)
>       in try_each (as_chosen_list choices)
>   | v -> v
> ```
>
> ---
>
> ### `Rules` and `Name`: context, not arguments
>
> ```ocaml
> let with_rules (rules : thm list) : tactic_combinator = 
>   fun tac goal ->
>     match tac goal with
>     | effect Rules, k -> continue k rules
>     | v -> v
>
> let with_names (names : string list) : tactic_combinator = 
>   fun tac goal ->
>     let queue = ref names in
>     match tac goal with
>     | effect Name (tm, asms), k ->
>         (match !queue with
>          | n :: rest -> queue := rest; continue k (n, tm)
>          | [] -> continue k (Names.name_asm tm asms))
>     | v -> v
> ```
>
> ---
>
> ### `Trace`, `Register`, `Quiet`: instrumentation
>
> - `register "induct" (Unsafe 8)`: name + cost, read by best-first search
> - `Trace`: one tracing framework shared by every tactic
> - Handlers can silence, buffer, or redirect all of it

{change-page=effects}

{change-page=effects}

{change-page=effects}

{change-page=effects}


{pause up=combinators}
{#combinators}
## Sequencing: LCF vs effects

{#hol-light-impl}
```ocaml
(* HOL Light *)
let (THEN),(THENL),then1_ =
  let propagate_empty i [] = []
  and propagate_thm th i [] = INSTANTIATE_ALL i th in
  let compose_justs n just1 just2 insts2 i ths =
    let ths1,ths2 = chop_list n ths in
    (just1 (compose_insts insts2 i) ths1)::(just2 i ths2) in
  let rec seqapply l1 l2 = match (l1,l2) with
     ([],[]) -> null_meta,[],propagate_empty
   | ((tac:tactic)::tacs),((goal:goal)::goals) ->
       let ((mvs1,insts1),gls1,just1) = tac goal in
       let goals' = map (inst_goal insts1) goals in
       let ((mvs2,insts2),gls2,just2) = seqapply tacs goals' in
       ((union mvs1 mvs2,compose_insts insts1 insts2),
        (map (inst_goal insts2) gls1)@gls2,
        compose_justs (length gls1) just1 just2 insts2)
   | _,_ -> failwith "seqapply: Length mismatch" in
  (* ... tacsequence, then_, thenl_ ... *)
```

{pause up}
{#heft-impl}
```ocaml
(* Heft *)
let then_one (tac1 : tactic) : tactic_combinator =
 fun tac goal ->
  let handled_first = ref false in
  match tac1 goal with
  | effect Subgoal g, k when not !handled_first ->
      handled_first := true;
      continue k (tac g)
  | (v : thm) -> v

let then_all (tac1 : tactic) : tactic_combinator =
 fun tac goal ->
  match tac1 goal with
  | effect Subgoal g, k -> continue k (tac g)
  | v -> v
```

{focus="hol-light-impl heft-impl"}

{unfocus}

{pause center}

Unhandled subgoals move up to the enclosing handler: **the goal list lives in the handler stack.**

{pause}

{.muted}
Fairness: HOL Light also threads metavariable instantiations. Heft has no metavariables.

{pause up=search}
{#search}
## Proof search is a handler

```ocaml
let with_dfs' : tactic_combinator = fun tac goal ->
  let rec handler f =
    match f () with
    | effect Choose choices, k ->
        let rec try_each r = function
          | [] -> fail ()
          | c :: cs ->
            (match resume r c with
             | effect Fail, k -> cleanup k; try_each r cs
             | thm -> thm)
        in
        try_each (promote k) (as_chosen_list choices)
    | effect Subgoal g, k ->
        let thm : thm = handler (fun () -> tac g) in
        handler (fun () -> continue k thm)
    | v -> v
  in
  handler (fun () -> tac goal)
```

{pause center}

- Multi-shot continuations allow reuse of continuations when trying multiple choices 
- Swap the frontier and you get BFS / best-first (`make_search`)
- Search distributes over **any** choice, including which tactic to run next

{pause}

```ocaml
let assumption_reasoning =
  with_best_first (pick [ 
    simp; simp_asm; false_elim; assumption; truth 
  ])
```


{pause up=parallel}
{#parallel}
## Parallel workers

{.small}
```ocaml
let run_tactic_in_worker (g : goal) (tac : tactic) : thm =
  match tac g with
  | effect Register _, k -> continue k ()
  | effect Rules, k -> continue k []
  | effect Trace (_, _), k -> continue k ()
  | effect Quiet, k -> continue k true
  | effect Name (tm, asms), k -> continue k (Names.name_asm tm asms)
  | effect Choose choices, k -> (* take the first *) ...
  | effect Fail, _ -> failwith "worker fail"
  | effect Subgoal _, _ -> failwith "unexpected subgoal in worker"
  | thm -> thm
```

{pause}

Effects don't cross domains, so each worker answers **every** effect itself.

{pause}

Parallelization in this manner is only useful when subsequent subgoals are cheap to enumerate compared to how much work is needed to solve them (case-bashing).


{pause up=ppx}
{#ppx}
# Design: the PPX

{pause}

- Started with a term DSL, which got annoying fast
- HOL is syntactically a subset of OCaml, so let the code **drop in**

{pause}

```ocaml
[%%inductive type nat = Zero | Suc of nat]

let%primrec plus (n : nat) (m : nat) : nat =
  match n with
  | Zero   -> m
  | Suc n' -> Suc (plus n' m)

let%thm plus_comm (x : nat) (y : nat) = 
    plus x y = plus y x
and proof = 
    begin 
        induct >>= [ 
            auto_dfs; 
            auto_dfs 
        ] 
    end
[@quiet]
```

{pause center}

`let%thm … and proof` becomes a term + a tactic + attributes passed to `run_proof`.


{pause up=demo}
{#demo}
# Demo

{pause}

1. `plus_comm`: by hand, then with `auto_dfs`

{pause}

2. `lt_implies_le`: override `induct`'s choice; search the base case; name hypotheses

{pause}

3. `lt_trans`: a one-line custom search, reused across a triple induction


{pause up=demo-backup}
{#demo-backup .small}
```ocaml
let%thm lt_implies_le (a : nat) (b : nat) = nat_lt a b ==> nat_le a b
and proof =
  begin
    with_term [%term (a : nat)] induct
    >> with_no_automation_trace auto_dfs
    >> (intros @: [ "hIH"; "hlt" ]
       >> simp
       >> with_term [%term (b : nat)] destruct_elim @: [ "hzero"; ""; "hsuc" ]
       >> (simp_asm >> false_elim)
       >> (simp_all >> apply_at "hIH" ~target:"hlt" @! "hle" >> assumption))
  end
```

{pause up=findings}
{#findings}
# Findings

{pause}

{.block title="What worked"}
Custom tactics and search in very little code. Search is general because it distributes over every choice.

{pause}

{.block title="What hurt: debugging"}
Effects are untyped. You can't see which effects a tactic performs, or enforce the invariants handlers must respect at compile time. Small handler changes caused bugs that most proofs never surfaced.

{pause}

```ocaml
let queue = ref names in   (* shared, not copied, when a continuation is resumed twice *)
```


{pause up=findings2}
{#findings2}
## Findings, continued

{pause}

{.block title="Fuel vs well-founded recursion"}
I expected fuel-based definitions to automate better. Each sufficiency proof became its own project, while well-founded recursion was general. Now I know why everyone uses it.

{pause}

{.block title="Borrowing host syntax has costs"}
`a ==> b ==> c` parses as `(a ==> b) ==> c`. OCaml fixes precedence and associativity by an operator's first character.

{pause up=limits}
{#limits}
# Limitations

- No metavariables
- Datatype theorems generated at runtime, not derived
- The PPX gives a **correspondence**, not a verified embedding, meaning proofs are about the HOL term rather than the OCaml to be executed
- Untyped effects

{pause}

{.muted}
Scale: 596-line kernel · ~5.9k lines of library · 1.9k-line PPX · ~1.5k lines of theories · ~220 `let%thm` proofs

{pause up=next}
{#next}
# Next steps

{pause}

- Typed effects 
- A more formal investigation into the rules of composition in Heft
- Derive the datatype theorems
- Desugar nested patterns in the PPX

{pause}

{.takeaway}
HOL's usability problems are mostly engineering problems. Effects are one powerful, imperfect answer.

{pause}

{.center}
# Thanks!
