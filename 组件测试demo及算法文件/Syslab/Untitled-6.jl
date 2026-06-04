using CSV
using DataFrames
using Statistics
using Printf

# 1. 加载数据
file_path = "System_Buck_Twin_Rc.csv"
if !isfile(file_path)
    error("找不到数据文件，请确保文件在当前工作目录下。")
end

df = CSV.read(file_path, DataFrame)

# 2. 选取分析区间 (排除 0-0.6s 的算法冷启动收敛期)
# 这一步非常重要，因为初始收敛过程是非线性的，会干扰老化趋势的评估
start_time = 0.6
end_time = 2.0
analysis_df = filter(row -> row."Time(s)" >= start_time && row."Time(s)" <= end_time, df)

# 提取时间轴 (X) 和 ESR 辨识值 (Y)
# 注意：列名需与您的 CSV 完全匹配
x = analysis_df."Time(s)"
y = analysis_df."highFreq_Rc_Observer.Rc_hat"
n = length(x)

# 3. 线性回归计算 (y = ax + b)
mean_x = mean(x)
mean_y = mean(y)

# 计算最小二乘法回归系数
numerator = sum((x .- mean_x) .* (y .- mean_y))
denominator = sum((x .- mean_x).^2)
a = numerator / denominator
b = mean_y - a * mean_x

# 计算拟合值 y_fit (即理论线性退化值)
y_fit = a .* x .+ b

# 4. 计算评估指标：决定系数 R²
ss_res = sum((y .- y_fit).^2)      # 残差平方和
ss_tot = sum((y .- mean_y).^2)     # 总离差平方和
r_squared = 1 - (ss_res / ss_tot)

# 5. 打印报告
println("====================================================")
println("      电容 ESR (Rc) 监测线性度评估报告")
println("====================================================")
@printf("分析时间窗口:    %.2f s - %.2f s\n", start_time, end_time)
@printf("样本数据点数:    %d\n", n)
@printf("ESR 增长斜率 (a): %.6e Ohm/s\n", a)
@printf("截距偏移 (b):     %.6f Ohm\n", b)
println("----------------------------------------------------")
@printf("线性拟合度 R²:    %.6f\n", r_squared)
println("----------------------------------------------------")

# 6. 结论判定
if r_squared > 0.98
    println("评估结论: [极佳] Rc_hat 曲线与老化物理逻辑高度一致。")
elseif r_squared > 0.90
    println("评估结论: [良好] 存在一定高频纹波干扰，但整体老化趋势清晰。")
else
    println("评估结论: [波动较大] 建议检查高通滤波器 f_hp 设置，以滤除更多纹波分量。")
end
println("====================================================")