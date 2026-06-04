model PrecisionInductor
  extends Modelica.Electrical.Analog.Interfaces.OnePort;

  // --- 1. 热接口 ---
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort 
    annotation (Placement(transformation(extent={{-10,-100},{10,-80}})));

  // --- 2. 参数定义 ---
  parameter Modelica.SIunits.Inductance L_nominal = 220e-6 "标称电感值";

  // 热相关参数 - 电阻部分
  parameter Modelica.SIunits.Resistance R_dc_ref = 0.05 "参考温度下的直流电阻";
  parameter Modelica.SIunits.Temperature T_ref = 298.15 "参考温度";
  parameter Real alpha_R = 0.00393 "铜的电阻温度系数";

  // 热相关参数 - 电感部分
  parameter Real alpha_L = -0.0005 "电感温度系数";

  parameter Modelica.SIunits.HeatCapacity C_thermal = 5.0 "电感热容";

  // --- 接口 ---
  // 输出实际电感值，方便连接到 Scope 进行对比
  Modelica.Blocks.Interfaces.RealOutput L_actual_out 
    annotation(Placement(transformation(extent={{100,50},{120,70}})));

  // --- 3. 内部变量 ---
  Modelica.SIunits.Voltage v_L;
  Modelica.SIunits.Voltage v_R;

  //当前实际物理值
  Modelica.SIunits.Resistance R_actual "当前实际电阻";
  Modelica.SIunits.Inductance L_actual "当前实际电感";

  Modelica.SIunits.Temperature T_core(start=T_ref, fixed=true) "线圈温度";
  Modelica.SIunits.Power P_loss "铜损功率";

equation
  // --- A. 热物理方程 ---
  T_core = heatPort.T;

  // 1. 电阻温漂
  R_actual = R_dc_ref * (1 + alpha_R * (T_core - T_ref));

  // 2. 电感温漂
  L_actual = L_nominal * (1 + alpha_L * (T_core - T_ref));

  // --- B. 接口输出 ---
  L_actual_out = L_actual;

  // --- C. 损耗与能量平衡 ---
  P_loss = i^2 * R_actual;
  C_thermal * der(T_core) = P_loss + heatPort.Q_flow;

  // --- D. 电路方程 ---
  v = v_L + v_R;

  v_L = L_actual * der(i);

  v_R = i * R_actual;

  annotation(
    defaultComponentName = "PrecisionInductor",
    Icon(
      coordinateSystem(extent = {{-100, -100}, {100, 100}}),
      graphics = {
        Line(points={{-100,0},{-60,0}}, color={0,0,255}, thickness=0.5),
        Line(points={{60,0},{100,0}}, color={0,0,255}, thickness=0.5),
        Line(points={{-60,0}, {-50,40}, {-40,0}, {-30,40}, {-20,0}, {-10,40}, {0,0}, {10,40}, {20,0}, {30,40}, {40,0}, {50,40}, {60,0}}, color={0,0,255}, smooth=Smooth.Bezier, thickness=0.5),
        Text(extent={{-100, 100}, {100, 50}}, textString="%name", lineColor={0, 0, 255}),
        Text(extent={{-40,-20},{40,-60}}, textString="Thermal L", lineColor={0,0,0}),
        Rectangle(extent={{-10,-80},{10,-100}}, fillColor={255,0,0}, fillPattern=FillPattern.Solid, lineColor={255,0,0})
      }
    )
  );
end PrecisionInductor;