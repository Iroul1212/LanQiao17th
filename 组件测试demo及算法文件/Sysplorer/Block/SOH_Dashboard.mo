block SOH_Dashboard // SOH健康度实时计算仪表盘
  import Modelica.Blocks.Interfaces.*;

  // 接口定义
  // 输入：接收滤波后的电容值和电阻值
  RealInput C_current annotation(Placement(transformation(extent={{-120,60},{-80,100}})));
  RealInput Ron_current annotation(Placement(transformation(extent={{-120,-100},{-80,-60}})));

  // 输出：计算出的 0~100 分数
  RealOutput SOH_C annotation(Placement(transformation(extent={{100,50},{120,70}})));
  RealOutput SOH_R annotation(Placement(transformation(extent={{100,-70},{120,-50}})));

  // 参数设置
  parameter Real C_nominal = 220e-6 "出厂额定电容";
  parameter Real Ron_nominal = 0.05 "出厂额定电阻";

  // 寿命终止阈值 (EOL - End of Life)
  parameter Real C_eol_ratio = 0.8;
  parameter Real Ron_eol_ratio = 2.0;

  // 内部临时变量
  protected
    Real raw_soh_c;
    Real raw_soh_r;

algorithm
  // 计算逻辑

  // 电容健康度
  raw_soh_c := 100 * (C_current - C_nominal * C_eol_ratio) / (C_nominal * (1 - C_eol_ratio));

  // 电阻健康度
  raw_soh_r := 100 * (Ron_nominal * Ron_eol_ratio - Ron_current) / (Ron_nominal * (Ron_eol_ratio - 1));

  // 限幅保护

  if raw_soh_c > 100 then
    SOH_C := 100;
  elseif raw_soh_c < 0 then
    SOH_C := 0;
  else
    SOH_C := raw_soh_c;
  end if;

  if raw_soh_r > 100 then
    SOH_R := 100;
  elseif raw_soh_r < 0 then
    SOH_R := 0;
  else
    SOH_R := raw_soh_r;
  end if;

  annotation (
    Icon(graphics={

      Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,255}, fillColor={235,245,255}, fillPattern=FillPattern.Solid),

      Text(extent={{-90,90},{90,50}}, textString="SOH Monitor", lineColor={0,0,255}),

      Ellipse(extent={{-80,40},{-20,0}}, lineColor={0,128,0}, thickness=1), // 绿圈
      Text(extent={{-80,20},{-20,0}}, textString="C %", lineColor={0,128,0}),
      Text(extent={{0,40},{80,0}}, textString="%SOH_C", lineColor={0,0,0}), // 动态显示数值占位符

      Ellipse(extent={{-80,-10},{-20,-50}}, lineColor={255,0,0}, thickness=1), // 红圈
      Text(extent={{-80,-30},{-20,-50}}, textString="R %", lineColor={255,0,0}),
      Text(extent={{0,-10},{80,-50}}, textString="%SOH_R", lineColor={0,0,0})
    })
  );
end SOH_Dashboard;