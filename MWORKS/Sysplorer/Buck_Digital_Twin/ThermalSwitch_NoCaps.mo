model ThermalSwitch_NoCaps
  extends Modelica.Electrical.Analog.Interfaces.OnePort;

  // --- 1. 接口定义 ---
  Modelica.Electrical.Analog.Interfaces.Pin G "栅极驱动" 
    annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort 
    annotation (Placement(transformation(extent={{30,30},{50,50}})));

  // --- 2. 参数定义 ---
  parameter Real R_th[3] = {0.1, 0.5, 2.0} "Foster热阻";
  parameter Real C_th[3] = {0.001, 0.05, 10.0} "Foster热容";
  parameter Real R_on_25 = 0.05 "25度导通电阻";
  parameter Real R_off = 1e5 "关断电阻";
  parameter Real alpha = 0.006 "温度系数";
  parameter Real V_th = 2.5 "开启阈值电压";

  // --- 3. 内部变量 ---
  Real R_channel "当前沟道电阻";
  Real T_j "结温";
  Real T_nodes[3](start={298.15, 298.15, 298.15});
  Real P_loss "热损耗功率";
  Real v_gs;

equation
  // 电压检测
  v_gs = G.v - n.v;

  // --- 物理方程 ---
  T_j = T_nodes[1];
  heatPort.T = T_nodes[3];

  if v_gs > V_th then
      R_channel = R_on_25 * (1 + alpha * (T_j - 298.15));
  else
      R_channel = R_off;
  end if;

  // --- 电路方程 ---
  v = i * R_channel;

  // --- 损耗与热网络 ---
  P_loss = v * i;
  C_th[1] * der(T_nodes[1]) = P_loss - (T_nodes[1] - T_nodes[2])/R_th[1];
  C_th[2] * der(T_nodes[2]) = (T_nodes[1] - T_nodes[2])/R_th[1] - (T_nodes[2] - T_nodes[3])/R_th[2];
  C_th[3] * der(T_nodes[3]) = (T_nodes[2] - T_nodes[3])/R_th[2] + heatPort.Q_flow;

  annotation (
    Icon(graphics={
      Ellipse(extent={{-100,-10},{-90,10}}, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid),
      Ellipse(extent={{90,-10},{100,10}}, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid),
      Line(points={{-95,0},{-60,0}}, color={0,0,255}),
      Line(points={{60,0},{95,0}}, color={0,0,255}),
      Line(points={{-60,0},{40,50}}, color={0,0,0}, thickness=1),
      Line(points={{0,-100},{0,-20}}, color={0,128,0}, pattern=LinePattern.Dash),
      Text(extent={{5,-80},{40,-100}}, textString="G", lineColor={0,128,0}),
      Text(extent={{-100,100},{100,60}}, textString="%name", lineColor={0,0,255}),
      Rectangle(extent={{35,35},{45,45}}, fillColor={255,0,0}, fillPattern=FillPattern.Solid),
      Text(extent={{50,55},{100,35}}, textString="Heat", lineColor={255,0,0})
    })
  );
end ThermalSwitch_NoCaps;