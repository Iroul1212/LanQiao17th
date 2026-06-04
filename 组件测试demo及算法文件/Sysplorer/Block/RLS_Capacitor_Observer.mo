block RLS_Capacitor_Observer // RLS电容辨识器
  import Modelica.Blocks.Interfaces.*;

  // 端口定义
  RealInput v_in annotation (Placement(transformation(extent={{-120,60},{-80,100}}), iconTransformation(extent={{-120,60},{-80,100}})));
  RealInput i_in annotation (Placement(transformation(extent={{-120,-100},{-80,-60}}), iconTransformation(extent={{-120,-100},{-80,-60}})));
  RealOutput C_hat annotation (Placement(transformation(extent={{100,-10},{120,10}}), iconTransformation(extent={{100,-10},{120,10}})));

  // 参数
  parameter Real samplePeriod = 1e-5;
  parameter Real lambda = 0.999;
  parameter Real R_load_known = 5;
  parameter Real init_C = 220e-6;
  parameter Real init_P = 10;

  // 内部变量
  protected
    discrete Real theta(start=init_C, fixed=true);
    discrete Real P(start=init_P, fixed=true);
    discrete Real v_old(start=0, fixed=true);
    Real phi;
    Real y_meas;
    Real K;
    Real prediction_error;
    Real delta_theta;
    Boolean sampleTrigger;

algorithm
  sampleTrigger := sample(0, samplePeriod);

  when sampleTrigger then
    y_meas := i_in - (v_in / R_load_known);
    phi := (v_in - v_old) / samplePeriod;

    // 输出带噪声的真实原始值
    if time > 0.01 and abs(phi) > 100 and P < 1e5 then
      K := (P * phi) / (lambda + phi * P * phi);
      prediction_error := y_meas - phi * theta;
      delta_theta := K * prediction_error;

      // 10% 防暴冲限幅
      if abs(delta_theta) > theta * 0.1 then
         delta_theta := sign(delta_theta) * theta * 0.1;
      end if;

      theta := theta + delta_theta;
      P := (1 - K * phi) * P / lambda;
    else
      theta := theta;
      P := P;
    end if;

    v_old := v_in;
    if theta < 1e-9 then theta := 1e-9; end if;
  end when;

  C_hat := theta;
  annotation (
    Icon(graphics={
      Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,100,0}, fillColor={220,255,220}, fillPattern=FillPattern.Solid),

      Text(extent={{-90,90},{90,50}}, textString="Capacitor RLS", lineColor={0,100,0}),

      Line(points={{-40,0},{-10,0}}, color={0,100,0}, thickness=0.5),
      Line(points={{-10,20},{-10,-20}}, color={0,100,0}, thickness=1),
      Line(points={{10,20},{10,-20}}, color={0,100,0}, thickness=1),
      Line(points={{10,0},{40,0}}, color={0,100,0}, thickness=0.5),

      Text(extent={{-100,80},{-40,60}}, textString="v", lineColor={0,64,0}, textStyle={TextStyle.Small}),
      Text(extent={{-100,-60},{-40,-80}}, textString="i", lineColor={0,64,0}, textStyle={TextStyle.Small}),
      Text(extent={{40,0},{100,-20}}, textString="C_hat", lineColor={0,128,0})
    })
  );
end RLS_Capacitor_Observer;