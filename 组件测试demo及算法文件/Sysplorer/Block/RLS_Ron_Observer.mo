block RLS_Ron_Observer // 导通电阻辨识器
  import Modelica.Blocks.Interfaces.*;

  // 端口定义
  RealInput v_sw annotation(Placement(transformation(extent = {{-120, 60}, {-80, 100}}), iconTransformation(extent = {{-120, 60}, {-80, 100}})));
  RealInput i_L annotation(Placement(transformation(extent = {{-120, -20}, {-80, 20}}), iconTransformation(extent = {{-120, -20}, {-80, 20}})));
  RealInput gate_signal annotation(Placement(transformation(extent = {{-120, -100}, {-80, -60}}), iconTransformation(extent = {{-120, -100}, {-80, -60}})));

  RealOutput Ron_hat annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}), iconTransformation(extent = {{100, -10}, {120, 10}})));

  // 参数设置
  parameter Real Vin_known = 24 "输入电压";

  // 采样周期
  parameter Real samplePeriod = 1e-6;

  parameter Real lambda = 0.999 "遗忘因子";

  // 初始值
  parameter Real init_R = 0.05;
  parameter Real init_P = 10;

  // 内部变量
  protected
    discrete Real theta(start = init_R, fixed = true);
    discrete Real P(start = init_P, fixed = true);
    Real phi;
    Real y_meas;
    Real K;
    Real prediction_error;
    Real delta_theta;
    Boolean sampleTrigger;
    Boolean is_conducting;
    Real v_drop; // 辅助变量：MOS管压降

  algorithm
    sampleTrigger := sample(0, samplePeriod);

    when sampleTrigger then
      is_conducting := gate_signal > 2.5;

      // 计算压降
      v_drop := Vin_known - v_sw;

      // 核心判断逻辑
      if is_conducting and abs(i_L) > 0.5 and v_drop < 1.5 then

        // RLS 计算
        y_meas := v_drop; // 观测值就是压降
        phi := i_L;       // 回归向量就是电流

        K := (P * phi) / (lambda + phi * P * phi);
        prediction_error := y_meas - phi * theta;
        delta_theta := K * prediction_error;

        // 防暴冲限幅
        if abs(delta_theta) > theta * 0.1 then
          delta_theta := sign(delta_theta) * theta * 0.1;
        end if;

        theta := theta + delta_theta;
        P := (1 - K * phi) * P / lambda;

      else
        // 关断或切换中
        theta := theta;
        P := P;
      end if;

      // 下限保护
      if theta < 1e-4 then
        theta := 1e-4;
      end if;

    end when;

    Ron_hat := theta;

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 0, 0}, fillColor = {255, 235, 235}, fillPattern = FillPattern.Solid),
      Text(extent = {{-90, 90}, {90, 50}}, textString = "Ron RLS", lineColor = {255, 0, 0}),
      Line(points = {{-40, 0}, {-20, 0}}, color = {255, 0, 0}, thickness = 0.5),
      Line(points = {{20, 0}, {40, 0}}, color = {255, 0, 0}, thickness = 0.5),
      Rectangle(extent = {{-20, 10}, {20, -10}}, lineColor = {255, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-100, 80}, {-40, 60}}, textString = "Vsw", lineColor = {128, 0, 0}, textStyle = {TextStyle.Small}),
      Text(extent = {{-100, 0}, {-40, -20}}, textString = "i_L", lineColor = {128, 0, 0}, textStyle = {TextStyle.Small}),
      Text(extent = {{-100, -80}, {-40, -100}}, textString = "Gate", lineColor = {128, 0, 0}, textStyle = {TextStyle.Small}),
      Text(extent = {{40, 0}, {100, -20}}, textString = "R_hat", lineColor = {255, 0, 0})
    })
  );
end RLS_Ron_Observer;