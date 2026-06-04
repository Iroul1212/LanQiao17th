model System_Buck_Twin

  Modelica.Electrical.Analog.Ideal.IdealDiode diode(useHeatPort=true,Ron=0.05,Vknee=0.7) 
    annotation(Placement(transformation(origin={-54,12},
extent={{-10,10},{10,-10}},
rotation=90)));

  PrecisionInductor PrecisionInductor(T_ref=298.15,C_thermal=0.005) 
    annotation(Placement(transformation(origin={8,60},
extent={{-10,10},{10,-10}})));
  Modelica.Electrical.Analog.Basic.Resistor R_s(R = 0.07) 
    annotation(Placement(transformation(origin={-28,60},
extent={{-10,-10},{10,10}})));

  Modelica.Electrical.Analog.Sources.ConstantVoltage Vin(V = 10) 
    annotation(Placement(transformation(origin={-152,12},
extent={{-10,-10},{10,10}},
rotation=-90)));
  Modelica.Electrical.Analog.Basic.Ground ground 
    annotation(Placement(transformation(origin={-54,-46},
extent={{-10,-10},{10,10}})));

  Modelica.Blocks.Sources.Constant duty_nominal(k = 0.33) 
    annotation(Placement(transformation(origin={222,60},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Pulse perturbation(period = 0.002, amplitude = 0.05, width = 50) 
    annotation(Placement(transformation(origin={222,22},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.Add add_perturb 
    annotation(Placement(transformation(origin={264,40},
extent={{-10,-10},{10,10}})));

  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor 
    annotation(Placement(transformation(origin={44,60},
extent={{-10,10},{10,-10}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor voltageSensor 
    annotation(Placement(transformation(origin={178,12},
extent={{10,-10},{-10,10}},
rotation=90)));

  // BBO
  Full_BBO_Optimizer full_BBO_Optimizer 
    annotation(Placement(transformation(origin={123,166},
extent={{-10,-10},{10,10}},
rotation=360)));
  Modelica.Blocks.Interfaces.RealOutput SOH_C_Out 
    annotation(Placement(transformation(origin={162,186},
extent={{-10,-10},{10,10}})));
  AgingCapacitor agingCapacitor(ESR_initial=0.025,C_nominal=330e-6) 
    annotation (Placement(transformation(origin={68,12},
extent={{-10,-10},{10,10}},
rotation=270)));
  Modelica.Blocks.Interfaces.RealOutput SOH_Rc_Out 
    annotation (Placement(transformation(origin={302,186},
extent={{-10,-10},{10,10}})));
  annotation(experiment(Algorithm=Dassl,InlineIntegrator=false,InlineStepSize=false,Interval=5e-05,StartTime=0,StopTime=2,StoreEventValue=0,Tolerance=1e-06),Diagram(coordinateSystem(extent={{-100,-100},{100,100}},
grid={2,2})));

    Real carrier;
    Boolean pwm_sig;
  Modelica.Blocks.Interfaces.RealOutput SOH_L_Out 
    annotation(Placement(transformation(origin={200,186},
extent={{-10,-10},{10,10}})));
  ThermalSwitch_NoCaps thermalSwitch_NoCaps(C_th={0.001, 0.001, 0.001}) 
    annotation (Placement(transformation(origin={-84,60},
extent={{-10,-10},{10,10}},
rotation=360)));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor heatsink_MOSFET(G=0.1) 
    annotation (Placement(transformation(origin={-84,120},
extent={{10,-10},{-10,10}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor heatsink_L(G=0.05) 
    annotation (Placement(transformation(origin={-84,150},
extent={{10,-10},{-10,10}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor heatsink_D(G=0.5) 
    annotation (Placement(transformation(origin={-84,90},
extent={{10,-10},{-10,10}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedTemperature prescribedTemperature 
    annotation (Placement(transformation(origin={-144.5,134},
extent={{-10,-10},{10,10}})));
  Modelica.Electrical.Analog.Basic.VariableResistor resistor 
    annotation (Placement(transformation(origin={123,12},
extent={{-10,-10},{10,10}},
rotation=-90)));
  Modelica.Blocks.Nonlinear.Limiter limiter(uMin=0.1,uMax=100) 
    annotation (Placement(transformation(origin={-205,-68},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.UnitConversions.From_degC from_degC 
    annotation (Placement(transformation(origin={-205,134},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Noise.NormalNoise normalNoise(samplePeriod=0.0002,sigma=0.002) 
    annotation (Placement(transformation(origin={156,102},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Math.Add add 
    annotation (Placement(transformation(origin={222,108},
extent={{-10,-10},{10,10}})));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor_input 
    annotation (Placement(transformation(origin={-122,60},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Interfaces.RealInput Set_T_Env 
    annotation (Placement(transformation(origin={-308,134},
extent={{-20,-20},{20,20}})));
  Modelica.Blocks.Interfaces.RealInput Set_R_Load 
    annotation (Placement(transformation(origin={-308,-68},
extent={{-20,-20},{20,20}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor heatsink_C(G=0.05) 
    annotation (Placement(transformation(origin={-84,180},
extent={{10,-10},{-10,10}})));
  HighFreq_Rc_Observer highFreq_Rc_Observer 
    annotation (Placement(transformation(origin={268,173},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Constant const(k=25) 
    annotation (Placement(transformation(origin={-260,134},
extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.Constant const1 
    annotation (Placement(transformation(origin={-254,-68},
extent={{-10,-10},{10,10}})));
  equation
    carrier = (time - floor(time / 5e-5) * 5e-5) / 5e-5;
    pwm_sig = add_perturb.y > carrier;
  thermalSwitch_NoCaps.G.v = thermalSwitch_NoCaps.n.v + (if pwm_sig then 10 else 0);
  connect(full_BBO_Optimizer.C_hat, SOH_C_Out) 
  annotation(Line(origin={179,173},
points={{-45,-4},{-17,-4},{-17,13}},
color={0,0,127}));
  connect(currentSensor.n, voltageSensor.p) 
  annotation(Line(origin={116,41},
  points={{-62,19},{62,19},{62,-19}},
  color={0,0,255}));
  connect(voltageSensor.n, ground.p) 
  annotation(Line(origin={65,-17},
points={{113,19},{113,-19},{-119,-19}},
color={0,0,255}));
  connect(R_s.n, PrecisionInductor.p) 
  annotation(Line(origin={-10,60},
points={{-8,0},{8,0}},
color={0,0,255}));
  connect(PrecisionInductor.n, currentSensor.p) 
  annotation(Line(origin={26,60},
points={{-8,0},{8,0}},
color={0,0,255}));
  connect(diode.p, ground.p) 
  annotation(Line(origin={-54,-17},
points={{0,19},{0,-19}},
color={0,0,255}));
  connect(Vin.n, diode.p) 
  annotation(Line(origin={-87,2},
points={{-65,0},{-65,-38},{33,-38},{33,0}},
color={0,0,255}));
  connect(duty_nominal.y, add_perturb.u1) 
  annotation(Line(origin={259,53},
points={{-26,7},{-19,7},{-19,-7},{-7,-7}},
color={0,0,127}));
  connect(add_perturb.u2, perturbation.y) 
  annotation(Line(origin={240,27},
points={{12,7},{0,7},{0,-5},{-7,-5}},
color={0,0,127}));
  connect(currentSensor.n, agingCapacitor.p) 
  annotation(Line(origin={63,32},
points={{-9,28},{5,28},{5,-10}},
color={0,0,255}));
  connect(agingCapacitor.n, ground.p) 
  annotation(Line(origin={10,-17},
points={{58,19},{58,-19},{-64,-19}},
color={0,0,255}));
  connect(highFreq_Rc_Observer.Rc_hat, SOH_Rc_Out) 
  annotation(Line(origin={179,176},
points={{100,-3},{123,-3},{123,10}},
color={0,0,127}));
  connect(currentSensor.i, full_BBO_Optimizer.i_L) 
  annotation(Line(origin={80,119},
points={{-36,-48},{-36,47},{32,47}},
color={0,0,127}));
  connect(full_BBO_Optimizer.d, add_perturb.y) 
  annotation(Line(origin={195,99},
points={{-83,59},{-89,59},{-89,49},{89,49},{89,-59},{80,-59}},
color={0,0,127}),__MWORKS(BlockSystem(NamedSignal)));
  connect(full_BBO_Optimizer.L_hat, SOH_L_Out) 
  annotation(Line(origin={171,176},
points={{-37,-13},{29,-13},{29,10}},
color={0,0,127}));
  connect(thermalSwitch_NoCaps.n, R_s.p) 
  annotation(Line(origin={-53,60},
points={{-21,0},{15,0}},
color={0,0,255}));
  connect(diode.n, thermalSwitch_NoCaps.n) 
  annotation(Line(origin={-64,41},
points={{10,-19},{10,19},{-10,19}},
color={0,0,255}));
  connect(heatsink_MOSFET.port_a, thermalSwitch_NoCaps.heatPort) 
  annotation(Line(origin={-65,99},
points={{-9,21},{5,21},{5,-35},{-15,-35}},
color={191,0,0}));
  connect(heatsink_L.port_a, PrecisionInductor.heatPort) 
  annotation(Line(origin={3,105},
points={{-77,45},{5,45},{5,-36}},
color={191,0,0}));
  connect(heatsink_D.port_a, diode.heatPort) 
  annotation(Line(origin={-69,51},
  points={{-5,39},{2,39},{2,-39},{5,-39}},
  color={191,0,0}));
  connect(heatsink_L.port_b, prescribedTemperature.port) 
  annotation(Line(origin={-112,135},
points={{18,15},{-15,15},{-15,-1},{-22.5,-1}},
color={191,0,0}));
  connect(heatsink_MOSFET.port_b, prescribedTemperature.port) 
  annotation(Line(origin={-112,120},
points={{18,0},{-15,0},{-15,14},{-22.5,14}},
color={191,0,0}));
  connect(heatsink_D.port_b, prescribedTemperature.port) 
  annotation(Line(origin={-112,105},
points={{18,-15},{-15,-15},{-15,29},{-22.5,29}},
color={191,0,0}));
  connect(currentSensor.n, resistor.p) 
  annotation(Line(origin={89,41},
  points={{-35,19},{34,19},{34,-19}},
  color={0,0,255}));
  connect(resistor.n, ground.p) 
  annotation(Line(origin={35,-17},
points={{88,19},{88,-19},{-89,-19}},
color={0,0,255}));
  connect(from_degC.y, prescribedTemperature.T) 
  annotation(Line(origin={-175,120},
points={{-19,14},{18.5,14}},
color={0,0,127}));
  connect(limiter.y, resistor.R) 
  annotation(Line(origin={-27,-24},
points={{-167,-44},{177,-44},{177,36},{162,36}},
color={0,0,127}));
  connect(add.u1, voltageSensor.v) 
  annotation(Line(origin={190,72},
points={{20,42},{2,42},{2,-60},{-1,-60}},
color={0,0,127}));
  connect(add.u2, normalNoise.y) 
  annotation(Line(origin={195,114},
points={{15,-12},{-28,-12}},
color={0,0,127}),__MWORKS(BlockSystem(NamedSignal)));
  connect(add.y, full_BBO_Optimizer.v_out) 
  annotation(Line(origin={173,147},
points={{60,-39},{81,-39},{81,-10},{-75,-10},{-75,27},{-61,27}},
color={0,0,127}));
  connect(thermalSwitch_NoCaps.p, currentSensor_input.n) 
  annotation(Line(origin={-101,60},
points={{7,0},{-11,0}},
color={0,0,255}));
  connect(currentSensor_input.p, Vin.p) 
  annotation(Line(origin={-140,41},
points={{8,19},{-12,19},{-12,-19}},
color={0,0,255}));
  connect(heatsink_C.port_a, agingCapacitor.heatPort) 
  annotation(Line(origin={4,99},
points={{-78,81},{82,81},{82,-87},{74,-87}},
color={191,0,0}));
  connect(heatsink_C.port_b, prescribedTemperature.port) 
  annotation(Line(origin={-112,154},
points={{18,26},{-15,26},{-15,-20},{-22.5,-20}},
color={191,0,0}));
  connect(add.y, highFreq_Rc_Observer.v_out) 
  annotation(Line(origin={238,138},
points={{-5,-30},{1,-30},{1,38},{19,38}},
color={0,0,127}));
  connect(currentSensor.i, highFreq_Rc_Observer.i_L) 
  annotation(Line(origin={143,120},
points={{-99,-49},{-99,-40},{181,-40},{181,36},{103,36},{103,50},{114,50}},
color={0,0,127}));
  connect(const1.y, limiter.u) 
  annotation(Line(origin={-230,-68},
  points={{-13,0},{13,0}},
  color={0,0,127}));
  connect(from_degC.u, const.y) 
  annotation(Line(origin={-233,134},
  points={{16,0},{-16,0}},
  color={0,0,127}));
  end System_Buck_Twin;