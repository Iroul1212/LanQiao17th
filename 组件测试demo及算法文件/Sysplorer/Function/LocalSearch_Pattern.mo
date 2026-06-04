function LocalSearch_Pattern
  import Modelica.Math.*;

  input Real pop_in[4];
  input Real cost_in; input Real LB[4]; input Real UB[4];
  input Real buf_v[:]; input Real buf_i[:]; input Real buf_d[:];
  input Real Vin; input Real R_load; input Real Ts;
  output Real pop_out[4]; output Real cost_out;

protected
  Integer N;
  Real trial_pop[4], trial_cost, pC, pL, pRc, pRs, A11, A12, A21, A22, B1_coeff, B2_coeff, tr, det, disc, sigma, omega;
  Real exp_st, cos_wt, sin_wt, term1, term2, Phi11, Phi12, Phi21, Phi22, xp[2], x0[2], x_est[2];
  Integer k, iter, param_idx;
  Real u1_k, u2_k, V_sw_k;

  Real relative_step_ratio = 0.05;
  Real current_step_scale;
  Real step_val;
  Boolean improved;
  Integer max_iter = 100;

  Real W_v = 5.0;
  Real V_D = 0.7;

algorithm
  N := size(buf_v, 1);
  pop_out := pop_in; cost_out := cost_in;
  current_step_scale := 1.0;

  for iter in 1:max_iter loop
    improved := false;

    // 正交局部搜索
    for param_idx in 1:4 loop
      step_val := max(pop_out[param_idx] * relative_step_ratio, 1e-9) * current_step_scale;

      // === 方向 1: +step ===
      trial_pop := pop_out;
      trial_pop[param_idx] := min(UB[param_idx], trial_pop[param_idx] + step_val);

      pC:=trial_pop[1]; pL:=trial_pop[2]; pRc:=trial_pop[3]; pRs:=trial_pop[4];

      B1_coeff := (R_load * pRc) / (pL * (R_load + pRc));
      B2_coeff := 1.0 / pL;

      A11 := -1.0/(pC*(R_load+pRc));
      A12 := R_load/(pC*(R_load+pRc));
      A21 := -R_load/(pL*(R_load+pRc));
      A22 := -(pRs+(pRc*R_load)/(R_load+pRc))/pL;

      tr := A11+A22; det := A11*A22-A12*A21; disc := tr*tr-4*det;
      if disc < 0 then
        sigma := tr/2.0; omega := sqrt(abs(disc))/2.0;
        exp_st := exp(sigma*Ts); cos_wt := cos(omega*Ts); sin_wt := sin(omega*Ts);
        term1 := exp_st*cos_wt; term2 := exp_st*sin_wt/omega;
        Phi11 := term1+term2*(A11-sigma); Phi12 := term2*A12;
        Phi21 := term2*A21; Phi22 := term1+term2*(A22-sigma);
      else
        Phi11 := 1.0+A11*Ts; Phi12 := A12*Ts; Phi21 := A21*Ts; Phi22 := 1.0+A22*Ts;
      end if;

      trial_cost := 0;
      for k in 2:N loop
         V_sw_k := (Vin + V_D) * buf_d[k-1] - V_D;
         u1_k := B1_coeff * V_sw_k;
         u2_k := B2_coeff * V_sw_k;

         xp[1] := (A12*u2_k - A22*u1_k)/det;
         xp[2] := (A21*u1_k - A11*u2_k)/det;

         x0[1] := buf_v[k-1] - xp[1]; x0[2] := buf_i[k-1] - xp[2];
         x_est[1] := Phi11*x0[1] + Phi12*x0[2] + xp[1]; x_est[2] := Phi21*x0[1] + Phi22*x0[2] + xp[2];
         trial_cost := trial_cost + ((x_est[1] - buf_v[k])*W_v)^2 + (x_est[2] - buf_i[k])^2;
      end for;

      if trial_cost < cost_out then
         pop_out := trial_pop; cost_out := trial_cost; improved := true;
      else
         // === 方向 2: -step ===
         trial_pop[param_idx] := max(LB[param_idx], pop_out[param_idx] - step_val);

         pC:=trial_pop[1]; pL:=trial_pop[2]; pRc:=trial_pop[3]; pRs:=trial_pop[4];

         B1_coeff := (R_load * pRc) / (pL * (R_load + pRc));
         B2_coeff := 1.0 / pL;

         A11 := -1.0/(pC*(R_load+pRc));
         A12 := R_load/(pC*(R_load+pRc));
         A21 := -R_load/(pL*(R_load+pRc)); A22 := -(pRs+(pRc*R_load)/(R_load+pRc))/pL;

         tr := A11+A22; det := A11*A22-A12*A21; disc := tr*tr-4*det;
         if disc < 0 then
            sigma := tr/2.0; omega := sqrt(abs(disc))/2.0;
            exp_st := exp(sigma*Ts); cos_wt := cos(omega*Ts); sin_wt := sin(omega*Ts);
            term1 := exp_st*cos_wt; term2 := exp_st*sin_wt/omega;
            Phi11 := term1+term2*(A11-sigma); Phi12 := term2*A12;
            Phi21 := term2*A21; Phi22 := term1+term2*(A22-sigma);
         else
            Phi11 := 1.0+A11*Ts; Phi12 := A12*Ts; Phi21 := A21*Ts; Phi22 := 1.0+A22*Ts;
         end if;

         trial_cost := 0;
         for k in 2:N loop
            V_sw_k := (Vin + V_D) * buf_d[k-1] - V_D;
            u1_k := B1_coeff * V_sw_k;
            u2_k := B2_coeff * V_sw_k;

            xp[1] := (A12*u2_k - A22*u1_k)/det;
            xp[2] := (A21*u1_k - A11*u2_k)/det;

            x0[1] := buf_v[k-1] - xp[1]; x0[2] := buf_i[k-1] - xp[2];
            x_est[1] := Phi11*x0[1] + Phi12*x0[2] + xp[1]; x_est[2] := Phi21*x0[1] + Phi22*x0[2] + xp[2];
            trial_cost := trial_cost + ((x_est[1] - buf_v[k])*W_v)^2 + (x_est[2] - buf_i[k])^2;
         end for;
         if trial_cost < cost_out then pop_out := trial_pop; cost_out := trial_cost; improved := true; end if;
      end if;
    end for;

    if not improved then
       current_step_scale := current_step_scale * 0.5;
       if current_step_scale < 1e-3 then break; end if;
    end if;
  end for;
end LocalSearch_Pattern;