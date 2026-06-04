block Full_BBO_Optimizer
  import Modelica.Blocks.Interfaces.*;
  import Modelica.Math.*;

  // 1. 输入接口
  RealInput v_out annotation(Placement(transformation(extent={{-120,50},{-100,70}})));
  RealInput i_L annotation(Placement(transformation(extent={{-120,-10},{-100,10}})));
  RealInput d annotation(Placement(transformation(extent={{-120,-70},{-100,-50}})));

  // 2. 输出接口
  RealOutput C_hat annotation(Placement(transformation(extent={{100,20},{120,40}})));
  RealOutput L_hat annotation(Placement(transformation(extent={{100,-40},{120,-20}})));

  // 3. 参数
  parameter Integer n_pop = 40;
  parameter Integer N_window = 300;
  parameter Real p_mutation = 0.01;
  parameter Real Ts = 2.0e-4;
  parameter Real Vin = 9.4;
  parameter Real R_load = 1.0;
  parameter Real J_threshold = 0.0001;

  parameter Real Weight_Voltage = 5.0;
  parameter Real V_D = 0.7 "二极管正向压降物理补偿";

  parameter Integer D = 4;
  parameter Real LB[4] = {100e-6, 50e-6,  0.001, 0.05};
  parameter Real UB[4] = {600e-6, 500e-6, 0.2,   0.3};

  parameter Real alpha = 0.05;

  protected
    discrete Real Pop[n_pop, D];
    discrete Real Pop_new[n_pop, D];
    discrete Real HSI[n_pop];
    discrete Integer HSI_Rank[n_pop];
    discrete Real mu[n_pop];
    discrete Real lambda[n_pop];

    discrete Real buf_v[N_window];
    discrete Real buf_i[N_window];
    discrete Real buf_d[N_window];

    // 注入初始值
    discrete Real C_smooth(start=330e-6, fixed=true);
    discrete Real L_smooth(start=220e-6, fixed=true);

    discrete Integer sample_count(start=0, fixed=true);
    discrete Boolean buffer_filled(start=false, fixed=true);
    discrete Real seed(start=111.0, fixed=true);

    Real pC, pL, pRc, pRs;
    Real A11, A12, A21, A22, B1_coeff, B2_coeff;
    Real tr, det, disc, sigma, omega;
    Real exp_st, cos_wt, sin_wt, term1, term2;
    Real Phi11, Phi12, Phi21, Phi22;
    Real u1_k, u2_k, V_sw_k;
    Real xp_1, xp_2, x0_1, x0_2, x_est_1, x_est_2;

    Real d_k, v_meas_prev, i_meas_prev;
    Real current_cost, min_cost_val;
    Real rand_val; Integer swap_temp, source_idx;
    Real total_lambda, acc_prob, rank_ratio;

    Real improved_pop[D], improved_cost;

  initial algorithm
    // 种群赋予优秀的物理先验初始值
    Pop[1, 1] := 330e-6; Pop[1, 2] := 220e-6;
    Pop[1, 3] := 0.025;  Pop[1, 4] := 0.12;
    HSI[1] := 0.0;
    for i in 2:n_pop loop
       for k in 1:D loop
          seed := seed * 16807.0; seed := seed - floor(seed/2147483647.0)*2147483647.0;
          Pop[i, k] := LB[k] + (UB[k] - LB[k]) * (seed / 2147483647.0);
       end for;
       HSI[i] := 1.0e20;
    end for;
    for i in 1:N_window loop buf_v[i]:=0; buf_i[i]:=0; buf_d[i]:=0; end for;

  algorithm
    when sample(0, Ts) then
      for k in 1:(N_window-1) loop
          buf_v[k] := buf_v[k+1]; buf_i[k] := buf_i[k+1]; buf_d[k] := buf_d[k+1];
      end for;
      buf_v[N_window] := v_out; buf_i[N_window] := i_L; buf_d[N_window] := d;

      sample_count := sample_count + 1;
      if sample_count >= N_window then buffer_filled := true; end if;

      if buffer_filled then
        for i in 1:n_pop loop
          pC := Pop[i, 1]; pL := Pop[i, 2]; pRc := Pop[i, 3]; pRs := Pop[i, 4];

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

          current_cost := 0;
          for k in 2:N_window loop
            d_k := buf_d[k-1]; v_meas_prev := buf_v[k-1]; i_meas_prev := buf_i[k-1];

            V_sw_k := (Vin + V_D) * d_k - V_D;
            u1_k := B1_coeff * V_sw_k;
            u2_k := B2_coeff * V_sw_k;

            xp_1 := (A12*u2_k - A22*u1_k)/det;
            xp_2 := (A21*u1_k - A11*u2_k)/det;

            x0_1 := v_meas_prev - xp_1; x0_2 := i_meas_prev - xp_2;
            x_est_1 := Phi11*x0_1 + Phi12*x0_2 + xp_1;
            x_est_2 := Phi21*x0_1 + Phi22*x0_2 + xp_2;

            current_cost := current_cost + ((x_est_1 - buf_v[k])*Weight_Voltage)^2 + (x_est_2 - buf_i[k])^2;
          end for;
          HSI[i] := current_cost;
        end for;

        for i in 1:n_pop loop HSI_Rank[i] := i; end for;
        for i in 1:(n_pop-1) loop
          for j in 1:(n_pop-i) loop
              if HSI[HSI_Rank[j]] > HSI[HSI_Rank[j+1]] then
                 swap_temp := HSI_Rank[j]; HSI_Rank[j] := HSI_Rank[j+1]; HSI_Rank[j+1] := swap_temp;
              end if;
          end for;
        end for;
        min_cost_val := HSI[HSI_Rank[1]];

        if min_cost_val > J_threshold then
            for k in 1:n_pop loop
               rank_ratio := (n_pop - k + 1.0) / (n_pop + 1.0);
               mu[HSI_Rank[k]] := rank_ratio; lambda[HSI_Rank[k]] := 1.0 - rank_ratio;
            end for;
            Pop_new := Pop;
            for i in 1:n_pop loop
               seed := seed * 16807.0; seed := seed - floor(seed/2147483647.0)*2147483647.0; rand_val := seed / 2147483647.0;
               if rand_val < lambda[i] then
                  total_lambda := 0;
                  for j in 1:n_pop loop total_lambda := total_lambda + mu[j]; end for;
                  seed := seed * 16807.0; seed := seed - floor(seed/2147483647.0)*2147483647.0; rand_val := (seed / 2147483647.0) * total_lambda;
                  acc_prob := 0; source_idx := 1;
                  for j in 1:n_pop loop
                      acc_prob := acc_prob + mu[j];
                      if rand_val <= acc_prob then source_idx := j; break; end if;
                  end for;
                  for k in 1:D loop Pop_new[i, k] := Pop[i, k] + lambda[i] * (Pop[source_idx, k] - Pop[i, k]); end for;
               end if;
            end for;
            for i in 1:n_pop loop
                if i <> HSI_Rank[1] then
                  for k in 1:D loop
                     seed := seed * 16807.0; seed := seed - floor(seed/2147483647.0)*2147483647.0; rand_val := seed / 2147483647.0;
                     if rand_val < p_mutation then
                        seed := seed * 16807.0; seed := seed - floor(seed/2147483647.0)*2147483647.0;
                        Pop_new[i, k] := LB[k] + (UB[k] - LB[k]) * (seed / 2147483647.0);
                     end if;
                  end for;
                end if;
            end for;
            Pop := Pop_new;
        end if;

        (improved_pop, improved_cost) := LocalSearch_Pattern(
            Pop[HSI_Rank[1], :], min_cost_val, LB, UB,
            buf_v, buf_i, buf_d, Vin, R_load, Ts
        );
        Pop[HSI_Rank[1], :] := improved_pop;

        // 平滑 C 和 L
        C_smooth := (1 - alpha) * C_smooth + alpha * Pop[HSI_Rank[1], 1];
        L_smooth := (1 - alpha) * L_smooth + alpha * Pop[HSI_Rank[1], 2];
      end if;
    end when;

    C_hat := C_smooth;
    L_hat := L_smooth;

  annotation (Icon(graphics={
    Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,128}, fillColor={255,255,240}, fillPattern=FillPattern.Solid),
    Text(extent={{-90,70},{90,20}}, textString="BBO-Solver", lineColor={0,0,128}),
    Text(extent={{-90,-20},{90,-70}}, textString="C & L Out", lineColor={0,128,0})
  }));
end Full_BBO_Optimizer;