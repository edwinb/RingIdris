-- Edwin Brady, Franck Slama
-- University of St Andrews
-- File semiGroup_reduce.idr
-- Normalize an expression reflecting an element in a semi-group
-------------------------------------------------------------------

module semiGroup_reduce

import Decidable.Equality
import dataTypes
import magma_reduce
import tools


--%default total


-- Normalization
-- No longer possible to tag this function as total due to fixed point to reach (non structural recursivity) (see last lines of the function)
assoc : (p:SemiGroup c) -> (neg:c->c) -> (g:Vect n c) -> {c1:c} -> (ExprSG p neg g c1) -> (c2 ** (ExprSG p neg g c2, c1=c2))
assoc p neg g (ConstSG _ _ _ const) = (_ ** (ConstSG _ _ _ const, refl))
assoc p neg g (VarSG _ _ v) = (_ ** (VarSG _ _ v, refl))
-- (x + c1) + (c2 + y) -> (x + (res c1+c2)) + y
assoc p neg g (PlusSG _ (PlusSG _ e1 (ConstSG _ _ _ c1)) (PlusSG _ (ConstSG _ _ _ c2) e2)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = (assoc p neg g e1) in
    let (r_ih2 ** (e_ih2, p_ih2)) = (assoc p neg g e2) in
    let (r_3 ** (e_3, p_3)) = magmaReduce (semiGroup_to_magma {p=p} {neg=neg} {g=g} (PlusSG _ (ConstSG _ _ _ c1) (ConstSG _ _ _ c2))) in
    let e_3' = magma_to_semiGroup p e_3 in
    (_ ** ((PlusSG _ (PlusSG _ e_ih1 e_3') e_ih2), ?Massoc1))
-- (x + c1) + c2 -> x + (res c1+c2)
assoc p neg g (PlusSG _ (PlusSG _ e1 (ConstSG _ _ _ c1)) (ConstSG _ _ _ c2)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = (assoc p neg g e1) in
    let (r_2 ** (e_2, p_2)) = magmaReduce (semiGroup_to_magma {p=p} {neg=neg} {g=g} (PlusSG _ (ConstSG _ _ _ c1) (ConstSG _ _ _ c2))) in
    let e_2' = magma_to_semiGroup p e_2 in
    (_ ** ((PlusSG _ e_ih1 e_2'), ?Massoc2))
-- c1 + (c2 + x) -> (res c1 +c c2) + x
assoc p neg g (PlusSG _ (ConstSG _ _ _ c1) (PlusSG _ (ConstSG _ _ _ c2) e1)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = (assoc p neg g e1) in
    let (r_2 ** (e_2, p_2)) = magmaReduce (semiGroup_to_magma {p=p} {neg=neg} {g=g} (PlusSG _ (ConstSG _ _ _ c1) (ConstSG _ _ _ c2))) in
    let e_2' = magma_to_semiGroup p e_2 in
    (_ ** ((PlusSG _ e_2' e_ih1), ?Massoc3))
assoc p neg g (PlusSG _ e1 e2) =
    let (r_ih1 ** (e_ih1, p_ih1)) = (assoc p neg g e1) in
    let (r_ih2 ** (e_ih2, p_ih2)) = (assoc p neg g e2) in
    let (r_3 ** (e_3, p_3)) = magmaReduce (semiGroup_to_magma {p=p} {neg=neg} {g=g} e1) in
    let (r_4 ** (e_4, p_4)) = magmaReduce (semiGroup_to_magma {p=p} {neg=neg} {g=g} e2) in
    let e_3' = magma_to_semiGroup p e_3 in
    let e_4' = magma_to_semiGroup p e_4 in
        case (exprSG_eq p neg g (PlusSG _ e1 e2) (PlusSG _ e_3' e_4')) of
        Just _ => (_ ** ((PlusSG _ e_3' e_4'), ?Massoc4)) -- Fixed point reached
        Nothing => let (r_final ** (e_final, p_final)) = assoc p neg g (PlusSG _ e_3' e_4') in -- Need to continue
                    (_ ** (e_final, ?Massoc5))


total
addAfter : (p:SemiGroup c) -> (neg:c->c) -> (g:Vect n c) -> {c1:c} -> {c2:c} -> (ExprSG p neg g c1) -> (ExprSG p neg g c2) -> (c3 ** (ExprSG p neg g c3, c3=Plus c1 c2))
addAfter p neg g (ConstSG _ _ _ c1) e = (_ ** (PlusSG _ (ConstSG _ _ _ c1) e, refl))
addAfter p neg g (VarSG _ _ v) e = (_ ** (PlusSG _ (VarSG _ _ v) e, refl))
addAfter p neg g (PlusSG _ e11 e12) e2 = 
    let (r_ih1 ** (e_ih1, p_ih1)) = addAfter p neg g e12 e2
        in (_ ** (PlusSG _ e11 e_ih1, ?MaddAfter1))


-- Transforms an expression in the form x + (y + (z + ...))
-- can't be tagged as total (non structural recursion)
shuffleRight : (p:SemiGroup c) -> (neg:c->c) -> (g:Vect n c) -> {c1:c} -> (ExprSG p neg g c1) -> (c2 ** (ExprSG p neg g c2, c1=c2))
shuffleRight p neg g (ConstSG _ _ _ c) = (_ ** (ConstSG _ _ _ c, refl))
shuffleRight p neg g (VarSG _ _ v) = (_ ** (VarSG _ _ v, refl))

shuffleRight p neg g (PlusSG _ (ConstSG _ _ _ c1) (ConstSG _ _ _ c2)) = (_ ** (PlusSG _ (ConstSG _ _ _ c1) (ConstSG _ _ _ c2), refl))
shuffleRight p neg g (PlusSG _ (ConstSG _ _ _ c1) (VarSG _ _ v)) = (_ ** (PlusSG _ (ConstSG _ _ _ c1) (VarSG _ _ v), refl))
shuffleRight p neg g (PlusSG _ (ConstSG _ _ _ c1) (PlusSG _ e21 e22)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = shuffleRight p neg g (PlusSG _ e21 e22) in
    (_ ** (PlusSG _ (ConstSG _ _ _ c1) e_ih1, ?MshuffleRight1))
    -- Previously : PlusSG (ConstSG c1) (addAfter (shuffleRight p21) (shuffleRight p22))

shuffleRight p neg g (PlusSG _ (VarSG _ _ v1) (ConstSG _ _ _ c2)) = (_ ** (PlusSG _ (VarSG _ _ v1) (ConstSG _ _ _ c2), refl))
shuffleRight p neg g (PlusSG _ (VarSG _ _ v1) (VarSG _ _ v2)) = (_ ** (PlusSG _ (VarSG _ _ v1) (VarSG _ _ v2), refl))
shuffleRight p neg g (PlusSG _ (VarSG _ _ v1) (PlusSG _ e21 e22)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = shuffleRight p neg g (PlusSG _ e21 e22) in
    (_ ** (PlusSG _ (VarSG _ _ v1) e_ih1, ?MshuffleRight2))
    -- PlusSG (VarSG v1) (addAfter (shuffleRight p21) (shuffleRight p22)) -- ok with me
    
shuffleRight p neg g (PlusSG _ (PlusSG _ e11 e12) (ConstSG _ _ _ c2)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = shuffleRight p neg g (PlusSG _ e11 e12) in
    let (r_2 ** (e_2, p_2)) = addAfter p neg g e_ih1 (ConstSG _ _ _ c2) in
    (_ ** (e_2, ?MshuffleRight3))
shuffleRight p neg g (PlusSG _ (PlusSG _ e11 e12) (VarSG _ _ v2)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = shuffleRight p neg g (PlusSG _ e11 e12) in
    let (r_2 ** (e_2, p_2)) = addAfter p neg g e_ih1 (VarSG _ _ v2) in
    (_ ** (e_2, ?MshuffleRight4))
shuffleRight p neg g (PlusSG _ (PlusSG _ e11 e12) (PlusSG _ e21 e22)) =
    let (r_ih1 ** (e_ih1, p_ih1)) = shuffleRight p neg g (PlusSG _ e11 e12) in
    let (r_ih2 ** (e_ih2, p_ih2)) = shuffleRight p neg g (PlusSG _ e21 e22) in
    let (r_3 ** (e_3, p_3)) = addAfter p neg g e_ih1 e_ih2 in
    (_ ** (e_3, ?MshuffleRight5))
    -- Previously : addAfter (addAfter (shuffleRight p11) (shuffleRight p12)) (addAfter (shuffleRight p21) (shuffleRight p22))
    -- Note : equivalent to "addAfter (addAfter (addAfter (shuffleRight p11) (shuffleRight p12)) (shuffleRight p21)) (shuffleRight p22)"


semiGroupReduce : (p:SemiGroup c) -> {neg:c->c} -> {g:Vect n c} -> {c1:c} -> (ExprSG p neg g c1) -> (c2 ** (ExprSG p neg g c2, c1=c2))
semiGroupReduce p e =
    let (r_assoc ** (e_assoc, p_assoc)) = assoc p _ _ e in
    let (r_shuffle ** (e_shuffle, p_shuffle)) = shuffleRight p _ _ e_assoc in
    (_ ** (e_shuffle, ?MsemiGroupReduce1))


total
buildProofSemiGroup : (p:SemiGroup c) -> {neg:c->c} -> {g:Vect n c} -> {x : c} -> {y : c} -> {c1:c} -> {c2:c} -> (ExprSG p neg g c1) -> (ExprSG p neg g c2) -> (x = c1) -> (y = c2) -> (Maybe (x = y))
buildProofSemiGroup p e1 e2 lp rp with (exprSG_eq p _ _ e1 e2)
    buildProofSemiGroup p e1 e1 lp rp | Just refl = ?MbuildProofSemiGroup
    buildProofSemiGroup p e1 e2 lp rp | Nothing = Nothing


semiGroupDecideEq : (p:SemiGroup c) -> {neg:c->c} -> {g:Vect n c} -> (ExprSG p neg g x) -> (ExprSG p neg g y) -> Maybe (x = y)
-- e1 is the left side, e2 is the right side
semiGroupDecideEq p e1 e2 =
    let (r_e1 ** (e_e1, p_e1)) = semiGroupReduce p e1 in
    let (r_e2 ** (e_e2, p_e2)) = semiGroupReduce p e2 in
    buildProofSemiGroup p e_e1 e_e2 p_e1 p_e2
                


---------- Proofs ----------
semiGroup_reduce.Massoc1 = proof {
  intros;
  rewrite p_ih1;
  rewrite p_ih2;
  rewrite p_3;
  rewrite semiGroupAssoc_4terms c p c1 c2 c4 c3;
  trivial;
}

semiGroup_reduce.Massoc2 = proof {
  intros;
  rewrite p_ih1 ;
  rewrite p_2;
  mrefine Plus_assoc;
}

semiGroup_reduce.Massoc3 = proof {
  intros;
  rewrite p_ih1 ;
  rewrite p_2;
  rewrite (sym (Plus_assoc c1 c3 c2));
  trivial;
}

semiGroup_reduce.Massoc4 = proof {
  intros;
  rewrite p_3;
  rewrite p_4;
  trivial;
}

semiGroup_reduce.Massoc5 = proof {
  intros;
  rewrite p_final ;
  rewrite p_3;
  rewrite p_4;
  trivial;
}

semiGroup_reduce.MaddAfter1 = proof {
  intros;
  rewrite (sym p_ih1);
  rewrite (Plus_assoc c1 c3 c2);
  trivial;
}

semiGroup_reduce.MshuffleRight1 = proof {
  intros;
  rewrite p_ih1 ;
  trivial;
}

semiGroup_reduce.MshuffleRight2 = proof {
  intros;
  rewrite p_ih1 ;
  trivial;
}

semiGroup_reduce.MshuffleRight3 = proof {
  intros;
  rewrite p_2;
  rewrite (sym p_2);
  rewrite p_ih1 ;
  trivial;
}

semiGroup_reduce.MshuffleRight4 = proof {
  intros;
  rewrite p_2;
  rewrite (sym p_2);
  rewrite p_ih1 ;
  trivial;
}

semiGroup_reduce.MshuffleRight5 = proof {
  intros;
  rewrite (sym p_3);
  rewrite p_ih1;
  rewrite p_ih2;
  trivial;
}

semiGroup_reduce.MsemiGroupReduce1 = proof {
  intros;
  rewrite p_shuffle ;
  rewrite p_assoc ;
  trivial;
}

semiGroup_reduce.MbuildProofSemiGroup = proof {
  intros;
  rewrite (sym lp);
  rewrite (sym rp);
  mrefine Just;
  trivial;
}






















