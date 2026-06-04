block HighFreq_Rc_Observer
  import Modelica.Blocks.Interfaces.*;
  import Modelica.Math.*;

  RealInput v_out annotation(Placement(transformation(extent={{-120,20},{-100,40}})));
  RealInput i_L annotation(Placement(transformation(extent={{-120,-40},{-100,-20}})));

  RealOutput Rc_hat(start=0.025, fixed=true) annotation(Placement(transformation(extent={{100,-10},{120,10}})));

  parameter Real R_load = 1.0 "负载阻抗先验参数 [Ohm]";
  parameter Real f_hp = 2000.0 "一阶高通滤波器截止频率 [Hz]";
  parameter Real f_lp = 100.0 "一阶低通提取滤波器截止频率 [Hz]";
  parameter Real Rc_initial = 0.025 "电容标称 ESR 初始参考值";

  protected
  Real w_hp = 2 * Modelica.Constants.pi * f_hp;
  Real w_lp = 2 * Modelica.Constants.pi * f_lp;

  Real i_C "流入电容支路的真实电流";

  // HPF 状态变量
  Real v_hp_state(start=3.3, fixed=true);
  Real i_hp_state(start=0.0, fixed=true);
  Real v_ac;
  Real i_ac;

  // 瞬时与平均功率状态
  Real p_inst;
  Real i_sq_inst;

  // 积分器初值
  Real P_avg(start=0.0001, fixed=true);
  Real I_sq_avg(start=0.004, fixed=true);

  Real Rc_raw;

equation
  i_C = i_L - v_out / R_load;

  der(v_hp_state) = w_hp * (v_out - v_hp_state);
  v_ac = v_out - v_hp_state;

  der(i_hp_state) = w_hp * (i_C - i_hp_state);
  i_ac = i_C - i_hp_state;

  p_inst = v_ac * i_ac;
  i_sq_inst = i_ac * i_ac;

  der(P_avg) = w_lp * (p_inst - P_avg);
  der(I_sq_avg) = w_lp * (i_sq_inst - I_sq_avg);

  Rc_raw = if I_sq_avg > 1e-8 then P_avg / I_sq_avg else Rc_initial;

  der(Rc_hat) = 10.0 * (Rc_raw - Rc_hat);

  annotation (Icon(graphics={
    Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,128}, fillColor={240,255,240}, fillPattern=FillPattern.Solid),
    Text(extent={{-90,50},{90,10}}, textString="HF-Ripple", lineColor={0,0,128}),
    Text(extent={{-90,-10},{90,-50}}, textString="Observer", lineColor={191,0,0})
  }));
end HighFreq_Rc_Observer;