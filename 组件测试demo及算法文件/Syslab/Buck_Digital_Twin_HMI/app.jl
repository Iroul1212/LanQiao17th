module Buck_Digital_Twin_HMI
    # Default loaded module
    using TyAppDesigner
    using ObjectOriented

    # User loaded module and file
    using FMI
    using TyPlot

    @oodef mutable struct App

        # Properties that correspond to app components
        UIFigure::TyAppDesigner.Figure = TyAppDesigner.create_figure()
        Axes1::TyAppDesigner.UIAxes = TyAppDesigner.create_uiaxes()
        Axes2::TyAppDesigner.UIAxes = TyAppDesigner.create_uiaxes()
        EditField_T::TyAppDesigner.NumericEditField = TyAppDesigner.create_numericeditfield()
        EditField_R::TyAppDesigner.NumericEditField = TyAppDesigner.create_numericeditfield()
        Btn_Start::TyAppDesigner.Button = TyAppDesigner.create_button()
        Btn_Close::TyAppDesigner.Button = TyAppDesigner.create_button()
        yLabel_C::TyAppDesigner.Label = TyAppDesigner.create_label()
        xLabel_C::TyAppDesigner.Label = TyAppDesigner.create_label()
        yLabel_R::TyAppDesigner.Label = TyAppDesigner.create_label()
        xLabel_R::TyAppDesigner.Label = TyAppDesigner.create_label()
        EditField_EqTime::TyAppDesigner.NumericEditField = TyAppDesigner.create_numericeditfield()
        Btn_Status_C::TyAppDesigner.Button = TyAppDesigner.create_button()
        Btn_Status_Rc::TyAppDesigner.Button = TyAppDesigner.create_button()
        Label_C::TyAppDesigner.Label = TyAppDesigner.create_label()
        Label_R::TyAppDesigner.Label = TyAppDesigner.create_label()

        # Appinfo
        Appname::Module = @__MODULE__
        Appfile::String = @__FILE__

        # User custom functions


        # User custom properties
        UserData::Dict{String, Any} = Dict{String, Any}("is_initialized" => false)

        # Callbacks that handle component events

        # Btn_StartPushedFcn function:Btn_Start
        function Btn_StartPushedFcn(app,event)
            try
                if !isdefined(app, :UserData) || !haskey(app.UserData, "is_initialized")
                    app.UserData = Dict{String, Any}("is_initialized" => false)
                end

                if !app.UserData["is_initialized"]
                    app.Btn_Start.Text = "加载中..." 
                    
                    app.UserData["t_current"] = 0.0
                    app.UserData["dt_macro"] = 0.01
                    app.UserData["is_running"] = false
                    
                    app.UserData["time_scale"] = 1.0 
                    app.UserData["K_acc"] = 0.5 
                    
                    app.UserData["vars_in"] = ["Set_T_Env", "Set_R_Load"]
                    app.UserData["vars_out"] = ["SOH_C_Out", "SOH_L_Out", "SOH_Rc_Out"]
                    
                    app.UserData["time_log"] = Float64[]
                    app.UserData["t_physical_log"] = Float64[] 
                    app.UserData["C_log"] = Float64[]
                    app.UserData["L_log"] = Float64[]
                    app.UserData["Rc_log"] = Float64[]
                    
                    fmu_path = joinpath(@__DIR__, "Buck_Digital_Twin_System_Buck_Twin.fmu")
                    if !isfile(fmu_path)
                        app.Btn_Start.Text = "FMU路径丢失" 
                        println("【致命错误】未找到 FMU 文件: ", fmu_path)
                        return
                    end

                    app.UserData["fmu"] = loadFMU(fmu_path)
                    app.UserData["inst"] = fmi2Instantiate!(app.UserData["fmu"])
                    
                    inst = app.UserData["inst"]
                    fmi2SetupExperiment(inst, 0.0, 1e5) 
                    fmi2EnterInitializationMode(inst)
                    fmi2SetReal(inst, app.UserData["vars_in"], Float64[app.EditField_T.Value, app.EditField_R.Value])
                    fmi2ExitInitializationMode(inst)
                    
                    app.UserData["is_initialized"] = true
                end

                app.UserData["is_running"] = !app.UserData["is_running"]
                
                if app.UserData["is_running"]
                    app.Btn_Start.Text = "暂停"
                    
                    @async begin
                        inst = app.UserData["inst"]
                        dt = app.UserData["dt_macro"]
                        vars_in = app.UserData["vars_in"]
                        vars_out = app.UserData["vars_out"]
                        
                        T_real_0 = time()
                        t_sim_0 = app.UserData["t_current"]
                        k_scale = app.UserData["time_scale"]
                        k_acc = app.UserData["K_acc"]
                        
                        try
                            while app.UserData["is_running"]
                                t = app.UserData["t_current"]
                                
                                fmi2SetReal(inst, vars_in, Float64[app.EditField_T.Value, app.EditField_R.Value])
                                status = fmi2DoStep(inst, t, dt, Int32(1))
                                
                                if status != 0
                                    app.UserData["is_running"] = false
                                    app.Btn_Start.Text = "解算发散" 
                                    break
                                end
                                
                                app.UserData["t_current"] += dt
                                res = fmi2GetReal(inst, vars_out)
                                
                                current_C_uF = res[1] * 1e6
                                current_Rc_mOhm = res[3] * 1e3

                                # 瞬态掩蔽逻辑 (消除0.1秒内的底层初始化跳变)
                                t_sim = app.UserData["t_current"]
                                T_converge = 0.1  
                                if t_sim < T_converge
                                    weight = (T_converge - t_sim) / T_converge 
                                    current_C_uF = weight * 330.0 + (1.0 - weight) * current_C_uF
                                    current_Rc_mOhm = weight * 25.0 + (1.0 - weight) * current_Rc_mOhm
                                end

                                push!(app.UserData["time_log"], app.UserData["t_current"])
                                push!(app.UserData["t_physical_log"], app.UserData["t_current"] * k_acc)
                                
                                push!(app.UserData["C_log"], current_C_uF)
                                push!(app.UserData["L_log"], res[2] * 1e3)
                                push!(app.UserData["Rc_log"], current_Rc_mOhm)
                                
                                # =========================================================
                                # 报警系统
                                # =========================================================
                                
                                # C
                                if current_C_uF <= 313.5
                                    app.Btn_Status_C.Text = "故障"
                                    app.Btn_Status_C.BackgroundColor = [0.9, 0.2, 0.2] # 红色
                                    app.Btn_Status_C.FontColor = [1.0, 1.0, 1.0]
                                elseif current_C_uF <= 320.1
                                    app.Btn_Status_C.Text = "警告"
                                    app.Btn_Status_C.BackgroundColor = [1.0, 0.6, 0.0] # 橙色
                                    app.Btn_Status_C.FontColor = [1.0, 1.0, 1.0]
                                else
                                    app.Btn_Status_C.Text = "正常"
                                    app.Btn_Status_C.BackgroundColor = [0.1294, 0.7647, 0.4941] # 绿色
                                    app.Btn_Status_C.FontColor = [1.0, 1.0, 1.0]
                                end
                                
                                # 2. Rc
                                if current_Rc_mOhm >= 50.0
                                    app.Btn_Status_Rc.Text = "故障"
                                    app.Btn_Status_Rc.BackgroundColor = [0.9, 0.2, 0.2] # 红色
                                    app.Btn_Status_Rc.FontColor = [1.0, 1.0, 1.0]
                                elseif current_Rc_mOhm >= 37.5
                                    app.Btn_Status_Rc.Text = "警告"
                                    app.Btn_Status_Rc.BackgroundColor = [1.0, 0.6, 0.0] # 橙色
                                    app.Btn_Status_Rc.FontColor = [1.0, 1.0, 1.0]
                                else
                                    app.Btn_Status_Rc.Text = "正常"
                                    app.Btn_Status_Rc.BackgroundColor = [0.1294, 0.7647, 0.4941] # 绿色
                                    app.Btn_Status_Rc.FontColor = [1.0, 1.0, 1.0]
                                end
                                # =========================================================
                                
                                if length(app.UserData["time_log"]) % 10 == 0
                                    window_size = 500
                                    start_idx = max(1, length(app.UserData["time_log"]) - window_size)
                                    
                                    t_view = app.UserData["time_log"][start_idx:end]
                                    C_view = app.UserData["C_log"][start_idx:end]
                                    Rc_view = app.UserData["Rc_log"][start_idx:end]
                                    
                                    TyPlot.plot(app.Axes1, t_view, C_view)
                                    TyPlot.plot(app.Axes2, t_view, Rc_view)
                                    
                                    if isdefined(app, :EditField_EqTime)
                                        app.EditField_EqTime.Value = round(app.UserData["t_physical_log"][end], digits=3)
                                    end
                                end
                                
                                T_target = T_real_0 + (app.UserData["t_current"] - t_sim_0) / k_scale
                                sleep_duration = T_target - time()
                                
                                if sleep_duration > 0.0
                                    sleep(sleep_duration)
                                else
                                    yield()
                                end
                            end
                        catch e
                            app.UserData["is_running"] = false
                            app.Btn_Start.Text = "渲染崩溃"
                            println("【异步协程异常】: ", e)
                        end
                    end
                else
                    app.Btn_Start.Text = "启动"
                end
            catch err
                app.Btn_Start.Text = "系统错误" 
                println("【主控线程异常】: ", err)
            end
        end

        # Btn_ClosePushedFcn function:Btn_Close
        function Btn_ClosePushedFcn(app,event)
        # 1. 停止仿真循环
            if haskey(app.UserData, "is_running")
                app.UserData["is_running"] = false
                sleep(0.1) # 给异步协程 0.1s 的时间安全退出
            end
            
            # 2. 释放底层的 C 指针
            if app.UserData["is_initialized"]
                try
                    fmi2FreeInstance!(app.UserData["inst"])
                    unloadFMU(app.UserData["fmu"])
                catch
                end
            end
            
            # 3. 销毁 App 窗口
            TyAppDesigner.delete(app, app.UIFigure)    
        end

        # Create UIFigure and components
        function createComponents(app)
            # Create UIFigure
            app.UIFigure = TyAppDesigner.uifigure(Visible=false)
            app.UIFigure.Position = [100,100,789,602]
            app.UIFigure.Name = raw"Syslab App"

            # Create Axes1
            app.Axes1 = TyAppDesigner.uiaxes(app.UIFigure)
            app.Axes1.Position = [356,31,400,260]
            app.Axes1.Title = raw"输出滤波电容连续老化特征 (C)"

            # Create Axes2
            app.Axes2 = TyAppDesigner.uiaxes(app.UIFigure)
            app.Axes2.Position = [357,314,400,260]
            app.Axes2.Title = raw"电容等效串联电阻离散故障特征 (Rc)"

            # Create EditField_T
            app.EditField_T = TyAppDesigner.uinumericeditfield(app.UIFigure)
            app.EditField_T.Position = [44,93,190,24]
            app.EditField_T.Label = raw"环境温度 [℃]"
            app.EditField_T.Value = 25
            app.EditField_T.HorizontalAlignment = raw"center"

            # Create EditField_R
            app.EditField_R = TyAppDesigner.uinumericeditfield(app.UIFigure)
            app.EditField_R.Position = [44,154,190,24]
            app.EditField_R.Label = raw"负载电阻 [Ω]"
            app.EditField_R.Value = 1
            app.EditField_R.HorizontalAlignment = raw"center"

            # Create Btn_Start
            app.Btn_Start = TyAppDesigner.uibutton(app.UIFigure)
            app.Btn_Start.Position = [103,470,100,32]
            app.Btn_Start.Text = raw"启动"
            app.Btn_Start.ButtonPushedFcn = raw"Btn_StartPushedFcn"

            # Create Btn_Close
            app.Btn_Close = TyAppDesigner.uibutton(app.UIFigure)
            app.Btn_Close.Position = [103,528,100,32]
            app.Btn_Close.Text = raw"安全退出"
            app.Btn_Close.ButtonPushedFcn = raw"Btn_ClosePushedFcn"

            # Create yLabel_C
            app.yLabel_C = TyAppDesigner.uilabel(app.UIFigure)
            app.yLabel_C.Position = [303,154,67,24]
            app.yLabel_C.Text = raw"容值 [μF]"
            app.yLabel_C.HorizontalAlignment = raw"center"
            app.yLabel_C.VerticalAlignment = raw"center"
            app.yLabel_C.WordWrap = false

            # Create xLabel_C
            app.xLabel_C = TyAppDesigner.uilabel(app.UIFigure)
            app.xLabel_C.Position = [536,267,63,24]
            app.xLabel_C.Text = raw"时间 [s]"

            # Create yLabel_R
            app.yLabel_R = TyAppDesigner.uilabel(app.UIFigure)
            app.yLabel_R.Position = [303,443,67,24]
            app.yLabel_R.Text = raw"阻值 [mΩ]"
            app.yLabel_R.HorizontalAlignment = raw"center"
            app.yLabel_R.VerticalAlignment = raw"center"
            app.yLabel_R.WordWrap = false

            # Create xLabel_R
            app.xLabel_R = TyAppDesigner.uilabel(app.UIFigure)
            app.xLabel_R.Position = [536,550,63,24]
            app.xLabel_R.Text = raw"时间 [s]"

            # Create EditField_EqTime
            app.EditField_EqTime = TyAppDesigner.uinumericeditfield(app.UIFigure)
            app.EditField_EqTime.Position = [58,396,190,24]
            app.EditField_EqTime.Label = raw"等效运行时间 [年]"
            app.EditField_EqTime.HorizontalAlignment = raw"center"

            # Create Btn_Status_C
            app.Btn_Status_C = TyAppDesigner.uibutton(app.UIFigure)
            app.Btn_Status_C.Position = [160,230,38,32]
            app.Btn_Status_C.Text = raw"正常"

            # Create Btn_Status_Rc
            app.Btn_Status_Rc = TyAppDesigner.uibutton(app.UIFigure)
            app.Btn_Status_Rc.Position = [160,305,38,32]
            app.Btn_Status_Rc.Text = raw"正常"

            # Create Label_C
            app.Label_C = TyAppDesigner.uilabel(app.UIFigure)
            app.Label_C.Position = [103,234,50,24]
            app.Label_C.Text = raw"电容C"

            # Create Label_R
            app.Label_R = TyAppDesigner.uilabel(app.UIFigure)
            app.Label_R.Position = [102,309,52,24]
            app.Label_R.Text = raw"电阻Rc"

            # Show the figure after all components are created
            app.UIFigure.Visible= true
        end

        # App creation
        function initApp(app)
            # Create UIFigure and components
            app.createComponents()

            # Register the app with App Designer
            TyAppDesigner.registerApp(app, app.UIFigure)

            return app
        end

        # App deletion
        function delete(app)
            # Delete UIFigure when app is deleted
            TyAppDesigner.delete(app, app.UIFigure)
        end
    end

    # Create an APP instance
    Instance = App().initApp()
end