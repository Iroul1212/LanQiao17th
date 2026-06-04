using CSV
using DataFrames
using Statistics
using Printf

# 1. 加载数据
file_path = "System_Buck_Twin_C.csv"
if !isfile(file_path)
    error("找不到文件：$file_path")
end

df = CSV.read(file_path, DataFrame)

# 2. 筛选分析区间
start_time = 0.1
end_time = 1.0
analysis_df = filter(row -> row."Time(s)" >= start_time && row."Time(s)" <= end_time, df)

# 提取时间 (X) 和 SOH 辨识值 (Y)
x = analysis_df."Time(s)"
y = analysis_df."SOH_C_Out"
n = length(x)

# 3. 线性回归计算 (最小二乘法: y = ax + b)
# 计算均值
mean_x = mean(x)
mean_y = mean(y)

# 计算回归系数 a (斜率) 和 b (截距)
numerator = sum((x .- mean_x) .* (y .- mean_y))
denominator = sum((x .- mean_x).^2)
a = numerator / denominator
b = mean_y - a * mean_x

# 计算拟合值 y_fit
y_fit = a .* x .+ b

# 4. 计算决定系数 R² (Coefficient of Determination)
ss_res = sum((y .- y_fit).^2)      # 残差平方和
ss_tot = sum((y .- mean_y).^2)     # 总离差平方和
r_squared = 1 - (ss_res / ss_tot)

# 5. 输出评估报告
println("====================================================")
println("      电容健康状态 (SOH) 监测线性度评估报告")
println("====================================================")
@printf("分析样本数:      %d\n", n)
@printf("拟合退化斜率 (a): %.6e SOH/s\n", a)
@printf("拟合回归截距 (b): %.6f\n", b)
println("----------------------------------------------------")
@printf("线性拟合度 R²:    %.6f\n", r_squared)
println("----------------------------------------------------")

# 6. 结论判定
if r_squared > 0.99
    println("评估结论: [极佳] SOH 输出具有极高的线性度，完美还原了物理老化过程。")
elseif r_squared > 0.95
    println("评估结论: [良好] 存在轻微计算波动，但整体退化趋势识别准确。")
else
    println("评估结论: [需优化] 线性度偏低，建议增加 BBO 算法的 N_window 窗口长度以过滤噪声。")
end
println("====================================================")