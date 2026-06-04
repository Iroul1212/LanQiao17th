model AgingCapacitor
  extends Modelica.Electrical.Analog.Interfaces.OnePort;

  parameter Modelica.SIunits.Capacitance C_nominal = 330e-6;
  parameter Modelica.SIunits.Resistance ESR_initial = 0.025;
  parameter Real Time_Scale = 15768000.0 "时间加速因子 K_acc";

  // 物理退化先验参数
  parameter Real Ea_over_kB = 10908.0 "活化能与玻尔兹曼常数之比 [K]";
  parameter Real T_ref_K = 298.15 "基准健康温度 25°C [K]";
  parameter Real k_C_base = 1.27e-9 "基准容值衰减速率 [1/s]";
  parameter Real k_ESR_base = 4.40e-9 "基准ESR指数增长速率 [1/s]";

  // 热力学接口
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort 
    annotation (Placement(transformation(extent={{-10,90},{10,110}})));

  // 状态变量严格赋初值，防止 DAE 求解器在 t=0 时寻根发散
  Modelica.SIunits.Capacitance C_actual(start=330e-6, fixed=true);
  Modelica.SIunits.Resistance ESR_actual(start=0.025, fixed=true);
  Modelica.SIunits.Voltage v_c(start=0.0, fixed=true);
  Modelica.SIunits.Charge q(start=0.0, fixed=true);

  Real AF "实时热加速因子";
  Modelica.SIunits.Power P_loss "焦耳发热损耗";

equation
  // 1. 电热耦合
  P_loss = i^2 * ESR_actual;
  heatPort.Q_flow = -P_loss;

  // 2. 阿伦尼乌斯退化动力学
  AF = exp(Ea_over_kB * (1 / T_ref_K - 1 / heatPort.T));
  der(C_actual) = - k_C_base * C_nominal * AF * Time_Scale;
  der(ESR_actual) = k_ESR_base * ESR_actual * AF * Time_Scale;

  // 3.电荷守恒与基尔霍夫回路方程
  q = C_actual * v_c;
  i = der(q);
  v = v_c + i * ESR_actual;

  annotation(
    defaultComponentName = "agingCap",
    Icon(
      coordinateSystem(extent = {{-100, -100}, {100, 100}}),
      graphics = {
        Line(points = {{-100, 0}, {-10, 0}}, color = {0, 0, 255}, thickness = 0.5),
        Line(points = {{10, 0}, {100, 0}}, color = {0, 0, 255}, thickness = 0.5),
        Line(points = {{-10, 30}, {-10, -30}}, color = {0, 0, 255}, thickness = 0.5),
        Line(points = {{10, 30}, {10, -30}}, color = {0, 0, 255}, thickness = 0.5),
        Rectangle(extent = {{-12, 30}, {-8, -30}}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, lineThickness = 0),
        Rectangle(extent = {{8, 30}, {12, -30}}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, lineThickness = 0),
        Text(extent = {{-100, 80}, {100, 40}}, textString = "%name", lineColor = {0, 0, 255}),
        Rectangle(extent={{-10,90},{10,110}}, fillColor={191,0,0}, fillPattern=FillPattern.Solid, lineThickness=0)
      }
    )
  );
end AgingCapacitor;