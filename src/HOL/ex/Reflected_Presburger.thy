theory Reflected_Presburger
imports GCD Main EfficientNat
uses ("coopereif.ML") ("coopertac.ML")
begin

lemma allpairs_set: "set (allpairs Pair xs ys) = {(x,y). x\<in> set xs \<and> y \<in> set ys}"
by (induct xs) auto


  (* generate a list from i to j*)
consts iupt :: "int \<times> int \<Rightarrow> int list"
recdef iupt "measure (\<lambda> (i,j). nat (j-i +1))" 
  "iupt (i,j) = (if j <i then [] else (i# iupt(i+1, j)))"

lemma iupt_set: "set (iupt(i,j)) = {i .. j}"
proof(induct rule: iupt.induct)
  case (1 a b)
  show ?case
    using prems by (simp add: simp_from_to)
qed

lemma nth_pos2: "0 < n \<Longrightarrow> (x#xs) ! n = xs ! (n - 1)"
using Nat.gr0_conv_Suc
by clarsimp


lemma myl: "\<forall> (a::'a::{pordered_ab_group_add}) (b::'a). (a \<le> b) = (0 \<le> b - a)" 
proof(clarify)
  fix x y ::"'a"
  have "(x \<le> y) = (x - y \<le> 0)" by (simp only: le_iff_diff_le_0[where a="x" and b="y"])
  also have "\<dots> = (- (y - x) \<le> 0)" by simp
  also have "\<dots> = (0 \<le> y - x)" by (simp only: neg_le_0_iff_le[where a="y-x"])
  finally show "(x \<le> y) = (0 \<le> y - x)" .
qed

lemma myless: "\<forall> (a::'a::{pordered_ab_group_add}) (b::'a). (a < b) = (0 < b - a)" 
proof(clarify)
  fix x y ::"'a"
  have "(x < y) = (x - y < 0)" by (simp only: less_iff_diff_less_0[where a="x" and b="y"])
  also have "\<dots> = (- (y - x) < 0)" by simp
  also have "\<dots> = (0 < y - x)" by (simp only: neg_less_0_iff_less[where a="y-x"])
  finally show "(x < y) = (0 < y - x)" .
qed

lemma myeq: "\<forall> (a::'a::{pordered_ab_group_add}) (b::'a). (a = b) = (0 = b - a)"
  by auto

(* Periodicity of dvd *)

lemma dvd_period:
  assumes advdd: "(a::int) dvd d"
  shows "(a dvd (x + t)) = (a dvd ((x+ c*d) + t))"
  using advdd  
proof-
  {fix x k
    from inf_period(3)[OF advdd, rule_format, where x=x and k="-k"]  
    have " ((a::int) dvd (x + t)) = (a dvd (x+k*d + t))" by simp}
  hence "\<forall>x.\<forall>k. ((a::int) dvd (x + t)) = (a dvd (x+k*d + t))"  by simp
  then show ?thesis by simp
qed

  (*********************************************************************************)
  (****                            SHADOW SYNTAX AND SEMANTICS                  ****)
  (*********************************************************************************)

datatype num = C int | Bound nat | CX int num | Neg num | Add num num| Sub num num 
  | Mul int num

  (* A size for num to make inductive proofs simpler*)
consts num_size :: "num \<Rightarrow> nat" 
primrec 
  "num_size (C c) = 1"
  "num_size (Bound n) = 1"
  "num_size (Neg a) = 1 + num_size a"
  "num_size (Add a b) = 1 + num_size a + num_size b"
  "num_size (Sub a b) = 3 + num_size a + num_size b"
  "num_size (CX c a) = 4 + num_size a"
  "num_size (Mul c a) = 1 + num_size a"

consts Inum :: "int list \<Rightarrow> num \<Rightarrow> int"
primrec
  "Inum bs (C c) = c"
  "Inum bs (Bound n) = bs!n"
  "Inum bs (CX c a) = c * (bs!0) + (Inum bs a)"
  "Inum bs (Neg a) = -(Inum bs a)"
  "Inum bs (Add a b) = Inum bs a + Inum bs b"
  "Inum bs (Sub a b) = Inum bs a - Inum bs b"
  "Inum bs (Mul c a) = c* Inum bs a"

datatype fm  = 
  T| F| Lt num| Le num| Gt num| Ge num| Eq num| NEq num| Dvd int num| NDvd int num|
  NOT fm| And fm fm|  Or fm fm| Imp fm fm| Iff fm fm| E fm| A fm 
  | Closed nat | NClosed nat


  (* A size for fm *)
consts fmsize :: "fm \<Rightarrow> nat"
recdef fmsize "measure size"
  "fmsize (NOT p) = 1 + fmsize p"
  "fmsize (And p q) = 1 + fmsize p + fmsize q"
  "fmsize (Or p q) = 1 + fmsize p + fmsize q"
  "fmsize (Imp p q) = 3 + fmsize p + fmsize q"
  "fmsize (Iff p q) = 3 + 2*(fmsize p + fmsize q)"
  "fmsize (E p) = 1 + fmsize p"
  "fmsize (A p) = 4+ fmsize p"
  "fmsize (Dvd i t) = 2"
  "fmsize (NDvd i t) = 2"
  "fmsize p = 1"
  (* several lemmas about fmsize *)
lemma fmsize_pos: "fmsize p > 0"	
by (induct p rule: fmsize.induct) simp_all

  (* Semantics of formulae (fm) *)
consts Ifm ::"bool list \<Rightarrow> int list \<Rightarrow> fm \<Rightarrow> bool"
primrec
  "Ifm bbs bs T = True"
  "Ifm bbs bs F = False"
  "Ifm bbs bs (Lt a) = (Inum bs a < 0)"
  "Ifm bbs bs (Gt a) = (Inum bs a > 0)"
  "Ifm bbs bs (Le a) = (Inum bs a \<le> 0)"
  "Ifm bbs bs (Ge a) = (Inum bs a \<ge> 0)"
  "Ifm bbs bs (Eq a) = (Inum bs a = 0)"
  "Ifm bbs bs (NEq a) = (Inum bs a \<noteq> 0)"
  "Ifm bbs bs (Dvd i b) = (i dvd Inum bs b)"
  "Ifm bbs bs (NDvd i b) = (\<not>(i dvd Inum bs b))"
  "Ifm bbs bs (NOT p) = (\<not> (Ifm bbs bs p))"
  "Ifm bbs bs (And p q) = (Ifm bbs bs p \<and> Ifm bbs bs q)"
  "Ifm bbs bs (Or p q) = (Ifm bbs bs p \<or> Ifm bbs bs q)"
  "Ifm bbs bs (Imp p q) = ((Ifm bbs bs p) \<longrightarrow> (Ifm bbs bs q))"
  "Ifm bbs bs (Iff p q) = (Ifm bbs bs p = Ifm bbs bs q)"
  "Ifm bbs bs (E p) = (\<exists> x. Ifm bbs (x#bs) p)"
  "Ifm bbs bs (A p) = (\<forall> x. Ifm bbs (x#bs) p)"
  "Ifm bbs bs (Closed n) = bbs!n"
  "Ifm bbs bs (NClosed n) = (\<not> bbs!n)"

lemma "Ifm bbs [] (A(Imp (Gt (Sub (Bound 0) (C 8))) (E(E(Eq(Sub(Add (Mul 3 (Bound 0)) (Mul 5 (Bound 1))) (Bound 2))))))) = P"
apply simp
oops

consts prep :: "fm \<Rightarrow> fm"
recdef prep "measure fmsize"
  "prep (E T) = T"
  "prep (E F) = F"
  "prep (E (Or p q)) = Or (prep (E p)) (prep (E q))"
  "prep (E (Imp p q)) = Or (prep (E (NOT p))) (prep (E q))"
  "prep (E (Iff p q)) = Or (prep (E (And p q))) (prep (E (And (NOT p) (NOT q))))" 
  "prep (E (NOT (And p q))) = Or (prep (E (NOT p))) (prep (E(NOT q)))"
  "prep (E (NOT (Imp p q))) = prep (E (And p (NOT q)))"
  "prep (E (NOT (Iff p q))) = Or (prep (E (And p (NOT q)))) (prep (E(And (NOT p) q)))"
  "prep (E p) = E (prep p)"
  "prep (A (And p q)) = And (prep (A p)) (prep (A q))"
  "prep (A p) = prep (NOT (E (NOT p)))"
  "prep (NOT (NOT p)) = prep p"
  "prep (NOT (And p q)) = Or (prep (NOT p)) (prep (NOT q))"
  "prep (NOT (A p)) = prep (E (NOT p))"
  "prep (NOT (Or p q)) = And (prep (NOT p)) (prep (NOT q))"
  "prep (NOT (Imp p q)) = And (prep p) (prep (NOT q))"
  "prep (NOT (Iff p q)) = Or (prep (And p (NOT q))) (prep (And (NOT p) q))"
  "prep (NOT p) = NOT (prep p)"
  "prep (Or p q) = Or (prep p) (prep q)"
  "prep (And p q) = And (prep p) (prep q)"
  "prep (Imp p q) = prep (Or (NOT p) q)"
  "prep (Iff p q) = Or (prep (And p q)) (prep (And (NOT p) (NOT q)))"
  "prep p = p"
(hints simp add: fmsize_pos)
lemma prep: "Ifm bbs bs (prep p) = Ifm bbs bs p"
by (induct p arbitrary: bs rule: prep.induct, auto)


  (* Quantifier freeness *)
consts qfree:: "fm \<Rightarrow> bool"
recdef qfree "measure size"
  "qfree (E p) = False"
  "qfree (A p) = False"
  "qfree (NOT p) = qfree p" 
  "qfree (And p q) = (qfree p \<and> qfree q)" 
  "qfree (Or  p q) = (qfree p \<and> qfree q)" 
  "qfree (Imp p q) = (qfree p \<and> qfree q)" 
  "qfree (Iff p q) = (qfree p \<and> qfree q)"
  "qfree p = True"

  (* Boundedness and substitution *)
consts 
  numbound0:: "num \<Rightarrow> bool" (* a num is INDEPENDENT of Bound 0 *)
  bound0:: "fm \<Rightarrow> bool" (* A Formula is independent of Bound 0 *)
  numsubst0:: "num \<Rightarrow> num \<Rightarrow> num" (* substitute a num into a num for Bound 0 *)
  subst0:: "num \<Rightarrow> fm \<Rightarrow> fm" (* substitue a num into a formula for Bound 0 *)
primrec
  "numbound0 (C c) = True"
  "numbound0 (Bound n) = (n>0)"
  "numbound0 (CX i a) = False"
  "numbound0 (Neg a) = numbound0 a"
  "numbound0 (Add a b) = (numbound0 a \<and> numbound0 b)"
  "numbound0 (Sub a b) = (numbound0 a \<and> numbound0 b)" 
  "numbound0 (Mul i a) = numbound0 a"

lemma numbound0_I:
  assumes nb: "numbound0 a"
  shows "Inum (b#bs) a = Inum (b'#bs) a"
using nb
by (induct a rule: numbound0.induct) (auto simp add: nth_pos2)

primrec
  "bound0 T = True"
  "bound0 F = True"
  "bound0 (Lt a) = numbound0 a"
  "bound0 (Le a) = numbound0 a"
  "bound0 (Gt a) = numbound0 a"
  "bound0 (Ge a) = numbound0 a"
  "bound0 (Eq a) = numbound0 a"
  "bound0 (NEq a) = numbound0 a"
  "bound0 (Dvd i a) = numbound0 a"
  "bound0 (NDvd i a) = numbound0 a"
  "bound0 (NOT p) = bound0 p"
  "bound0 (And p q) = (bound0 p \<and> bound0 q)"
  "bound0 (Or p q) = (bound0 p \<and> bound0 q)"
  "bound0 (Imp p q) = ((bound0 p) \<and> (bound0 q))"
  "bound0 (Iff p q) = (bound0 p \<and> bound0 q)"
  "bound0 (E p) = False"
  "bound0 (A p) = False"
  "bound0 (Closed P) = True"
  "bound0 (NClosed P) = True"
lemma bound0_I:
  assumes bp: "bound0 p"
  shows "Ifm bbs (b#bs) p = Ifm bbs (b'#bs) p"
