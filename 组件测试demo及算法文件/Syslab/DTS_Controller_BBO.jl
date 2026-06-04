using FMI
using TyPlot

# 1. 指向您确认的最新文件名
fmu_path = joinpath(@__DIR__, "Buck_Digital_Twin_System_Buck_Twin.fmu")
myFMU = loadFMU(fmu_path)

function run_digital_twin(fmu)
    inst = fmi2Instantiate!(fmu)
    
    # 仿真参数：dt_macro 为 Julia 与 FMU 交互的间隔
    t_start, t_stop, dt_macro = 0.0, 2.0, 0.01 

    # 变量名（须与 modelDescription.xml 中 exact match）
    vars_in = ["Set_T_Env", "Set_R_Load"]
    vars_out = ["full_BBO_Optimizer.Rs_hat", "voltageSensor.v"]

    # --- 初始化序列 ---
    fmi2SetupExperiment(inst, t_start, t_stop)
    fmi2EnterInitializationMode(inst)
    
    # 在初始化时注入物理初值，防止因默认 0 值导致初值计算发散
    # 对应 25摄氏度 环境与 1.0欧姆 负载
    fmi2SetReal(inst, vars_in, [25.0, 1.0])
    
    fmi2ExitInitializationMode(inst)

    # 预分配存储空间
    time_log, Rs_log, V_log = Float64[], Float64[], Float64[]
    t_current = t_start

    while t_current <= t_stop
        # 边界条件控制逻辑
        current_T = 25.0 + 50.0 * (t_current / t_stop)
        current_R = t_current < 1.0 ? 1.0 : 0.5
        
        fmi2SetReal(inst, vars_in, [current_T, current_R])
        
        # 驱动 FMU 步进
        # 注意：由于导出时设为 1e-5 定步长，这里的 dt_macro 必须是其整数倍
        status = fmi2DoStep(inst, t_current, dt_macro, Int32(1))
        
        if status != 0
            @warn "仿真在 t = $(t_current) 停止。请检查模型内阻设置。"
            break 
        end
        
        t_current += dt_macro
        
        # 采集结果
        res = fmi2GetReal(inst, vars_out)
        push!(time_log, t_current)
        push!(Rs_log, res[1])
        push!(V_log, res[2])
    end

    fmi2FreeInstance!(inst)
    return time_log, Rs_log, V_log
end

# 运行主流程
try
    t_data, rs_data, v_data = run_digital_twin(myFMU)
    unloadFMU(myFMU)
    
    if !isempty(t_data)
        # 使用标准的 TyPlot 绘图接口
        subplot(211)
        plot(t_data, rs_data, "r", linewidth=1.5)
        title("BBO Online Parameter Estimation: Rs_hat")
        ylabel("Rs [Ohm]")
        grid("on")

        subplot(212)
        plot(t_data, v_data, "b", linewidth=1.5)
        title("Buck Converter Output Voltage")
        xlabel("Time [s]")
        ylabel("Voltage [V]")
        grid("on")
    else
        println("未获取到仿真数据，请确认 FMU 文件是否在当前目录。")
    end
catch e
    println("程序异常退出: ", e)
    # 确保即使崩溃也能卸载 FMU，释放 DLL 占用
    try unloadFMU(myFMU) catch end
end