using bp numbound0_I[where b="b" and bs="bs" and b'="b'"]
by (induct p rule: bound0.induct) (auto simp add: nth_pos2)

primrec
  "numsubst0 t (C c) = (C c)"
  "numsubst0 t (Bound n) = (if n=0 then t else Bound n)"
  "numsubst0 t (CX i a) = Add (Mul i t) (numsubst0 t a)"
  "numsubst0 t (Neg a) = Neg (numsubst0 t a)"
  "numsubst0 t (Add a b) = Add (numsubst0 t a) (numsubst0 t b)"
  "numsubst0 t (Sub a b) = Sub (numsubst0 t a) (numsubst0 t b)" 
  "numsubst0 t (Mul i a) = Mul i (numsubst0 t a)"

lemma numsubst0_I:
  shows "Inum (b#bs) (numsubst0 a t) = Inum ((Inum (b#bs) a)#bs) t"
  by (induct t) (simp_all add: nth_pos2)

lemma numsubst0_I':
  assumes nb: "numbound0 a"
  shows "Inum (b#bs) (numsubst0 a t) = Inum ((Inum (b'#bs) a)#bs) t"
  by (induct t) (simp_all add: nth_pos2 numbound0_I[OF nb, where b="b" and b'="b'"])


primrec
  "subst0 t T = T"
  "subst0 t F = F"
  "subst0 t (Lt a) = Lt (numsubst0 t a)"
  "subst0 t (Le a) = Le (numsubst0 t a)"
  "subst0 t (Gt a) = Gt (numsubst0 t a)"
  "subst0 t (Ge a) = Ge (numsubst0 t a)"
  "subst0 t (Eq a) = Eq (numsubst0 t a)"
  "subst0 t (NEq a) = NEq (numsubst0 t a)"
  "subst0 t (Dvd i a) = Dvd i (numsubst0 t a)"
  "subst0 t (NDvd i a) = NDvd i (numsubst0 t a)"
  "subst0 t (NOT p) = NOT (subst0 t p)"
  "subst0 t (And p q) = And (subst0 t p) (subst0 t q)"
  "subst0 t (Or p q) = Or (subst0 t p) (subst0 t q)"
  "subst0 t (Imp p q) = Imp (subst0 t p) (subst0 t q)"
  "subst0 t (Iff p q) = Iff (subst0 t p) (subst0 t q)"
  "subst0 t (Closed P) = (Closed P)"
  "subst0 t (NClosed P) = (NClosed P)"

lemma subst0_I: assumes qfp: "qfree p"
  shows "Ifm bbs (b#bs) (subst0 a p) = Ifm bbs ((Inum (b#bs) a)#bs) p"
  using qfp numsubst0_I[where b="b" and bs="bs" and a="a"]
  by (induct p) (simp_all add: nth_pos2 )


consts 
  decrnum:: "num \<Rightarrow> num" 
  decr :: "fm \<Rightarrow> fm"

recdef decrnum "measure size"
  "decrnum (Bound n) = Bound (n - 1)"
  "decrnum (Neg a) = Neg (decrnum a)"
  "decrnum (Add a b) = Add (decrnum a) (decrnum b)"
  "decrnum (Sub a b) = Sub (decrnum a) (decrnum b)"
  "decrnum (Mul c a) = Mul c (decrnum a)"
  "decrnum a = a"

recdef decr "measure size"
  "decr (Lt a) = Lt (decrnum a)"
  "decr (Le a) = Le (decrnum a)"
  "decr (Gt a) = Gt (decrnum a)"
  "decr (Ge a) = Ge (decrnum a)"
  "decr (Eq a) = Eq (decrnum a)"
  "decr (NEq a) = NEq (decrnum a)"
  "decr (Dvd i a) = Dvd i (decrnum a)"
  "decr (NDvd i a) = NDvd i (decrnum a)"
  "decr (NOT p) = NOT (decr p)" 
  "decr (And p q) = And (decr p) (decr q)"
  "decr (Or p q) = Or (decr p) (decr q)"
  "decr (Imp p q) = Imp (decr p) (decr q)"
  "decr (Iff p q) = Iff (decr p) (decr q)"
  "decr p = p"

lemma decrnum: assumes nb: "numbound0 t"
  shows "Inum (x#bs) t = Inum bs (decrnum t)"
  using nb by (induct t rule: decrnum.induct, simp_all add: nth_pos2)

lemma decr: assumes nb: "bound0 p"
  shows "Ifm bbs (x#bs) p = Ifm bbs bs (decr p)"
  using nb 
  by (induct p rule: decr.induct, simp_all add: nth_pos2 decrnum)

lemma decr_qf: "bound0 p \<Longrightarrow> qfree (decr p)"
by (induct p, simp_all)

consts 
  isatom :: "fm \<Rightarrow> bool" (* test for atomicity *)
recdef isatom "measure size"
  "isatom T = True"
  "isatom F = True"
  "isatom (Lt a) = True"
  "isatom (Le a) = True"
  "isatom (Gt a) = True"
  "isatom (Ge a) = True"
  "isatom (Eq a) = True"
  "isatom (NEq a) = True"
  "isatom (Dvd i b) = True"
  "isatom (NDvd i b) = True"
  "isatom (Closed P) = True"
  "isatom (NClosed P) = True"
  "isatom p = False"

lemma numsubst0_numbound0: assumes nb: "numbound0 t"
  shows "numbound0 (numsubst0 t a)"
using nb by (induct a rule: numsubst0.induct, auto)

lemma subst0_bound0: assumes qf: "qfree p" and nb: "numbound0 t"
  shows "bound0 (subst0 t p)"
using qf numsubst0_numbound0[OF nb] by (induct p  rule: subst0.induct, auto)

lemma bound0_qf: "bound0 p \<Longrightarrow> qfree p"
by (induct p, simp_all)


constdefs djf:: "('a \<Rightarrow> fm) \<Rightarrow> 'a \<Rightarrow> fm \<Rightarrow> fm"
  "djf f p q \<equiv> (if q=T then T else if q=F then f p else 
  (let fp = f p in case fp of T \<Rightarrow> T | F \<Rightarrow> q | _ \<Rightarrow> Or (f p) q))"
constdefs evaldjf:: "('a \<Rightarrow> fm) \<Rightarrow> 'a list \<Rightarrow> fm"
  "evaldjf f ps \<equiv> foldr (djf f) ps F"

lemma djf_Or: "Ifm bbs bs (djf f p q) = Ifm bbs bs (Or (f p) q)"
by (cases "q=T", simp add: djf_def,cases "q=F",simp add: djf_def) 
(cases "f p", simp_all add: Let_def djf_def) 

lemma evaldjf_ex: "Ifm bbs bs (evaldjf f ps) = (\<exists> p \<in> set ps. Ifm bbs bs (f p))"
  by(induct ps, simp_all add: evaldjf_def djf_Or)

lemma evaldjf_bound0: 
  assumes nb: "\<forall> x\<in> set xs. bound0 (f x)"
  shows "bound0 (evaldjf f xs)"
  using nb by (induct xs, auto simp add: evaldjf_def djf_def Let_def) (case_tac "f a", auto) 

lemma evaldjf_qf: 
  assumes nb: "\<forall> x\<in> set xs. qfree (f x)"
  shows "qfree (evaldjf f xs)"
  using nb by (induct xs, auto simp add: evaldjf_def djf_def Let_def) (case_tac "f a", auto) 

consts disjuncts :: "fm \<Rightarrow> fm list"
recdef disjuncts "measure size"
  "disjuncts (Or p q) = (disjuncts p) @ (disjuncts q)"
  "disjuncts F = []"
  "disjuncts p = [p]"

lemma disjuncts: "(\<exists> q\<in> set (disjuncts p). Ifm bbs bs q) = Ifm bbs bs p"
by(induct p rule: disjuncts.induct, auto)

lemma disjuncts_nb: "bound0 p \<Longrightarrow> \<forall> q\<in> set (disjuncts p). bound0 q"
proof-
  assume nb: "bound0 p"
  hence "list_all bound0 (disjuncts p)" by (induct p rule:disjuncts.induct,auto)
  thus ?thesis by (simp only: list_all_iff)
qed

lemma disjuncts_qf: "qfree p \<Longrightarrow> \<forall> q\<in> set (disjuncts p). qfree q"
proof-
  assume qf: "qfree p"
  hence "list_all qfree (disjuncts p)"
    by (induct p rule: disjuncts.induct, auto)
  thus ?thesis by (simp only: list_all_iff)
qed

constdefs DJ :: "(fm \<Rightarrow> fm) \<Rightarrow> fm \<Rightarrow> fm"
  "DJ f p \<equiv> evaldjf f (disjuncts p)"

lemma DJ: assumes fdj: "\<forall> p q. f (Or p q) = Or (f p) (f q)"
  and fF: "f F = F"
  shows "Ifm bbs bs (DJ f p) = Ifm bbs bs (f p)"
proof-
  have "Ifm bbs bs (DJ f p) = (\<exists> q \<in> set (disjuncts p). Ifm bbs bs (f q))"
    by (simp add: DJ_def evaldjf_ex) 
  also have "\<dots> = Ifm bbs bs (f p)" using fdj fF by (induct p rule: disjuncts.induct, auto)
  finally show ?thesis .
qed

lemma DJ_qf: assumes 
  fqf: "\<forall> p. qfree p \<longrightarrow> qfree (f p)"
  shows "\<forall>p. qfree p \<longrightarrow> qfree (DJ f p) "
proof(clarify)
  fix  p assume qf: "qfree p"
  have th: "DJ f p = evaldjf f (disjuncts p)" by (simp add: DJ_def)
  from disjuncts_qf[OF qf] have "\<forall> q\<in> set (disjuncts p). qfree q" .
  with fqf have th':"\<forall> q\<in> set (disjuncts p). qfree (f q)" by blast
  
  from evaldjf_qf[OF th'] th show "qfree (DJ f p)" by simp
qed

lemma DJ_qe: assumes qe: "\<forall> bs p. qfree p \<longrightarrow> qfree (qe p) \<and> (Ifm bbs bs (qe p) = Ifm bbs bs (E p))"
  shows "\<forall> bs p. qfree p \<longrightarrow> qfree (DJ qe p) \<and> (Ifm bbs bs ((DJ qe p)) = Ifm bbs bs (E p))"
proof(clarify)
  fix p::fm and bs
  assume qf: "qfree p"
  from qe have qth: "\<forall> p. qfree p \<longrightarrow> qfree (qe p)" by blast
  from DJ_qf[OF qth] qf have qfth:"qfree (DJ qe p)" by auto
  have "Ifm bbs bs (DJ qe p) = (\<exists> q\<in> set (disjuncts p). Ifm bbs bs (qe q))"
    by (simp add: DJ_def evaldjf_ex)
  also have "\<dots> = (\<exists> q \<in> set(disjuncts p). Ifm bbs bs (E q))" using qe disjuncts_qf[OF qf] by auto
  also have "\<dots> = Ifm bbs bs (E p)" by (induct p rule: disjuncts.induct, auto)
  finally show "qfree (DJ qe p) \<and> Ifm bbs bs (DJ qe p) = Ifm bbs bs (E p)" using qfth by blast
qed
  (* Simplification *)

  (* Algebraic simplifications for nums *)
consts bnds:: "num \<Rightarrow> nat list"
  lex_ns:: "nat list \<times> nat list \<Rightarrow> bool"
recdef bnds "measure size"
  "bnds (Bound n) = [n]"
  "bnds (CX c a) = 0#(bnds a)"
  "bnds (Neg a) = bnds a"
  "bnds (Add a b) = (bnds a)@(bnds b)"
  "bnds (Sub a b) = (bnds a)@(bnds b)"
  "bnds (Mul i a) = bnds a"
  "bnds a = []"
recdef lex_ns "measure (\<lambda> (xs,ys). length xs + length ys)"
  "lex_ns ([], ms) = True"
  "lex_ns (ns, []) = False"
  "lex_ns (n#ns, m#ms) = (n<m \<or> ((n = m) \<and> lex_ns (ns,ms))) "
constdefs lex_bnd :: "num \<Rightarrow> num \<Rightarrow> bool"
  "lex_bnd t s \<equiv> lex_ns (bnds t, bnds s)"

consts simpnum:: "num \<Rightarrow> num"
  numadd:: "num \<times> num \<Rightarrow> num"
  nummul:: "num \<Rightarrow> int \<Rightarrow> num"
  numfloor:: "num \<Rightarrow> num"
recdef numadd "measure (\<lambda> (t,s). size t + size s)"
  "numadd (Add (Mul c1 (Bound n1)) r1,Add (Mul c2 (Bound n2)) r2) =
  (if n1=n2 then 
  (let c = c1 + c2
  in (if c=0 then numadd(r1,r2) else Add (Mul c (Bound n1)) (numadd (r1,r2))))
  else if n1 \<le> n2 then (Add (Mul c1 (Bound n1)) (numadd (r1,Add (Mul c2 (Bound n2)) r2))) 
  else (Add (Mul c2 (Bound n2)) (numadd (Add (Mul c1 (Bound n1)) r1,r2))))"
  "numadd (Add (Mul c1 (Bound n1)) r1,t) = Add (Mul c1 (Bound n1)) (numadd (r1, t))"  
  "numadd (t,Add (Mul c2 (Bound n2)) r2) = Add (Mul c2 (Bound n2)) (numadd (t,r2))" 
  "numadd (C b1, C b2) = C (b1+b2)"
  "numadd (a,b) = Add a b"

lemma numadd: "Inum bs (numadd (t,s)) = Inum bs (Add t s)"
apply (induct t s rule: numadd.induct, simp_all add: Let_def)
apply (case_tac "c1+c2 = 0",case_tac "n1 \<le> n2", simp_all)
 apply (case_tac "n1 = n2")
  apply(simp_all add: ring_simps)
apply(simp add: left_distrib[symmetric])
done

lemma numadd_nb: "\<lbrakk> numbound0 t ; numbound0 s\<rbrakk> \<Longrightarrow> numbound0 (numadd (t,s))"
by (induct t s rule: numadd.induct, auto simp add: Let_def)

recdef nummul "measure size"
  "nummul (C j) = (\<lambda> i. C (i*j))"
  "nummul (Add a b) = (\<lambda> i. numadd (nummul a i, nummul b i))"
  "nummul (Mul c t) = (\<lambda> i. nummul t (i*c))"
  "nummul t = (\<lambda> i. Mul i t)"

lemma nummul: "\<And> i. Inum bs (nummul t i) = Inum bs (Mul i t)"
by (induct t rule: nummul.induct, auto simp add: ring_simps numadd)

lemma nummul_nb: "\<And> i. numbound0 t \<Longrightarrow> numbound0 (nummul t i)"
by (induct t rule: nummul.induct, auto simp add: numadd_nb)

constdefs numneg :: "num \<Rightarrow> num"
  "numneg t \<equiv> nummul t (- 1)"

constdefs numsub :: "num \<Rightarrow> num \<Rightarrow> num"
  "numsub s t \<equiv> (if s = t then C 0 else numadd (s,numneg t))"

lemma numneg: "Inum bs (numneg t) = Inum bs (Neg t)"
using numneg_def nummul by simp

lemma numneg_nb: "numbound0 t \<Longrightarrow> numbound0 (numneg t)"
using numneg_def nummul_nb by simp

lemma numsub: "Inum bs (numsub a b) = Inum bs (Sub a b)"
using numneg numadd numsub_def by simp

lemma numsub_nb: "\<lbrakk> numbound0 t ; numbound0 s\<rbrakk> \<Longrightarrow> numbound0 (numsub t s)"
using numsub_def numadd_nb numneg_nb by simp

recdef simpnum "measure size"
  "simpnum (C j) = C j"
  "simpnum (Bound n) = Add (Mul 1 (Bound n)) (C 0)"
  "simpnum (Neg t) = numneg (simpnum t)"
  "simpnum (Add t s) = numadd (simpnum t,simpnum s)"
  "simpnum (Sub t s) = numsub (simpnum t) (simpnum s)"
  "simpnum (Mul i t) = (if i = 0 then (C 0) else nummul (simpnum t) i)"
  "simpnum t = t"

lemma simpnum_ci: "Inum bs (simpnum t) = Inum bs t"
by (induct t rule: simpnum.induct, auto simp add: numneg numadd numsub nummul)

lemma simpnum_numbound0: 
  "numbound0 t \<Longrightarrow> numbound0 (simpnum t)"
by (induct t rule: simpnum.induct, auto simp add: numadd_nb numsub_nb nummul_nb numneg_nb)

consts not:: "fm \<Rightarrow> fm"
recdef not "measure size"
  "not (NOT p) = p"
  "not T = F"
  "not F = T"
  "not p = NOT p"
lemma not: "Ifm bbs bs (not p) = Ifm bbs bs (NOT p)"
by (cases p) auto
lemma not_qf: "qfree p \<Longrightarrow> qfree (not p)"
by (cases p, auto)
lemma not_bn: "bound0 p \<Longrightarrow> bound0 (not p)"
by (cases p, auto)

constdefs conj :: "fm \<Rightarrow> fm \<Rightarrow> fm"
  "conj p q \<equiv> (if (p = F \<or> q=F) then F else if p=T then q else if q=T then p else And p q)"
lemma conj: "Ifm bbs bs (conj p q) = Ifm bbs bs (And p q)"
by (cases "p=F \<or> q=F",simp_all add: conj_def) (cases p,simp_all)

lemma conj_qf: "\<lbrakk>qfree p ; qfree q\<rbrakk> \<Longrightarrow> qfree (conj p q)"
using conj_def by auto 
lemma conj_nb: "\<lbrakk>bound0 p ; bound0 q\<rbrakk> \<Longrightarrow> bound0 (conj p q)"
using conj_def by auto 

constdefs disj :: "fm \<Rightarrow> fm \<Rightarrow> fm"
  "disj p q \<equiv> (if (p = T \<or> q=T) then T else if p=F then q else if q=F then p else Or p q)"

lemma disj: "Ifm bbs bs (disj p q) = Ifm bbs bs (Or p q)"
by (cases "p=T \<or> q=T",simp_all add: disj_def) (cases p,simp_all)
lemma disj_qf: "\<lbrakk>qfree p ; qfree q\<rbrakk> \<Longrightarrow> qfree (disj p q)"
using disj_def by auto 
lemma disj_nb: "\<lbrakk>bound0 p ; bound0 q\<rbrakk> \<Longrightarrow> bound0 (disj p q)"
using disj_def by auto 

constdefs   imp :: "fm \<Rightarrow> fm \<Rightarrow> fm"
  "imp p q \<equiv> (if (p = F \<or> q=T) then T else if p=T then q else if q=F then not p else Imp p q)"
lemma imp: "Ifm bbs bs (imp p q) = Ifm bbs bs (Imp p q)"
by (cases "p=F \<or> q=T",simp_all add: imp_def,cases p) (simp_all add: not)
lemma imp_qf: "\<lbrakk>qfree p ; qfree q\<rbrakk> \<Longrightarrow> qfree (imp p q)"
using imp_def by (cases "p=F \<or> q=T",simp_all add: imp_def,cases p) (simp_all add: not_qf) 
lemma imp_nb: "\<lbrakk>bound0 p ; bound0 q\<rbrakk> \<Longrightarrow> bound0 (imp p q)"
using imp_def by (cases "p=F \<or> q=T",simp_all add: imp_def,cases p) simp_all

constdefs   iff :: "fm \<Rightarrow> fm \<Rightarrow> fm"
  "iff p q \<equiv> (if (p = q) then T else if (p = not q \<or> not p = q) then F else 
       if p=F then not q else if q=F then not p else if p=T then q else if q=T then p else 
  Iff p q)"
lemma iff: "Ifm bbs bs (iff p q) = Ifm bbs bs (Iff p q)"
  by (unfold iff_def,cases "p=q", simp,cases "p=not q", simp add:not) 
(cases "not p= q", auto simp add:not)
lemma iff_qf: "\<lbrakk>qfree p ; qfree q\<rbrakk> \<Longrightarrow> qfree (iff p q)"
  by (unfold iff_def,cases "p=q", auto simp add: not_qf)
lemma iff_nb: "\<lbrakk>bound0 p ; bound0 q\<rbrakk> \<Longrightarrow> bound0 (iff p q)"
using iff_def by (unfold iff_def,cases "p=q", auto simp add: not_bn)

consts simpfm :: "fm \<Rightarrow> fm"
recdef simpfm "measure fmsize"
  "simpfm (And p q) = conj (simpfm p) (simpfm q)"
  "simpfm (Or p q) = disj (simpfm p) (simpfm q)"
  "simpfm (Imp p q) = imp (simpfm p) (simpfm q)"
  "simpfm (Iff p q) = iff (simpfm p) (simpfm q)"
  "simpfm (NOT p) = not (simpfm p)"
  "simpfm (Lt a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v < 0) then T else F 
  | _ \<Rightarrow> Lt a')"
  "simpfm (Le a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v \<le> 0)  then T else F | _ \<Rightarrow> Le a')"
  "simpfm (Gt a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v > 0)  then T else F | _ \<Rightarrow> Gt a')"
  "simpfm (Ge a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v \<ge> 0)  then T else F | _ \<Rightarrow> Ge a')"
  "simpfm (Eq a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v = 0)  then T else F | _ \<Rightarrow> Eq a')"
  "simpfm (NEq a) = (let a' = simpnum a in case a' of C v \<Rightarrow> if (v \<noteq> 0)  then T else F | _ \<Rightarrow> NEq a')"
  "simpfm (Dvd i a) = (if i=0 then simpfm (Eq a)
             else if (abs i = 1) then T
             else let a' = simpnum a in case a' of C v \<Rightarrow> if (i dvd v)  then T else F | _ \<Rightarrow> Dvd i a')"
  "simpfm (NDvd i a) = (if i=0 then simpfm (NEq a) 
             else if (abs i = 1) then F
             else let a' = simpnum a in case a' of C v \<Rightarrow> if (\<not>(i dvd v)) then T else F | _ \<Rightarrow> NDvd i a')"
  "simpfm p = p"
lemma simpfm: "Ifm bbs bs (simpfm p) = Ifm bbs bs p"
proof(induct p rule: simpfm.induct)
  case (6 a) let ?sa = "simpnum a" from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (7 a)  let ?sa = "simpnum a" 
  from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (8 a)  let ?sa = "simpnum a" 
  from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (9 a)  let ?sa = "simpnum a" 
  from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (10 a)  let ?sa = "simpnum a" 
  from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (11 a)  let ?sa = "simpnum a" 
  from simpnum_ci have sa: "Inum bs ?sa = Inum bs a" by simp
  {fix v assume "?sa = C v" hence ?case using sa by simp }
  moreover {assume "\<not> (\<exists> v. ?sa = C v)" hence ?case using sa 
      by (cases ?sa, simp_all add: Let_def)}
  ultimately show ?case by blast
next
  case (12 i a)  let ?sa = "simpnum a" from simpnum_ci 
  have sa: "Inum bs ?sa = Inum bs a" by simp
  have "i=0 \<or> abs i = 1 \<or> (i\<noteq>0 \<and> (abs i \<noteq> 1))" by auto
  {assume "i=0" hence ?case using "12.hyps" by (simp add: dvd_def Let_def)}
  moreover 
  {assume i1: "abs i = 1"
      from zdvd_1_left[where m = "Inum bs a"] uminus_dvd_conv[where d="1" and t="Inum bs a"]
      have ?case using i1 apply (cases "i=0", simp_all add: Let_def) 
	by (cases "i > 0", simp_all)}
  moreover   
  {assume inz: "i\<noteq>0" and cond: "abs i \<noteq> 1"
    {fix v assume "?sa = C v" hence ?case using sa[symmetric] inz cond
	by (cases "abs i = 1", auto) }
    moreover {assume "\<not> (\<exists> v. ?sa = C v)" 
      hence "simpfm (Dvd i a) = Dvd i ?sa" using inz cond 
	by (cases ?sa, auto simp add: Let_def)
      hence ?case using sa by simp}
    ultimately have ?case by blast}
  ultimately show ?case by blast
next
  case (13 i a)  let ?sa = "simpnum a" from simpnum_ci 
  have sa: "Inum bs ?sa = Inum bs a" by simp
  have "i=0 \<or> abs i = 1 \<or> (i\<noteq>0 \<and> (abs i \<noteq> 1))" by auto
  {assume "i=0" hence ?case using "13.hyps" by (simp add: dvd_def Let_def)}
  moreover 
  {assume i1: "abs i = 1"
      from zdvd_1_left[where m = "Inum bs a"] uminus_dvd_conv[where d="1" and t="Inum bs a"]
      have ?case using i1 apply (cases "i=0", simp_all add: Let_def)
      apply (cases "i > 0", simp_all) done}
  moreover   
  {assume inz: "i\<noteq>0" and cond: "abs i \<noteq> 1"
    {fix v assume "?sa = C v" hence ?case using sa[symmetric] inz cond
	by (cases "abs i = 1", auto) }
    moreover {assume "\<not> (\<exists> v. ?sa = C v)" 
      hence "simpfm (NDvd i a) = NDvd i ?sa" using inz cond 
	by (cases ?sa, auto simp add: Let_def)
      hence ?case using sa by simp}
    ultimately have ?case by blast}
  ultimately show ?case by blast
qed (induct p rule: simpfm.induct, simp_all add: conj disj imp iff not)

lemma simpfm_bound0: "bound0 p \<Longrightarrow> bound0 (simpfm p)"
proof(induct p rule: simpfm.induct)
  case (6 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (7 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (8 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (9 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (10 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (11 a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (12 i a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
next
  case (13 i a) hence nb: "numbound0 a" by simp
  hence "numbound0 (simpnum a)" by (simp only: simpnum_numbound0[OF nb])
  thus ?case by (cases "simpnum a", auto simp add: Let_def)
qed(auto simp add: disj_def imp_def iff_def conj_def not_bn)

lemma simpfm_qf: "qfree p \<Longrightarrow> qfree (simpfm p)"
by (induct p rule: simpfm.induct, auto simp add: disj_qf imp_qf iff_qf conj_qf not_qf Let_def)
 (case_tac "simpnum a",auto)+

  (* Generic quantifier elimination *)
consts qelim :: "fm \<Rightarrow> (fm \<Rightarrow> fm) \<Rightarrow> fm"
recdef qelim "measure fmsize"
  "qelim (E p) = (\<lambda> qe. DJ qe (qelim p qe))"
  "qelim (A p) = (\<lambda> qe. not (qe ((qelim (NOT p) qe))))"
  "qelim (NOT p) = (\<lambda> qe. not (qelim p qe))"
  "qelim (And p q) = (\<lambda> qe. conj (qelim p qe) (qelim q qe))" 
  "qelim (Or  p q) = (\<lambda> qe. disj (qelim p qe) (qelim q qe))" 
  "qelim (Imp p q) = (\<lambda> qe. imp (qelim p qe) (qelim q qe))"
  "qelim (Iff p q) = (\<lambda> qe. iff (qelim p qe) (qelim q qe))"
  "qelim p = (\<lambda> y. simpfm p)"

lemma qelim_ci:
  assumes qe_inv: "\<forall> bs p. qfree p \<longrightarrow> qfree (qe p) \<and> (Ifm bbs bs (qe p) = Ifm bbs bs (E p))"
  shows "\<And> bs. qfree (qelim p qe) \<and> (Ifm bbs bs (qelim p qe) = Ifm bbs bs p)"
using qe_inv DJ_qe[OF qe_inv] 
by(induct p rule: qelim.induct) 
(auto simp add: not disj conj iff imp not_qf disj_qf conj_qf imp_qf iff_qf 
  simpfm simpfm_qf simp del: simpfm.simps)
  (* Linearity for fm where Bound 0 ranges over \<int> *)
consts
  zsplit0 :: "num \<Rightarrow> int \<times> num" (* splits the bounded from the unbounded part*)
recdef zsplit0 "measure size"
  "zsplit0 (C c) = (0,C c)"
  "zsplit0 (Bound n) = (if n=0 then (1, C 0) else (0,Bound n))"
  "zsplit0 (CX i a) = (let (i',a') =  zsplit0 a in (i+i', a'))"
  "zsplit0 (Neg a) = (let (i',a') =  zsplit0 a in (-i', Neg a'))"
  "zsplit0 (Add a b) = (let (ia,a') =  zsplit0 a ; 
                            (ib,b') =  zsplit0 b 
                            in (ia+ib, Add a' b'))"
  "zsplit0 (Sub a b) = (let (ia,a') =  zsplit0 a ; 
                            (ib,b') =  zsplit0 b 
                            in (ia-ib, Sub a' b'))"
  "zsplit0 (Mul i a) = (let (i',a') =  zsplit0 a in (i*i', Mul i a'))"
(hints simp add: Let_def)

lemma zsplit0_I:
  shows "\<And> n a. zsplit0 t = (n,a) \<Longrightarrow> (Inum ((x::int) #bs) (CX n a) = Inum (x #bs) t) \<and> numbound0 a"
  (is "\<And> n a. ?S t = (n,a) \<Longrightarrow> (?I x (CX n a) = ?I x t) \<and> ?N a")
proof(induct t rule: zsplit0.induct)
  case (1 c n a) thus ?case by auto 
next
  case (2 m n a) thus ?case by (cases "m=0") auto
next
  case (3 i a n a')
  let ?j = "fst (zsplit0 a)"
  let ?b = "snd (zsplit0 a)"
  have abj: "zsplit0 a = (?j,?b)" by simp hence th: "a'=?b \<and> n=i+?j" using prems 
    by (simp add: Let_def split_def)
  from abj prems  have th2: "(?I x (CX ?j ?b) = ?I x a) \<and> ?N ?b" by blast
  from th have "?I x (CX n a') = ?I x (CX (i+?j) ?b)" by simp
  also from th2 have "\<dots> = ?I x (CX i (CX ?j ?b))" by (simp add: left_distrib)
  finally have "?I x (CX n a') = ?I  x (CX i a)" using th2 by simp
  with th2 th show ?case by blast
next
  case (4 t n a)
  let ?nt = "fst (zsplit0 t)"
  let ?at = "snd (zsplit0 t)"
  have abj: "zsplit0 t = (?nt,?at)" by simp hence th: "a=Neg ?at \<and> n=-?nt" using prems 
    by (simp add: Let_def split_def)
  from abj prems  have th2: "(?I x (CX ?nt ?at) = ?I x t) \<and> ?N ?at" by blast
  from th2[simplified] th[simplified] show ?case by simp
next
  case (5 s t n a)
  let ?ns = "fst (zsplit0 s)"
  let ?as = "snd (zsplit0 s)"
  let ?nt = "fst (zsplit0 t)"
  let ?at = "snd (zsplit0 t)"
  have abjs: "zsplit0 s = (?ns,?as)" by simp 
  moreover have abjt:  "zsplit0 t = (?nt,?at)" by simp 
  ultimately have th: "a=Add ?as ?at \<and> n=?ns + ?nt" using prems 
    by (simp add: Let_def split_def)
  from abjs[symmetric] have bluddy: "\<exists> x y. (x,y) = zsplit0 s" by blast
  from prems have "(\<exists> x y. (x,y) = zsplit0 s) \<longrightarrow> (\<forall>xa xb. zsplit0 t = (xa, xb) \<longrightarrow> Inum (x # bs) (CX xa xb) = Inum (x # bs) t \<and> numbound0 xb)" by simp
  with bluddy abjt have th3: "(?I x (CX ?nt ?at) = ?I x t) \<and> ?N ?at" by blast
  from abjs prems  have th2: "(?I x (CX ?ns ?as) = ?I x s) \<and> ?N ?as" by blast
  from th3[simplified] th2[simplified] th[simplified] show ?case 
    by (simp add: left_distrib)
next
  case (6 s t n a)
  let ?ns = "fst (zsplit0 s)"
  let ?as = "snd (zsplit0 s)"
  let ?nt = "fst (zsplit0 t)"
  let ?at = "snd (zsplit0 t)"
  have abjs: "zsplit0 s = (?ns,?as)" by simp 
  moreover have abjt:  "zsplit0 t = (?nt,?at)" by simp 
  ultimately have th: "a=Sub ?as ?at \<and> n=?ns - ?nt" using prems 
    by (simp add: Let_def split_def)
  from abjs[symmetric] have bluddy: "\<exists> x y. (x,y) = zsplit0 s" by blast
  from prems have "(\<exists> x y. (x,y) = zsplit0 s) \<longrightarrow> (\<forall>xa xb. zsplit0 t = (xa, xb) \<longrightarrow> Inum (x # bs) (CX xa xb) = Inum (x # bs) t \<and> numbound0 xb)" by simp
  with bluddy abjt have th3: "(?I x (CX ?nt ?at) = ?I x t) \<and> ?N ?at" by blast
  from abjs prems  have th2: "(?I x (CX ?ns ?as) = ?I x s) \<and> ?N ?as" by blast
  from th3[simplified] th2[simplified] th[simplified] show ?case 
    by (simp add: left_diff_distrib)
next
  case (7 i t n a)
  let ?nt = "fst (zsplit0 t)"
  let ?at = "snd (zsplit0 t)"
  have abj: "zsplit0 t = (?nt,?at)" by simp hence th: "a=Mul i ?at \<and> n=i*?nt" using prems 
    by (simp add: Let_def split_def)
  from abj prems  have th2: "(?I x (CX ?nt ?at) = ?I x t) \<and> ?N ?at" by blast
  hence " ?I x (Mul i t) = i * ?I x (CX ?nt ?at)" by simp
  also have "\<dots> = ?I x (CX (i*?nt) (Mul i ?at))" by (simp add: right_distrib)
  finally show ?case using th th2 by simp
qed

consts
  iszlfm :: "fm \<Rightarrow> bool"   (* Linearity test for fm *)
  zlfm :: "fm \<Rightarrow> fm"       (* Linearity transformation for fm *)
recdef iszlfm "measure size"
  "iszlfm (And p q) = (iszlfm p \<and> iszlfm q)" 
  "iszlfm (Or p q) = (iszlfm p \<and> iszlfm q)" 
  "iszlfm (Eq  (CX c e)) = (c>0 \<and> numbound0 e)"
  "iszlfm (NEq (CX c e)) = (c>0 \<and> numbound0 e)"
  "iszlfm (Lt  (CX c e)) = (c>0 \<and> numbound0 e)"
  "iszlfm (Le  (CX c e)) = (c>0 \<and> numbound0 e)"
  "iszlfm (Gt  (CX c e)) = (c>0 \<and> numbound0 e)"
  "iszlfm (Ge  (CX c e)) = ( c>0 \<and> numbound0 e)"
  "iszlfm (Dvd i (CX c e)) = 
                 (c>0 \<and> i>0 \<and> numbound0 e)"
  "iszlfm (NDvd i (CX c e))= 
                 (c>0 \<and> i>0 \<and> numbound0 e)"
  "iszlfm p = (isatom p \<and> (bound0 p))"

lemma zlin_qfree: "iszlfm p \<Longrightarrow> qfree p"
  by (induct p rule: iszlfm.induct) auto


recdef zlfm "measure fmsize"
  "zlfm (And p q) = And (zlfm p) (zlfm q)"
  "zlfm (Or p q) = Or (zlfm p) (zlfm q)"
  "zlfm (Imp p q) = Or (zlfm (NOT p)) (zlfm q)"
  "zlfm (Iff p q) = Or (And (zlfm p) (zlfm q)) (And (zlfm (NOT p)) (zlfm (NOT q)))"
  "zlfm (Lt a) = (let (c,r) = zsplit0 a in 
     if c=0 then Lt r else 
     if c>0 then (Lt (CX c r)) else (Gt (CX (- c) (Neg r))))"
  "zlfm (Le a) = (let (c,r) = zsplit0 a in 
     if c=0 then Le r else 
     if c>0 then (Le (CX c r)) else (Ge (CX (- c) (Neg r))))"
  "zlfm (Gt a) = (let (c,r) = zsplit0 a in 
     if c=0 then Gt r else 
     if c>0 then (Gt (CX c r)) else (Lt (CX (- c) (Neg r))))"
  "zlfm (Ge a) = (let (c,r) = zsplit0 a in 
     if c=0 then Ge r else 
     if c>0 then (Ge (CX c r)) else (Le (CX (- c) (Neg r))))"
  "zlfm (Eq a) = (let (c,r) = zsplit0 a in 
     if c=0 then Eq r else 
     if c>0 then (Eq (CX c r)) else (Eq (CX (- c) (Neg r))))"
  "zlfm (NEq a) = (let (c,r) = zsplit0 a in 
     if c=0 then NEq r else 
     if c>0 then (NEq (CX c r)) else (NEq (CX (- c) (Neg r))))"
  "zlfm (Dvd i a) = (if i=0 then zlfm (Eq a) 
        else (let (c,r) = zsplit0 a in 
              if c=0 then (Dvd (abs i) r) else 
      if c>0 then (Dvd (abs i) (CX c r))
      else (Dvd (abs i) (CX (- c) (Neg r)))))"
  "zlfm (NDvd i a) = (if i=0 then zlfm (NEq a) 
        else (let (c,r) = zsplit0 a in 
              if c=0 then (NDvd (abs i) r) else 
      if c>0 then (NDvd (abs i) (CX c r))
      else (NDvd (abs i) (CX (- c) (Neg r)))))"
  "zlfm (NOT (And p q)) = Or (zlfm (NOT p)) (zlfm (NOT q))"
  "zlfm (NOT (Or p q)) = And (zlfm (NOT p)) (zlfm (NOT q))"
  "zlfm (NOT (Imp p q)) = And (zlfm p) (zlfm (NOT q))"
  "zlfm (NOT (Iff p q)) = Or (And(zlfm p) (zlfm(NOT q))) (And (zlfm(NOT p)) (zlfm q))"
  "zlfm (NOT (NOT p)) = zlfm p"
  "zlfm (NOT T) = F"
  "zlfm (NOT F) = T"
  "zlfm (NOT (Lt a)) = zlfm (Ge a)"
  "zlfm (NOT (Le a)) = zlfm (Gt a)"
  "zlfm (NOT (Gt a)) = zlfm (Le a)"
  "zlfm (NOT (Ge a)) = zlfm (Lt a)"
  "zlfm (NOT (Eq a)) = zlfm (NEq a)"
  "zlfm (NOT (NEq a)) = zlfm (Eq a)"
  "zlfm (NOT (Dvd i a)) = zlfm (NDvd i a)"
  "zlfm (NOT (NDvd i a)) = zlfm (Dvd i a)"
  "zlfm (NOT (Closed P)) = NClosed P"
  "zlfm (NOT (NClosed P)) = Closed P"
  "zlfm p = p" (hints simp add: fmsize_pos)

lemma zlfm_I:
  assumes qfp: "qfree p"
  shows "(Ifm bbs (i#bs) (zlfm p) = Ifm bbs (i# bs) p) \<and> iszlfm (zlfm p)"
  (is "(?I (?l p) = ?I p) \<and> ?L (?l p)")
using qfp
proof(induct p rule: zlfm.induct)
  case (5 a) 
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (6 a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (7 a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (8 a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (9 a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (10 a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  from prems Ia nb  show ?case 
    by (auto simp add: Let_def split_def ring_simps) (cases "?r",auto)
next
  case (11 j a)  
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  have "j=0 \<or> (j\<noteq>0 \<and> ?c = 0) \<or> (j\<noteq>0 \<and> ?c >0) \<or> (j\<noteq> 0 \<and> ?c<0)" by arith
  moreover
  {assume "j=0" hence z: "zlfm (Dvd j a) = (zlfm (Eq a))" by (simp add: Let_def) 
    hence ?case using prems by (simp del: zlfm.simps add: zdvd_0_left)}
  moreover
  {assume "?c=0" and "j\<noteq>0" hence ?case 
      using zsplit0_I[OF spl, where x="i" and bs="bs"] zdvd_abs1[where d="j"]
      by (cases "?r", simp_all add: Let_def split_def)}
  moreover
  {assume cp: "?c > 0" and jnz: "j\<noteq>0" hence l: "?L (?l (Dvd j a))" 
      by (simp add: nb Let_def split_def)
    hence ?case using Ia cp jnz by (simp add: Let_def split_def 
	zdvd_abs1[where d="j" and t="(?c*i) + ?N ?r", symmetric])}
  moreover
  {assume cn: "?c < 0" and jnz: "j\<noteq>0" hence l: "?L (?l (Dvd j a))" 
      by (simp add: nb Let_def split_def)
    hence ?case using Ia cn jnz zdvd_zminus_iff[where m="abs j" and n="?c*i + ?N ?r" ]
      by (simp add: Let_def split_def 
      zdvd_abs1[where d="j" and t="(?c*i) + ?N ?r", symmetric])}
  ultimately show ?case by blast
next
  case (12 j a) 
  let ?c = "fst (zsplit0 a)"
  let ?r = "snd (zsplit0 a)"
  have spl: "zsplit0 a = (?c,?r)" by simp
  from zsplit0_I[OF spl, where x="i" and bs="bs"] 
  have Ia:"Inum (i # bs) a = Inum (i #bs) (CX ?c ?r)" and nb: "numbound0 ?r" by auto 
  let ?N = "\<lambda> t. Inum (i#bs) t"
  have "j=0 \<or> (j\<noteq>0 \<and> ?c = 0) \<or> (j\<noteq>0 \<and> ?c >0) \<or> (j\<noteq> 0 \<and> ?c<0)" by arith
  moreover
  {assume "j=0" hence z: "zlfm (NDvd j a) = (zlfm (NEq a))" by (simp add: Let_def) 
    hence ?case using prems by (simp del: zlfm.simps add: zdvd_0_left)}
  moreover
  {assume "?c=0" and "j\<noteq>0" hence ?case 
      using zsplit0_I[OF spl, where x="i" and bs="bs"] zdvd_abs1[where d="j"]
      by (cases "?r", simp_all add: Let_def split_def)}
  moreover
  {assume cp: "?c > 0" and jnz: "j\<noteq>0" hence l: "?L (?l (Dvd j a))" 
      by (simp add: nb Let_def split_def)
    hence ?case using Ia cp jnz by (simp add: Let_def split_def 
	zdvd_abs1[where d="j" and t="(?c*i) + ?N ?r", symmetric])}
  moreover
  {assume cn: "?c < 0" and jnz: "j\<noteq>0" hence l: "?L (?l (Dvd j a))" 
      by (simp add: nb Let_def split_def)
    hence ?case using Ia cn jnz zdvd_zminus_iff[where m="abs j" and n="?c*i + ?N ?r" ]
      by (simp add: Let_def split_def 
      zdvd_abs1[where d="j" and t="(?c*i) + ?N ?r", symmetric])}
  ultimately show ?case by blast
qed auto

consts 
  plusinf:: "fm \<Rightarrow> fm" (* Virtual substitution of +\<infinity>*)
  minusinf:: "fm \<Rightarrow> fm" (* Virtual substitution of -\<infinity>*)
  \<delta> :: "fm \<Rightarrow> int" (* Compute lcm {d| N\<^isup>?\<^isup> Dvd c*x+t \<in> p}*)
  d\<delta> :: "fm \<Rightarrow> int \<Rightarrow> bool" (* checks if a given l divides all the ds above*)

recdef minusinf "measure size"
  "minusinf (And p q) = And (minusinf p) (minusinf q)" 
  "minusinf (Or p q) = Or (minusinf p) (minusinf q)" 
  "minusinf (Eq  (CX c e)) = F"
  "minusinf (NEq (CX c e)) = T"
  "minusinf (Lt  (CX c e)) = T"
  "minusinf (Le  (CX c e)) = T"
  "minusinf (Gt  (CX c e)) = F"
  "minusinf (Ge  (CX c e)) = F"
  "minusinf p = p"

lemma minusinf_qfree: "qfree p \<Longrightarrow> qfree (minusinf p)"
  by (induct p rule: minusinf.induct, auto)

recdef plusinf "measure size"
  "plusinf (And p q) = And (plusinf p) (plusinf q)" 
  "plusinf (Or p q) = Or (plusinf p) (plusinf q)" 
  "plusinf (Eq  (CX c e)) = F"
  "plusinf (NEq (CX c e)) = T"
  "plusinf (Lt  (CX c e)) = F"
  "plusinf (Le  (CX c e)) = F"
  "plusinf (Gt  (CX c e)) = T"
  "plusinf (Ge  (CX c e)) = T"
  "plusinf p = p"

recdef \<delta> "measure size"
  "\<delta> (And p q) = ilcm (\<delta> p) (\<delta> q)" 
  "\<delta> (Or p q) = ilcm (\<delta> p) (\<delta> q)" 
  "\<delta> (Dvd i (CX c e)) = i"
  "\<delta> (NDvd i (CX c e)) = i"
  "\<delta> p = 1"

recdef d\<delta> "measure size"
  "d\<delta> (And p q) = (\<lambda> d. d\<delta> p d \<and> d\<delta> q d)" 
  "d\<delta> (Or p q) = (\<lambda> d. d\<delta> p d \<and> d\<delta> q d)" 
  "d\<delta> (Dvd i (CX c e)) = (\<lambda> d. i dvd d)"
  "d\<delta> (NDvd i (CX c e)) = (\<lambda> d. i dvd d)"
  "d\<delta> p = (\<lambda> d. True)"

lemma delta_mono: 
  assumes lin: "iszlfm p"
  and d: "d dvd d'"
  and ad: "d\<delta> p d"
  shows "d\<delta> p d'"
  using lin ad d
proof(induct p rule: iszlfm.induct)
  case (9 i c e)  thus ?case using d
    by (simp add: zdvd_trans[where m="i" and n="d" and k="d'"])
next
  case (10 i c e) thus ?case using d
    by (simp add: zdvd_trans[where m="i" and n="d" and k="d'"])
qed simp_all

lemma \<delta> : assumes lin:"iszlfm p"
  shows "d\<delta> p (\<delta> p) \<and> \<delta> p >0"
using lin
proof (induct p rule: iszlfm.induct)
  case (1 p q) 
  let ?d = "\<delta> (And p q)"
  from prems ilcm_pos have dp: "?d >0" by simp
  have d1: "\<delta> p dvd \<delta> (And p q)" using prems ilcm_dvd1 by simp 
   hence th: "d\<delta> p ?d" using delta_mono prems by auto
  have "\<delta> q dvd \<delta> (And p q)" using prems ilcm_dvd2 by simp 
  hence th': "d\<delta> q ?d" using delta_mono prems by auto
  from th th' dp show ?case by simp 
next
  case (2 p q)  
  let ?d = "\<delta> (And p q)"
  from prems ilcm_pos have dp: "?d >0" by simp
  have "\<delta> p dvd \<delta> (And p q)" using prems ilcm_dvd1 by simp hence th: "d\<delta> p ?d" using delta_mono prems by auto
  have "\<delta> q dvd \<delta> (And p q)" using prems ilcm_dvd2 by simp hence th': "d\<delta> q ?d" using delta_mono prems by auto
  from th th' dp show ?case by simp 
qed simp_all


consts 
  a\<beta> :: "fm \<Rightarrow> int \<Rightarrow> fm" (* adjusts the coeffitients of a formula *)
  d\<beta> :: "fm \<Rightarrow> int \<Rightarrow> bool" (* tests if all coeffs c of c divide a given l*)
  \<zeta>  :: "fm \<Rightarrow> int" (* computes the lcm of all coefficients of x*)
  \<beta> :: "fm \<Rightarrow> num list"
  \<alpha> :: "fm \<Rightarrow> num list"

recdef a\<beta> "measure size"
  "a\<beta> (And p q) = (\<lambda> k. And (a\<beta> p k) (a\<beta> q k))" 
  "a\<beta> (Or p q) = (\<lambda> k. Or (a\<beta> p k) (a\<beta> q k))" 
  "a\<beta> (Eq  (CX c e)) = (\<lambda> k. Eq (CX 1 (Mul (k div c) e)))"
  "a\<beta> (NEq (CX c e)) = (\<lambda> k. NEq (CX 1 (Mul (k div c) e)))"
  "a\<beta> (Lt  (CX c e)) = (\<lambda> k. Lt (CX 1 (Mul (k div c) e)))"
  "a\<beta> (Le  (CX c e)) = (\<lambda> k. Le (CX 1 (Mul (k div c) e)))"
  "a\<beta> (Gt  (CX c e)) = (\<lambda> k. Gt (CX 1 (Mul (k div c) e)))"
  "a\<beta> (Ge  (CX c e)) = (\<lambda> k. Ge (CX 1 (Mul (k div c) e)))"
  "a\<beta> (Dvd i (CX c e)) =(\<lambda> k. Dvd ((k div c)*i) (CX 1 (Mul (k div c) e)))"
  "a\<beta> (NDvd i (CX c e))=(\<lambda> k. NDvd ((k div c)*i) (CX 1 (Mul (k div c) e)))"
  "a\<beta> p = (\<lambda> k. p)"

recdef d\<beta> "measure size"
  "d\<beta> (And p q) = (\<lambda> k. (d\<beta> p k) \<and> (d\<beta> q k))" 
  "d\<beta> (Or p q) = (\<lambda> k. (d\<beta> p k) \<and> (d\<beta> q k))" 
  "d\<beta> (Eq  (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (NEq (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (Lt  (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (Le  (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (Gt  (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (Ge  (CX c e)) = (\<lambda> k. c dvd k)"
  "d\<beta> (Dvd i (CX c e)) =(\<lambda> k. c dvd k)"
  "d\<beta> (NDvd i (CX c e))=(\<lambda> k. c dvd k)"
  "d\<beta> p = (\<lambda> k. True)"

recdef \<zeta> "measure size"
  "\<zeta> (And p q) = ilcm (\<zeta> p) (\<zeta> q)" 
  "\<zeta> (Or p q) = ilcm (\<zeta> p) (\<zeta> q)" 
  "\<zeta> (Eq  (CX c e)) = c"
  "\<zeta> (NEq (CX c e)) = c"
  "\<zeta> (Lt  (CX c e)) = c"
  "\<zeta> (Le  (CX c e)) = c"
  "\<zeta> (Gt  (CX c e)) = c"
  "\<zeta> (Ge  (CX c e)) = c"
  "\<zeta> (Dvd i (CX c e)) = c"
  "\<zeta> (NDvd i (CX c e))= c"
  "\<zeta> p = 1"

recdef \<beta> "measure size"
  "\<beta> (And p q) = (\<beta> p @ \<beta> q)" 
  "\<beta> (Or p q) = (\<beta> p @ \<beta> q)" 
  "\<beta> (Eq  (CX c e)) = [Sub (C -1) e]"
  "\<beta> (NEq (CX c e)) = [Neg e]"
  "\<beta> (Lt  (CX c e)) = []"
  "\<beta> (Le  (CX c e)) = []"
  "\<beta> (Gt  (CX c e)) = [Neg e]"
  "\<beta> (Ge  (CX c e)) = [Sub (C -1) e]"
  "\<beta> p = []"

recdef \<alpha> "measure size"
  "\<alpha> (And p q) = (\<alpha> p @ \<alpha> q)" 
  "\<alpha> (Or p q) = (\<alpha> p @ \<alpha> q)" 
  "\<alpha> (Eq  (CX c e)) = [Add (C -1) e]"
  "\<alpha> (NEq (CX c e)) = [e]"
  "\<alpha> (Lt  (CX c e)) = [e]"
  "\<alpha> (Le  (CX c e)) = [Add (C -1) e]"
  "\<alpha> (Gt  (CX c e)) = []"
  "\<alpha> (Ge  (CX c e)) = []"
  "\<alpha> p = []"
consts mirror :: "fm \<Rightarrow> fm"
recdef mirror "measure size"
  "mirror (And p q) = And (mirror p) (mirror q)" 
  "mirror (Or p q) = Or (mirror p) (mirror q)" 
  "mirror (Eq  (CX c e)) = Eq (CX c (Neg e))"
  "mirror (NEq (CX c e)) = NEq (CX c (Neg e))"
  "mirror (Lt  (CX c e)) = Gt (CX c (Neg e))"
  "mirror (Le  (CX c e)) = Ge (CX c (Neg e))"
  "mirror (Gt  (CX c e)) = Lt (CX c (Neg e))"
  "mirror (Ge  (CX c e)) = Le (CX c (Neg e))"
  "mirror (Dvd i (CX c e)) = Dvd i (CX c (Neg e))"
  "mirror (NDvd i (CX c e)) = NDvd i (CX c (Neg e))"
  "mirror p = p"
    (* Lemmas for the correctness of \<sigma>\<rho> *)
lemma dvd1_eq1: "x >0 \<Longrightarrow> (x::int) dvd 1 = (x = 1)"
by auto

lemma minusinf_inf:
  assumes linp: "iszlfm p"
  and u: "d\<beta> p 1"
  shows "\<exists> (z::int). \<forall> x < z. Ifm bbs (x#bs) (minusinf p) = Ifm bbs (x#bs) p"
  (is "?P p" is "\<exists> (z::int). \<forall> x < z. ?I x (?M p) = ?I x p")
using linp u
proof (induct p rule: minusinf.induct)
  case (1 p q) thus ?case 
    by (auto simp add: dvd1_eq1) (rule_tac x="min z za" in exI,simp)
next
  case (2 p q) thus ?case 
    by (auto simp add: dvd1_eq1) (rule_tac x="min z za" in exI,simp)
next
  case (3 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). c*x + Inum (x#bs) e \<noteq> 0"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" and"x + Inum (x#bs) e = 0"
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "False" by simp
  qed
  thus ?case by auto
next
  case (4 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). c*x + Inum (x#bs) e \<noteq> 0"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" and"x + Inum (x#bs) e = 0"
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "False" by simp
  qed
  thus ?case by auto
next
  case (5 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). c*x + Inum (x#bs) e < 0"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" 
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "x + Inum (x#bs) e < 0" by simp
  qed
  thus ?case by auto
next
  case (6 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). c*x + Inum (x#bs) e \<le> 0"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" 
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "x + Inum (x#bs) e \<le> 0" by simp
  qed
  thus ?case by auto
next
  case (7 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). \<not> (c*x + Inum (x#bs) e > 0)"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" and"x + Inum (x#bs) e > 0"
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "False" by simp
  qed
  thus ?case by auto
next
  case (8 c e) hence c1: "c=1" and nb: "numbound0 e" using dvd1_eq1 by simp+
  hence "\<forall> x<(- Inum (a#bs) e). \<not> (c*x + Inum (x#bs) e \<ge> 0)"
  proof(clarsimp)
    fix x assume "x < (- Inum (a#bs) e)" and"x + Inum (x#bs) e \<ge> 0"
    with numbound0_I[OF nb, where bs="bs" and b="a" and b'="x"]
    show "False" by simp
  qed
  thus ?case by auto
qed auto

lemma minusinf_repeats:
  assumes d: "d\<delta> p d" and linp: "iszlfm p"
  shows "Ifm bbs ((x - k*d)#bs) (minusinf p) = Ifm bbs (x #bs) (minusinf p)"
using linp d
proof(induct p rule: iszlfm.induct) 
  case (9 i c e) hence nbe: "numbound0 e"  and id: "i dvd d" by simp+
    hence "\<exists> k. d=i*k" by (simp add: dvd_def)
    then obtain "di" where di_def: "d=i*di" by blast
    show ?case 
    proof(simp add: numbound0_I[OF nbe,where bs="bs" and b="x - k * d" and b'="x"] right_diff_distrib, rule iffI)
      assume 
	"i dvd c * x - c*(k*d) + Inum (x # bs) e"
      (is "?ri dvd ?rc*?rx - ?rc*(?rk*?rd) + ?I x e" is "?ri dvd ?rt")
      hence "\<exists> (l::int). ?rt = i * l" by (simp add: dvd_def)
      hence "\<exists> (l::int). c*x+ ?I x e = i*l+c*(k * i*di)" 
	by (simp add: ring_simps di_def)
      hence "\<exists> (l::int). c*x+ ?I x e = i*(l + c*k*di)"
	by (simp add: ring_simps)
      hence "\<exists> (l::int). c*x+ ?I x e = i*l" by blast
      thus "i dvd c*x + Inum (x # bs) e" by (simp add: dvd_def) 
    next
      assume 
	"i dvd c*x + Inum (x # bs) e" (is "?ri dvd ?rc*?rx+?e")
      hence "\<exists> (l::int). c*x+?e = i*l" by (simp add: dvd_def)
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*l - c*(k*d)" by simp
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*l - c*(k*i*di)" by (simp add: di_def)
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*((l - c*k*di))" by (simp add: ring_simps)
      hence "\<exists> (l::int). c*x - c * (k*d) +?e = i*l"
	by blast
      thus "i dvd c*x - c*(k*d) + Inum (x # bs) e" by (simp add: dvd_def)
    qed
next
  case (10 i c e)  hence nbe: "numbound0 e"  and id: "i dvd d" by simp+
    hence "\<exists> k. d=i*k" by (simp add: dvd_def)
    then obtain "di" where di_def: "d=i*di" by blast
    show ?case 
    proof(simp add: numbound0_I[OF nbe,where bs="bs" and b="x - k * d" and b'="x"] right_diff_distrib, rule iffI)
      assume 
	"i dvd c * x - c*(k*d) + Inum (x # bs) e"
      (is "?ri dvd ?rc*?rx - ?rc*(?rk*?rd) + ?I x e" is "?ri dvd ?rt")
      hence "\<exists> (l::int). ?rt = i * l" by (simp add: dvd_def)
      hence "\<exists> (l::int). c*x+ ?I x e = i*l+c*(k * i*di)" 
	by (simp add: ring_simps di_def)
      hence "\<exists> (l::int). c*x+ ?I x e = i*(l + c*k*di)"
	by (simp add: ring_simps)
      hence "\<exists> (l::int). c*x+ ?I x e = i*l" by blast
      thus "i dvd c*x + Inum (x # bs) e" by (simp add: dvd_def) 
    next
      assume 
	"i dvd c*x + Inum (x # bs) e" (is "?ri dvd ?rc*?rx+?e")
      hence "\<exists> (l::int). c*x+?e = i*l" by (simp add: dvd_def)
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*l - c*(k*d)" by simp
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*l - c*(k*i*di)" by (simp add: di_def)
      hence "\<exists> (l::int). c*x - c*(k*d) +?e = i*((l - c*k*di))" by (simp add: ring_simps)
      hence "\<exists> (l::int). c*x - c * (k*d) +?e = i*l"
	by blast
      thus "i dvd c*x - c*(k*d) + Inum (x # bs) e" by (simp add: dvd_def)
    qed
qed (auto simp add: nth_pos2 numbound0_I[where bs="bs" and b="x - k*d" and b'="x"])

    (* Is'nt this beautiful?*)
lemma minusinf_ex:
  assumes lin: "iszlfm p" and u: "d\<beta> p 1"
  and exmi: "\<exists> (x::int). Ifm bbs (x#bs) (minusinf p)" (is "\<exists> x. ?P1 x")
  shows "\<exists> (x::int). Ifm bbs (x#bs) p" (is "\<exists> x. ?P x")
proof-
  let ?d = "\<delta> p"
  from \<delta> [OF lin] have dpos: "?d >0" by simp
  from \<delta> [OF lin] have alld: "d\<delta> p ?d" by simp
  from minusinf_repeats[OF alld lin] have th1:"\<forall> x k. ?P1 x = ?P1 (x - (k * ?d))" by simp
  from minusinf_inf[OF lin u] have th2:"\<exists> z. \<forall> x. x<z \<longrightarrow> (?P x = ?P1 x)" by blast
  from minusinfinity [OF dpos th1 th2] exmi show ?thesis by blast
qed

    (*	And This ???*)
lemma minusinf_bex:
  assumes lin: "iszlfm p"
  shows "(\<exists> (x::int). Ifm bbs (x#bs) (minusinf p)) = 
         (\<exists> (x::int)\<in> {1..\<delta> p}. Ifm bbs (x#bs) (minusinf p))"
  (is "(\<exists> x. ?P x) = _")
proof-
  let ?d = "\<delta> p"
  from \<delta> [OF lin] have dpos: "?d >0" by simp
  from \<delta> [OF lin] have alld: "d\<delta> p ?d" by simp
  from minusinf_repeats[OF alld lin] have th1:"\<forall> x k. ?P x = ?P (x - (k * ?d))" by simp
  from periodic_finite_ex[OF dpos th1] show ?thesis by blast
qed


lemma mirror\<alpha>\<beta>:
  assumes lp: "iszlfm p"
  shows "(Inum (i#bs)) ` set (\<alpha> p) = (Inum (i#bs)) ` set (\<beta> (mirror p))"
using lp
by (induct p rule: mirror.induct, auto)

lemma mirror: 
  assumes lp: "iszlfm p"
  shows "Ifm bbs (x#bs) (mirror p) = Ifm bbs ((- x)#bs) p" 
using lp
proof(induct p rule: iszlfm.induct)
  case (9 j c e) hence nb: "numbound0 e" by simp
  have "Ifm bbs (x#bs) (mirror (Dvd j (CX c e))) = (j dvd c*x - Inum (x#bs) e)" (is "_ = (j dvd c*x - ?e)") by simp
    also have "\<dots> = (j dvd (- (c*x - ?e)))"
    by (simp only: zdvd_zminus_iff)
  also have "\<dots> = (j dvd (c* (- x)) + ?e)"
    apply (simp only: minus_mult_right[symmetric] minus_mult_left[symmetric] diff_def zadd_ac zminus_zadd_distrib)
    by (simp add: ring_simps)
  also have "\<dots> = Ifm bbs ((- x)#bs) (Dvd j (CX c e))"
    using numbound0_I[OF nb, where bs="bs" and b="x" and b'="- x"]
    by simp
  finally show ?case .
next
    case (10 j c e) hence nb: "numbound0 e" by simp
  have "Ifm bbs (x#bs) (mirror (Dvd j (CX c e))) = (j dvd c*x - Inum (x#bs) e)" (is "_ = (j dvd c*x - ?e)") by simp
    also have "\<dots> = (j dvd (- (c*x - ?e)))"
    by (simp only: zdvd_zminus_iff)
  also have "\<dots> = (j dvd (c* (- x)) + ?e)"
    apply (simp only: minus_mult_right[symmetric] minus_mult_left[symmetric] diff_def zadd_ac zminus_zadd_distrib)
    by (simp add: ring_simps)
  also have "\<dots> = Ifm bbs ((- x)#bs) (Dvd j (CX c e))"
    using numbound0_I[OF nb, where bs="bs" and b="x" and b'="- x"]
    by simp
  finally show ?case by simp
qed (auto simp add: numbound0_I[where bs="bs" and b="x" and b'="- x"] nth_pos2)

lemma mirror_l: "iszlfm p \<and> d\<beta> p 1 
  \<Longrightarrow> iszlfm (mirror p) \<and> d\<beta> (mirror p) 1"
by (induct p rule: mirror.induct, auto)

lemma mirror_\<delta>: "iszlfm p \<Longrightarrow> \<delta> (mirror p) = \<delta> p"
by (induct p rule: mirror.induct,auto)

lemma \<beta>_numbound0: assumes lp: "iszlfm p"
  shows "\<forall> b\<in> set (\<beta> p). numbound0 b"
  using lp by (induct p rule: \<beta>.induct,auto)

lemma d\<beta>_mono: 
  assumes linp: "iszlfm p"
  and dr: "d\<beta> p l"
  and d: "l dvd l'"
  shows "d\<beta> p l'"
using dr linp zdvd_trans[where n="l" and k="l'", simplified d]
by (induct p rule: iszlfm.induct) simp_all

lemma \<alpha>_l: assumes lp: "iszlfm p"
  shows "\<forall> b\<in> set (\<alpha> p). numbound0 b"
using lp
by(induct p rule: \<alpha>.induct, auto)

lemma \<zeta>: 
  assumes linp: "iszlfm p"
  shows "\<zeta> p > 0 \<and> d\<beta> p (\<zeta> p)"
using linp
proof(induct p rule: iszlfm.induct)
  case (1 p q)
  from prems have dl1: "\<zeta> p dvd ilcm (\<zeta> p) (\<zeta> q)" 
    by (simp add: ilcm_dvd1[where a="\<zeta> p" and b="\<zeta> q"])
  from prems have dl2: "\<zeta> q dvd ilcm (\<zeta> p) (\<zeta> q)" 
    by (simp add: ilcm_dvd2[where a="\<zeta> p" and b="\<zeta> q"])
  from prems d\<beta>_mono[where p = "p" and l="\<zeta> p" and l'="ilcm (\<zeta> p) (\<zeta> q)"] 
    d\<beta>_mono[where p = "q" and l="\<zeta> q" and l'="ilcm (\<zeta> p) (\<zeta> q)"] 
    dl1 dl2 show ?case by (auto simp add: ilcm_pos)
next
  case (2 p q)
  from prems have dl1: "\<zeta> p dvd ilcm (\<zeta> p) (\<zeta> q)" 
    by (simp add: ilcm_dvd1[where a="\<zeta> p" and b="\<zeta> q"])
  from prems have dl2: "\<zeta> q dvd ilcm (\<zeta> p) (\<zeta> q)" 
    by (simp add: ilcm_dvd2[where a="\<zeta> p" and b="\<zeta> q"])
  from prems d\<beta>_mono[where p = "p" and l="\<zeta> p" and l'="ilcm (\<zeta> p) (\<zeta> q)"] 
    d\<beta>_mono[where p = "q" and l="\<zeta> q" and l'="ilcm (\<zeta> p) (\<zeta> q)"] 
    dl1 dl2 show ?case by (auto simp add: ilcm_pos)
qed (auto simp add: ilcm_pos)

lemma a\<beta>: assumes linp: "iszlfm p" and d: "d\<beta> p l" and lp: "l > 0"
  shows "iszlfm (a\<beta> p l) \<and> d\<beta> (a\<beta> p l) 1 \<and> (Ifm bbs (l*x #bs) (a\<beta> p l) = Ifm bbs (x#bs) p)"
using linp d
proof (induct p rule: iszlfm.induct)
  case (5 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l*x + (l div c) * Inum (x # bs) e < 0) =
          ((c * (l div c)) * x + (l div c) * Inum (x # bs) e < 0)"
      by simp
    also have "\<dots> = ((l div c) * (c*x + Inum (x # bs) e) < (l div c) * 0)" by (simp add: ring_simps)
    also have "\<dots> = (c*x + Inum (x # bs) e < 0)"
    using mult_less_0_iff [where a="(l div c)" and b="c*x + Inum (x # bs) e"] ldcp by simp
  finally show ?case using numbound0_I[OF be,where b="l*x" and b'="x" and bs="bs"] be  by simp
next
  case (6 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l*x + (l div c) * Inum (x# bs) e \<le> 0) =
          ((c * (l div c)) * x + (l div c) * Inum (x # bs) e \<le> 0)"
      by simp
    also have "\<dots> = ((l div c) * (c * x + Inum (x # bs) e) \<le> ((l div c)) * 0)" by (simp add: ring_simps)
    also have "\<dots> = (c*x + Inum (x # bs) e \<le> 0)"
    using mult_le_0_iff [where a="(l div c)" and b="c*x + Inum (x # bs) e"] ldcp by simp
  finally show ?case using numbound0_I[OF be,where b="l*x" and b'="x" and bs="bs"]  be by simp
next
  case (7 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l*x + (l div c)* Inum (x # bs) e > 0) =
          ((c * (l div c)) * x + (l div c) * Inum (x # bs) e > 0)"
      by simp
    also have "\<dots> = ((l div c) * (c * x + Inum (x # bs) e) > ((l div c)) * 0)" by (simp add: ring_simps)
    also have "\<dots> = (c * x + Inum (x # bs) e > 0)"
    using zero_less_mult_iff [where a="(l div c)" and b="c * x + Inum (x # bs) e"] ldcp by simp
  finally show ?case using numbound0_I[OF be,where b="(l * x)" and b'="x" and bs="bs"]  be  by simp
next
  case (8 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l*x + (l div c)* Inum (x # bs) e \<ge> 0) =
          ((c*(l div c))*x + (l div c)* Inum (x # bs) e \<ge> 0)"
      by simp
    also have "\<dots> = ((l div c)*(c*x + Inum (x # bs) e) \<ge> ((l div c)) * 0)" 
      by (simp add: ring_simps)
    also have "\<dots> = (c*x + Inum (x # bs) e \<ge> 0)" using ldcp 
      zero_le_mult_iff [where a="l div c" and b="c*x + Inum (x # bs) e"] by simp
  finally show ?case using be numbound0_I[OF be,where b="l*x" and b'="x" and bs="bs"]  
    by simp
next
  case (3 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l * x + (l div c) * Inum (x # bs) e = 0) =
          ((c * (l div c)) * x + (l div c) * Inum (x # bs) e = 0)"
      by simp
    also have "\<dots> = ((l div c) * (c * x + Inum (x # bs) e) = ((l div c)) * 0)" by (simp add: ring_simps)
    also have "\<dots> = (c * x + Inum (x # bs) e = 0)"
    using mult_eq_0_iff [where a="(l div c)" and b="c * x + Inum (x # bs) e"] ldcp by simp
  finally show ?case using numbound0_I[OF be,where b="(l * x)" and b'="x" and bs="bs"]  be  by simp
next
  case (4 c e) hence cp: "c>0" and be: "numbound0 e" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(l * x + (l div c) * Inum (x # bs) e \<noteq> 0) =
          ((c * (l div c)) * x + (l div c) * Inum (x # bs) e \<noteq> 0)"
      by simp
    also have "\<dots> = ((l div c) * (c * x + Inum (x # bs) e) \<noteq> ((l div c)) * 0)" by (simp add: ring_simps)
    also have "\<dots> = (c * x + Inum (x # bs) e \<noteq> 0)"
    using zero_le_mult_iff [where a="(l div c)" and b="c * x + Inum (x # bs) e"] ldcp by simp
  finally show ?case using numbound0_I[OF be,where b="(l * x)" and b'="x" and bs="bs"]  be  by simp
next
  case (9 j c e) hence cp: "c>0" and be: "numbound0 e" and jp: "j > 0" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(\<exists> (k::int). l * x + (l div c) * Inum (x # bs) e = ((l div c) * j) * k) = (\<exists> (k::int). (c * (l div c)) * x + (l div c) * Inum (x # bs) e = ((l div c) * j) * k)"  by simp
    also have "\<dots> = (\<exists> (k::int). (l div c) * (c * x + Inum (x # bs) e - j * k) = (l div c)*0)" by (simp add: ring_simps)
    also have "\<dots> = (\<exists> (k::int). c * x + Inum (x # bs) e - j * k = 0)"
    using zero_le_mult_iff [where a="(l div c)" and b="c * x + Inum (x # bs) e - j * k"] ldcp by simp
  also have "\<dots> = (\<exists> (k::int). c * x + Inum (x # bs) e = j * k)" by simp
  finally show ?case using numbound0_I[OF be,where b="(l * x)" and b'="x" and bs="bs"] be  mult_strict_mono[OF ldcp jp ldcp ] by (simp add: dvd_def)
next
  case (10 j c e) hence cp: "c>0" and be: "numbound0 e" and jp: "j > 0" and d': "c dvd l" by simp+
    from lp cp have clel: "c\<le>l" by (simp add: zdvd_imp_le [OF d' lp])
    from cp have cnz: "c \<noteq> 0" by simp
    have "c div c\<le> l div c"
      by (simp add: zdiv_mono1[OF clel cp])
    then have ldcp:"0 < l div c" 
      by (simp add: zdiv_self[OF cnz])
    have "c * (l div c) = c* (l div c) + l mod c" using d' zdvd_iff_zmod_eq_0[where m="c" and n="l"] by simp
    hence cl:"c * (l div c) =l" using zmod_zdiv_equality[where a="l" and b="c", symmetric] 
      by simp
    hence "(\<exists> (k::int). l * x + (l div c) * Inum (x # bs) e = ((l div c) * j) * k) = (\<exists> (k::int). (c * (l div c)) * x + (l div c) * Inum (x # bs) e = ((l div c) * j) * k)"  by simp
    also have "\<dots> = (\<exists> (k::int). (l div c) * (c * x + Inum (x # bs) e - j * k) = (l div c)*0)" by (simp add: ring_simps)
    also have "\<dots> = (\<exists> (k::int). c * x + Inum (x # bs) e - j * k = 0)"
    using zero_le_mult_iff [where a="(l div c)" and b="c * x + Inum (x # bs) e - j * k"] ldcp by simp
  also have "\<dots> = (\<exists> (k::int). c * x + Inum (x # bs) e = j * k)" by simp
  finally show ?case using numbound0_I[OF be,where b="(l * x)" and b'="x" and bs="bs"] be  mult_strict_mono[OF ldcp jp ldcp ] by (simp add: dvd_def)
qed (simp_all add: nth_pos2 numbound0_I[where bs="bs" and b="(l * x)" and b'="x"])

lemma a\<beta>_ex: assumes linp: "iszlfm p" and d: "d\<beta> p l" and lp: "l>0"
  shows "(\<exists> x. l dvd x \<and> Ifm bbs (x #bs) (a\<beta> p l)) = (\<exists> (x::int). Ifm bbs (x#bs) p)"
  (is "(\<exists> x. l dvd x \<and> ?P x) = (\<exists> x. ?P' x)")
proof-
  have "(\<exists> x. l dvd x \<and> ?P x) = (\<exists> (x::int). ?P (l*x))"
    using unity_coeff_ex[where l="l" and P="?P", simplified] by simp
  also have "\<dots> = (\<exists> (x::int). ?P' x)" using a\<beta>[OF linp d lp] by simp
  finally show ?thesis  . 
qed

lemma \<beta>:
  assumes lp: "iszlfm p"
  and u: "d\<beta> p 1"
  and d: "d\<delta> p d"
  and dp: "d > 0"
  and nob: "\<not>(\<exists>(j::int) \<in> {1 .. d}. \<exists> b\<in> (Inum (a#bs)) ` set(\<beta> p). x = b + j)"
  and p: "Ifm bbs (x#bs) p" (is "?P x")
  shows "?P (x - d)"
using lp u d dp nob p
proof(induct p rule: iszlfm.induct)
  case (5 c e) hence c1: "c=1" and  bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    with dp p c1 numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"] prems
    show ?case by simp
next
  case (6 c e)  hence c1: "c=1" and  bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    with dp p c1 numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"] prems
    show ?case by simp
next
  case (7 c e) hence p: "Ifm bbs (x #bs) (Gt (CX c e))" and c1: "c=1" and bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    {assume "(x-d) +?e > 0" hence ?case using c1 
      numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"] by simp}
    moreover
    {assume H: "\<not> (x-d) + ?e > 0" 
      let ?v="Neg e"
      have vb: "?v \<in> set (\<beta> (Gt (CX c e)))" by simp
      from prems(11)[simplified simp_thms Inum.simps \<beta>.simps set.simps bex_simps numbound0_I[OF bn,where b="a" and b'="x" and bs="bs"]] 
      have nob: "\<not> (\<exists> j\<in> {1 ..d}. x =  - ?e + j)" by auto 
      from H p have "x + ?e > 0 \<and> x + ?e \<le> d" by (simp add: c1)
      hence "x + ?e \<ge> 1 \<and> x + ?e \<le> d"  by simp
      hence "\<exists> (j::int) \<in> {1 .. d}. j = x + ?e" by simp
      hence "\<exists> (j::int) \<in> {1 .. d}. x = (- ?e + j)" 
	by (simp add: ring_simps)
      with nob have ?case by auto}
    ultimately show ?case by blast
next
  case (8 c e) hence p: "Ifm bbs (x #bs) (Ge (CX c e))" and c1: "c=1" and bn:"numbound0 e" 
    using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    {assume "(x-d) +?e \<ge> 0" hence ?case using  c1 
      numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"]
	by simp}
    moreover
    {assume H: "\<not> (x-d) + ?e \<ge> 0" 
      let ?v="Sub (C -1) e"
      have vb: "?v \<in> set (\<beta> (Ge (CX c e)))" by simp
      from prems(11)[simplified simp_thms Inum.simps \<beta>.simps set.simps bex_simps numbound0_I[OF bn,where b="a" and b'="x" and bs="bs"]] 
      have nob: "\<not> (\<exists> j\<in> {1 ..d}. x =  - ?e - 1 + j)" by auto 
      from H p have "x + ?e \<ge> 0 \<and> x + ?e < d" by (simp add: c1)
      hence "x + ?e +1 \<ge> 1 \<and> x + ?e + 1 \<le> d"  by simp
      hence "\<exists> (j::int) \<in> {1 .. d}. j = x + ?e + 1" by simp
      hence "\<exists> (j::int) \<in> {1 .. d}. x= - ?e - 1 + j" by (simp add: ring_simps)
      with nob have ?case by simp }
    ultimately show ?case by blast
next
  case (3 c e) hence p: "Ifm bbs (x #bs) (Eq (CX c e))" (is "?p x") and c1: "c=1" and bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    let ?v="(Sub (C -1) e)"
    have vb: "?v \<in> set (\<beta> (Eq (CX c e)))" by simp
    from p have "x= - ?e" by (simp add: c1) with prems(11) show ?case using dp
      by simp (erule ballE[where x="1"],
	simp_all add:ring_simps numbound0_I[OF bn,where b="x"and b'="a"and bs="bs"])
next
  case (4 c e)hence p: "Ifm bbs (x #bs) (NEq (CX c e))" (is "?p x") and c1: "c=1" and bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    let ?v="Neg e"
    have vb: "?v \<in> set (\<beta> (NEq (CX c e)))" by simp
    {assume "x - d + Inum (((x -d)) # bs) e \<noteq> 0" 
      hence ?case by (simp add: c1)}
    moreover
    {assume H: "x - d + Inum (((x -d)) # bs) e = 0"
      hence "x = - Inum (((x -d)) # bs) e + d" by simp
      hence "x = - Inum (a # bs) e + d"
	by (simp add: numbound0_I[OF bn,where b="x - d"and b'="a"and bs="bs"])
       with prems(11) have ?case using dp by simp}
  ultimately show ?case by blast
next 
  case (9 j c e) hence p: "Ifm bbs (x #bs) (Dvd j (CX c e))" (is "?p x") and c1: "c=1" and bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    from prems have id: "j dvd d" by simp
    from c1 have "?p x = (j dvd (x+ ?e))" by simp
    also have "\<dots> = (j dvd x - d + ?e)" 
      using dvd_period[OF id, where x="x" and c="-1" and t="?e"] by simp
    finally show ?case 
      using numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"] c1 p by simp
next
  case (10 j c e) hence p: "Ifm bbs (x #bs) (NDvd j (CX c e))" (is "?p x") and c1: "c=1" and bn:"numbound0 e" using dvd1_eq1[where x="c"] by simp+
    let ?e = "Inum (x # bs) e"
    from prems have id: "j dvd d" by simp
    from c1 have "?p x = (\<not> j dvd (x+ ?e))" by simp
    also have "\<dots> = (\<not> j dvd x - d + ?e)" 
      using dvd_period[OF id, where x="x" and c="-1" and t="?e"] by simp
    finally show ?case using numbound0_I[OF bn,where b="(x-d)" and b'="x" and bs="bs"] c1 p by simp
qed (auto simp add: numbound0_I[where bs="bs" and b="(x - d)" and b'="x"] nth_pos2)

lemma \<beta>':   
  assumes lp: "iszlfm p"
  and u: "d\<beta> p 1"
  and d: "d\<delta> p d"
  and dp: "d > 0"
  shows "\<forall> x. \<not>(\<exists>(j::int) \<in> {1 .. d}. \<exists> b\<in> set(\<beta> p). Ifm bbs ((Inum (a#bs) b + j) #bs) p) \<longrightarrow> Ifm bbs (x#bs) p \<longrightarrow> Ifm bbs ((x - d)#bs) p" (is "\<forall> x. ?b \<longrightarrow> ?P x \<longrightarrow> ?P (x - d)")
proof(clarify)
  fix x 
  assume nb:"?b" and px: "?P x" 
  hence nb2: "\<not>(\<exists>(j::int) \<in> {1 .. d}. \<exists> b\<in> (Inum (a#bs)) ` set(\<beta> p). x = b + j)"
    by auto
  from  \<beta>[OF lp u d dp nb2 px] show "?P (x -d )" .
qed
lemma cpmi_eq: "0 < D \<Longrightarrow> (EX z::int. ALL x. x < z --> (P x = P1 x))
==> ALL x.~(EX (j::int) : {1..D}. EX (b::int) : B. P(b+j)) --> P (x) --> P (x - D) 
==> (ALL (x::int). ALL (k::int). ((P1 x)= (P1 (x-k*D))))
==> (EX (x::int). P(x)) = ((EX (j::int) : {1..D} . (P1(j))) | (EX (j::int) : {1..D}. EX (b::int) : B. P (b+j)))"
apply(rule iffI)
prefer 2
apply(drule minusinfinity)
apply assumption+
apply(fastsimp)
apply clarsimp
apply(subgoal_tac "!!k. 0<=k \<Longrightarrow> !x. P x \<longrightarrow> P (x - k*D)")
apply(frule_tac x = x and z=z in decr_lemma)
apply(subgoal_tac "P1(x - (\<bar>x - z\<bar> + 1) * D)")
prefer 2
apply(subgoal_tac "0 <= (\<bar>x - z\<bar> + 1)")
prefer 2 apply arith
 apply fastsimp
apply(drule (1)  periodic_finite_ex)
apply blast
apply(blast dest:decr_mult_lemma)
done

theorem cp_thm:
  assumes lp: "iszlfm p"
  and u: "d\<beta> p 1"
  and d: "d\<delta> p d"
  and dp: "d > 0"
  shows "(\<exists> (x::int). Ifm bbs (x #bs) p) = (\<exists> j\<in> {1.. d}. Ifm bbs (j #bs) (minusinf p) \<or> (\<exists> b \<in> set (\<beta> p). Ifm bbs ((Inum (i#bs) b + j) #bs) p))"
  (is "(\<exists> (x::int). ?P (x)) = (\<exists> j\<in> ?D. ?M j \<or> (\<exists> b\<in> ?B. ?P (?I b + j)))")
proof-
  from minusinf_inf[OF lp u] 
  have th: "\<exists>(z::int). \<forall>x<z. ?P (x) = ?M x" by blast
  let ?B' = "{?I b | b. b\<in> ?B}"
  have BB': "(\<exists>j\<in>?D. \<exists>b\<in> ?B. ?P (?I b +j)) = (\<exists> j \<in> ?D. \<exists> b \<in> ?B'. ?P (b + j))" by auto
  hence th2: "\<forall> x. \<not> (\<exists> j \<in> ?D. \<exists> b \<in> ?B'. ?P ((b + j))) \<longrightarrow> ?P (x) \<longrightarrow> ?P ((x - d))" 
    using \<beta>'[OF lp u d dp, where a="i" and bbs = "bbs"] by blast
  from minusinf_repeats[OF d lp]
  have th3: "\<forall> x k. ?M x = ?M (x-k*d)" by simp
  from cpmi_eq[OF dp th th2 th3] BB' show ?thesis by blast
qed

    (* Implement the right hand sides of Cooper's theorem and Ferrante and Rackoff. *)
lemma mirror_ex: 
  assumes lp: "iszlfm p"
  shows "(\<exists> x. Ifm bbs (x#bs) (mirror p)) = (\<exists> x. Ifm bbs (x#bs) p)"
  (is "(\<exists> x. ?I x ?mp) = (\<exists> x. ?I x p)")
proof(auto)
  fix x assume "?I x ?mp" hence "?I (- x) p" using mirror[OF lp] by blast
  thus "\<exists> x. ?I x p" by blast
next
  fix x assume "?I x p" hence "?I (- x) ?mp" 
    using mirror[OF lp, where x="- x", symmetric] by auto
  thus "\<exists> x. ?I x ?mp" by blast
qed
  
  
lemma cp_thm': 
  assumes lp: "iszlfm p"
  and up: "d\<beta> p 1" and dd: "d\<delta> p d" and dp: "d > 0"
  shows "(\<exists> x. Ifm bbs (x#bs) p) = ((\<exists> j\<in> {1 .. d}. Ifm bbs (j#bs) (minusinf p)) \<or> (\<exists> j\<in> {1.. d}. \<exists> b\<in> (Inum (i#bs)) ` set (\<beta> p). Ifm bbs ((b+j)#bs) p))"
  using cp_thm[OF lp up dd dp,where i="i"] by auto

constdefs unit:: "fm \<Rightarrow> fm \<times> num list \<times> int"
  "unit p \<equiv> (let p' = zlfm p ; l = \<zeta> p' ; q = And (Dvd l (CX 1 (C 0))) (a\<beta> p' l); d = \<delta> q;
             B = remdups (map simpnum (\<beta> q)) ; a = remdups (map simpnum (\<alpha> q))
             in if length B \<le> length a then (q,B,d) else (mirror q, a,d))"

lemma unit: assumes qf: "qfree p"
  shows "\<And> q B d. unit p = (q,B,d) \<Longrightarrow> ((\<exists> x. Ifm bbs (x#bs) p) = (\<exists> x. Ifm bbs (x#bs) q)) \<and> (Inum (i#bs)) ` set B = (Inum (i#bs)) ` set (\<beta> q) \<and> d\<beta> q 1 \<and> d\<delta> q d \<and> d >0 \<and> iszlfm q \<and> (\<forall> b\<in> set B. numbound0 b)"
proof-
  fix q B d 
  assume qBd: "unit p = (q,B,d)"
  let ?thes = "((\<exists> x. Ifm bbs (x#bs) p) = (\<exists> x. Ifm bbs (x#bs) q)) \<and>
    Inum (i#bs) ` set B = Inum (i#bs) ` set (\<beta> q) \<and>
    d\<beta> q 1 \<and> d\<delta> q d \<and> 0 < d \<and> iszlfm q \<and> (\<forall> b\<in> set B. numbound0 b)"
  let ?I = "\<lambda> x p. Ifm bbs (x#bs) p"
  let ?p' = "zlfm p"
  let ?l = "\<zeta> ?p'"
  let ?q = "And (Dvd ?l (CX 1 (C 0))) (a\<beta> ?p' ?l)"
  let ?d = "\<delta> ?q"
  let ?B = "set (\<beta> ?q)"
  let ?B'= "remdups (map simpnum (\<beta> ?q))"
  let ?A = "set (\<alpha> ?q)"
  let ?A'= "remdups (map simpnum (\<alpha> ?q))"
  from conjunct1[OF zlfm_I[OF qf, where bs="bs"]] 
  have pp': "\<forall> i. ?I i ?p' = ?I i p" by auto
  from conjunct2[OF zlfm_I[OF qf, where bs="bs" and i="i"]]
  have lp': "iszlfm ?p'" . 
  from lp' \<zeta>[where p="?p'"] have lp: "?l >0" and dl: "d\<beta> ?p' ?l" by auto
  from a\<beta>_ex[where p="?p'" and l="?l" and bs="bs", OF lp' dl lp] pp'
  have pq_ex:"(\<exists> (x::int). ?I x p) = (\<exists> x. ?I x ?q)" by simp 
  from lp' lp a\<beta>[OF lp' dl lp] have lq:"iszlfm ?q" and uq: "d\<beta> ?q 1"  by auto
  from \<delta>[OF lq] have dp:"?d >0" and dd: "d\<delta> ?q ?d" by blast+
  let ?N = "\<lambda> t. Inum (i#bs) t"
  have "?N ` set ?B' = ((?N o simpnum) ` ?B)" by auto 
  also have "\<dots> = ?N ` ?B" using simpnum_ci[where bs="i#bs"] by auto
  finally have BB': "?N ` set ?B' = ?N ` ?B" .
  have "?N ` set ?A' = ((?N o simpnum) ` ?A)" by auto 
  also have "\<dots> = ?N ` ?A" using simpnum_ci[where bs="i#bs"] by auto
  finally have AA': "?N ` set ?A' = ?N ` ?A" .
  from \<beta>_numbound0[OF lq] have B_nb:"\<forall> b\<in> set ?B'. numbound0 b"
    by (simp add: simpnum_numbound0)
  from \<alpha>_l[OF lq] have A_nb: "\<forall> b\<in> set ?A'. numbound0 b"
    by (simp add: simpnum_numbound0)
    {assume "length ?B' \<le> length ?A'"
    hence q:"q=?q" and "B = ?B'" and d:"d = ?d"
      using qBd by (auto simp add: Let_def unit_def)
    with BB' B_nb have b: "?N ` (set B) = ?N ` set (\<beta> q)" 
      and bn: "\<forall>b\<in> set B. numbound0 b" by simp+ 
  with pq_ex dp uq dd lq q d have ?thes by simp}
  moreover 
  {assume "\<not> (length ?B' \<le> length ?A')"
    hence q:"q=mirror ?q" and "B = ?A'" and d:"d = ?d"
      using qBd by (auto simp add: Let_def unit_def)
    with AA' mirror\<alpha>\<beta>[OF lq] A_nb have b:"?N ` (set B) = ?N ` set (\<beta> q)" 
      and bn: "\<forall>b\<in> set B. numbound0 b" by simp+
    from mirror_ex[OF lq] pq_ex q 
    have pqm_eq:"(\<exists> (x::int). ?I x p) = (\<exists> (x::int). ?I x q)" by simp
    from lq uq q mirror_l[where p="?q"]
    have lq': "iszlfm q" and uq: "d\<beta> q 1" by auto
    from \<delta>[OF lq'] mirror_\<delta>[OF lq] q d have dq:"d\<delta> q d " by auto
    from pqm_eq b bn uq lq' dp dq q dp d have ?thes by simp
  }
  ultimately show ?thes by blast
qed
    (* Cooper's Algorithm *)

constdefs cooper :: "fm \<Rightarrow> fm"
  "cooper p \<equiv> 
  (let (q,B,d) = unit p; js = iupt (1,d);
       mq = simpfm (minusinf q);
       md = evaldjf (\<lambda> j. simpfm (subst0 (C j) mq)) js
   in if md = T then T else
    (let qd = evaldjf (\<lambda> (b,j). simpfm (subst0 (Add b (C j)) q)) 
                               (allpairs Pair B js)
     in decr (disj md qd)))"
lemma cooper: assumes qf: "qfree p"
  shows "((\<exists> x. Ifm bbs (x#bs) p) = (Ifm bbs bs (cooper p))) \<and> qfree (cooper p)" 
  (is "(?lhs = ?rhs) \<and> _")
proof-

  let ?I = "\<lambda> x p. Ifm bbs (x#bs) p"
  let ?q = "fst (unit p)"
  let ?B = "fst (snd(unit p))"
  let ?d = "snd (snd (unit p))"
  let ?js = "iupt (1,?d)"
  let ?mq = "minusinf ?q"
  let ?smq = "simpfm ?mq"
  let ?md = "evaldjf (\<lambda> j. simpfm (subst0 (C j) ?smq)) ?js"
  let ?N = "\<lambda> t. Inum (i#bs) t"
  let ?qd = "evaldjf (\<lambda> (b,j). simpfm (subst0 (Add b (C j)) ?q)) (allpairs Pair ?B ?js)"
  have qbf:"unit p = (?q,?B,?d)" by simp
  from unit[OF qf qbf] have pq_ex: "(\<exists>(x::int). ?I x p) = (\<exists> (x::int). ?I x ?q)" and 
    B:"?N ` set ?B = ?N ` set (\<beta> ?q)" and 
    uq:"d\<beta> ?q 1" and dd: "d\<delta> ?q ?d" and dp: "?d > 0" and 
    lq: "iszlfm ?q" and 
    Bn: "\<forall> b\<in> set ?B. numbound0 b" by auto
  from zlin_qfree[OF lq] have qfq: "qfree ?q" .
  from simpfm_qf[OF minusinf_qfree[OF qfq]] have qfmq: "qfree ?smq".
  have jsnb: "\<forall> j \<in> set ?js. numbound0 (C j)" by simp
  hence "\<forall> j\<in> set ?js. bound0 (subst0 (C j) ?smq)" 
    by (auto simp only: subst0_bound0[OF qfmq])
  hence th: "\<forall> j\<in> set ?js. bound0 (simpfm (subst0 (C j) ?smq))"
    by (auto simp add: simpfm_bound0)
  from evaldjf_bound0[OF th] have mdb: "bound0 ?md" by simp 
  from Bn jsnb have "\<forall> (b,j) \<in> set (allpairs Pair ?B ?js). numbound0 (Add b (C j))"
    by (simp add: allpairs_set)
  hence "\<forall> (b,j) \<in> set (allpairs Pair ?B ?js). bound0 (subst0 (Add b (C j)) ?q)"
    using subst0_bound0[OF qfq] by blast
  hence "\<forall> (b,j) \<in> set (allpairs Pair ?B ?js). bound0 (simpfm (subst0 (Add b (C j)) ?q))"
    using simpfm_bound0  by blast
  hence th': "\<forall> x \<in> set (allpairs Pair ?B ?js). bound0 ((\<lambda> (b,j). simpfm (subst0 (Add b (C j)) ?q)) x)"
    by auto 
  from evaldjf_bound0 [OF th'] have qdb: "bound0 ?qd" by simp
  from mdb qdb 
  have mdqdb: "bound0 (disj ?md ?qd)" by (simp only: disj_def, cases "?md=T \<or> ?qd=T", simp_all)
  from trans [OF pq_ex cp_thm'[OF lq uq dd dp,where i="i"]] B
  have "?lhs = (\<exists> j\<in> {1.. ?d}. ?I j ?mq \<or> (\<exists> b\<in> ?N ` set ?B. Ifm bbs ((b+ j)#bs) ?q))" by auto
  also have "\<dots> = (\<exists> j\<in> {1.. ?d}. ?I j ?mq \<or> (\<exists> b\<in> set ?B. Ifm bbs ((?N b+ j)#bs) ?q))" by simp
  also have "\<dots> = ((\<exists> j\<in> {1.. ?d}. ?I j ?mq ) \<or> (\<exists> j\<in> {1.. ?d}. \<exists> b\<in> set ?B. Ifm bbs ((?N (Add b (C j)))#bs) ?q))" by (simp only: Inum.simps) blast
  also have "\<dots> = ((\<exists> j\<in> {1.. ?d}. ?I j ?smq ) \<or> (\<exists> j\<in> {1.. ?d}. \<exists> b\<in> set ?B. Ifm bbs ((?N (Add b (C j)))#bs) ?q))" by (simp add: simpfm) 
  also have "\<dots> = ((\<exists> j\<in> set ?js. (\<lambda> j. ?I i (simpfm (subst0 (C j) ?smq))) j) \<or> (\<exists> j\<in> set ?js. \<exists> b\<in> set ?B. Ifm bbs ((?N (Add b (C j)))#bs) ?q))"
    by (simp only: simpfm subst0_I[OF qfmq] iupt_set) auto
  also have "\<dots> = (?I i (evaldjf (\<lambda> j. simpfm (subst0 (C j) ?smq)) ?js) \<or> (\<exists> j\<in> set ?js. \<exists> b\<in> set ?B. ?I i (subst0 (Add b (C j)) ?q)))" 
   by (simp only: evaldjf_ex subst0_I[OF qfq])
 also have "\<dots>= (?I i ?md \<or> (\<exists> (b,j) \<in> set (allpairs Pair ?B ?js). (\<lambda> (b,j). ?I i (simpfm (subst0 (Add b (C j)) ?q))) (b,j)))"
   by (simp only: simpfm allpairs_set) blast
 also have "\<dots> = (?I i ?md \<or> (?I i (evaldjf (\<lambda> (b,j). simpfm (subst0 (Add b (C j)) ?q)) (allpairs Pair ?B ?js))))"
   by (simp only: evaldjf_ex[where bs="i#bs" and f="\<lambda> (b,j). simpfm (subst0 (Add b (C j)) ?q)" and ps="allpairs Pair ?B ?js"]) (auto simp add: split_def) 
 finally have mdqd: "?lhs = (?I i ?md \<or> ?I i ?qd)" by simp  
  also have "\<dots> = (?I i (disj ?md ?qd))" by (simp add: disj)
  also have "\<dots> = (Ifm bbs bs (decr (disj ?md ?qd)))" by (simp only: decr [OF mdqdb]) 
  finally have mdqd2: "?lhs = (Ifm bbs bs (decr (disj ?md ?qd)))" . 
  {assume mdT: "?md = T"
    hence cT:"cooper p = T" 
      by (simp only: cooper_def unit_def split_def Let_def if_True) simp
    from mdT have lhs:"?lhs" using mdqd by simp 
    from mdT have "?rhs" by (simp add: cooper_def unit_def split_def)
    with lhs cT have ?thesis by simp }
  moreover
  {assume mdT: "?md \<noteq> T" hence "cooper p = decr (disj ?md ?qd)" 
      by (simp only: cooper_def unit_def split_def Let_def if_False) 
    with mdqd2 decr_qf[OF mdqdb] have ?thesis by simp }
  ultimately show ?thesis by blast
qed

constdefs pa:: "fm \<Rightarrow> fm"
  "pa \<equiv> (\<lambda> p. qelim (prep p) cooper)"

theorem mirqe: "(Ifm bbs bs (pa p) = Ifm bbs bs p) \<and> qfree (pa p)"
  using qelim_ci cooper prep by (auto simp add: pa_def)
declare zdvd_iff_zmod_eq_0 [code]

code_module GeneratedCooper
file "generated_cooper.ML"
contains pa = "pa"
test = "%x . pa (E(A(Imp (Ge (Sub (Bound 0) (Bound 1))) (E(E(Eq(Sub(Add(Mul 3 (Bound 1)) (Mul 5 (Bound 0))) (Bound 2))))))))"

ML{* use "generated_cooper.ML"; 
     GeneratedCooper.test (); *}
use "coopereif.ML"
oracle linzqe_oracle ("term") = Coopereif.cooper_oracle
use"coopertac.ML"
setup "LinZTac.setup"

  (* Tests *)
lemma "\<exists> (j::int). \<forall> x\<ge>j. (\<exists> a b. x = 3*a+5*b)"
by cooper

lemma "ALL (x::int) >=8. EX i j. 5*i + 3*j = x" by cooper
theorem "(\<forall>(y::int). 3 dvd y) ==> \<forall>(x::int). b < x --> a \<le> x"
  by cooper

theorem "!! (y::int) (z::int) (n::int). 3 dvd z ==> 2 dvd (y::int) ==>
  (\<exists>(x::int).  2*x =  y) & (\<exists>(k::int). 3*k = z)"
  by cooper

theorem "!! (y::int) (z::int) n. Suc(n::nat) < 6 ==>  3 dvd z ==>
  2 dvd (y::int) ==> (\<exists>(x::int).  2*x =  y) & (\<exists>(k::int). 3*k = z)"
  by cooper

theorem "\<forall>(x::nat). \<exists>(y::nat). (0::nat) \<le> 5 --> y = 5 + x "
  by cooper

lemma "ALL (x::int) >=8. EX i j. 5*i + 3*j = x" by cooper 
lemma "ALL (y::int) (z::int) (n::int). 3 dvd z --> 2 dvd (y::int) --> (EX (x::int).  2*x =  y) & (EX (k::int). 3*k = z)" by cooper
lemma "ALL(x::int) y. x < y --> 2 * x + 1 < 2 * y" by cooper
lemma "ALL(x::int) y. 2 * x + 1 ~= 2 * y" by cooper
lemma "EX(x::int) y. 0 < x  & 0 <= y  & 3 * x - 5 * y = 1" by cooper
lemma "~ (EX(x::int) (y::int) (z::int). 4*x + (-6::int)*y = 1)" by cooper
lemma "ALL(x::int). (2 dvd x) --> (EX(y::int). x = 2*y)" by cooper
lemma "ALL(x::int). (2 dvd x) --> (EX(y::int). x = 2*y)" by cooper
lemma "ALL(x::int). (2 dvd x) = (EX(y::int). x = 2*y)" by cooper
lemma "ALL(x::int). ((2 dvd x) = (ALL(y::int). x ~= 2*y + 1))" by cooper
lemma "~ (ALL(x::int). ((2 dvd x) = (ALL(y::int). x ~= 2*y+1) | (EX(q::int) (u::int) i. 3*i + 2*q - u < 17) --> 0 < x | ((~ 3 dvd x) &(x + 8 = 0))))" by cooper
lemma "~ (ALL(i::int). 4 <= i --> (EX x y. 0 <= x & 0 <= y & 3 * x + 5 * y = i))" 
  by cooper
lemma "EX j. ALL (x::int) >= j. EX i j. 5*i + 3*j = x" by cooper

theorem "(\<forall>(y::int). 3 dvd y) ==> \<forall>(x::int). b < x --> a \<le> x"
  by cooper

theorem "!! (y::int) (z::int) (n::int). 3 dvd z ==> 2 dvd (y::int) ==>
  (\<exists>(x::int).  2*x =  y) & (\<exists>(k::int). 3*k = z)"
  by cooper

theorem "!! (y::int) (z::int) n. Suc(n::nat) < 6 ==>  3 dvd z ==>
  2 dvd (y::int) ==> (\<exists>(x::int).  2*x =  y) & (\<exists>(k::int). 3*k = z)"
  by cooper

theorem "\<forall>(x::nat). \<exists>(y::nat). (0::nat) \<le> 5 --> y = 5 + x "
  by cooper

theorem "\<forall>(x::nat). \<exists>(y::nat). y = 5 + x | x div 6 + 1= 2"
  by cooper

theorem "\<exists>(x::int). 0 < x"
  by cooper

theorem "\<forall>(x::int) y. x < y --> 2 * x + 1 < 2 * y"
  by cooper
 
theorem "\<forall>(x::int) y. 2 * x + 1 \<noteq> 2 * y"
  by cooper
 
theorem "\<exists>(x::int) y. 0 < x  & 0 \<le> y  & 3 * x - 5 * y = 1"
  by cooper

theorem "~ (\<exists>(x::int) (y::int) (z::int). 4*x + (-6::int)*y = 1)"
  by cooper

theorem "~ (\<exists>(x::int). False)"
  by cooper

theorem "\<forall>(x::int). (2 dvd x) --> (\<exists>(y::int). x = 2*y)"
  by cooper 

theorem "\<forall>(x::int). (2 dvd x) --> (\<exists>(y::int). x = 2*y)"
  by cooper 

theorem "\<forall>(x::int). (2 dvd x) = (\<exists>(y::int). x = 2*y)"
  by cooper 

theorem "\<forall>(x::int). ((2 dvd x) = (\<forall>(y::int). x \<noteq> 2*y + 1))"
  by cooper 

theorem "~ (\<forall>(x::int). 
            ((2 dvd x) = (\<forall>(y::int). x \<noteq> 2*y+1) | 
             (\<exists>(q::int) (u::int) i. 3*i + 2*q - u < 17)
             --> 0 < x | ((~ 3 dvd x) &(x + 8 = 0))))"
  by cooper
 
theorem "~ (\<forall>(i::int). 4 \<le> i --> (\<exists>x y. 0 \<le> x & 0 \<le> y & 3 * x + 5 * y = i))"
  by cooper

theorem "\<forall>(i::int). 8 \<le> i --> (\<exists>x y. 0 \<le> x & 0 \<le> y & 3 * x + 5 * y = i)"
  by cooper

theorem "\<exists>(j::int). \<forall>i. j \<le> i --> (\<exists>x y. 0 \<le> x & 0 \<le> y & 3 * x + 5 * y = i)"
  by cooper

theorem "~ (\<forall>j (i::int). j \<le> i --> (\<exists>x y. 0 \<le> x & 0 \<le> y & 3 * x + 5 * y = i))"
  by cooper

theorem "(\<exists>m::nat. n = 2 * m) --> (n + 1) div 2 = n div 2"
  by cooper

end
