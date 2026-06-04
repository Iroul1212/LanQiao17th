using CSV
using DataFrames
using Statistics
using Printf

# 1. 加载仿真数据
# 确保文件 System_Buck_Twin_C.csv 位于当前工作目录下
file_path = "System_Buck_Twin_C.csv"
if !isfile(file_path)
    error("找不到数据文件，请检查文件路径。")
end

df = CSV.read(file_path, DataFrame)

# 2. 筛选 0.1s 到 1.0s 之间的样本点 (算法进入稳态后的区间)
# 严格匹配 CSV 中的列名: "Time(s)" 和 "SOH_C_Out"
steady_state_df = filter(row -> row."Time(s)" >= 0.1 && row."Time(s)" <= 1.0, df)

if isempty(steady_state_df)
    error("筛选区间内无数据点，请检查仿真时间设置。")
end

# 3. 提取辨识值序列
c_hat = steady_state_df."SOH_C_Out"

# 4. 计算统计学量化指标
mu_c = mean(c_hat)        # 均值 (Mean)
var_c = var(c_hat)        # 方差 (Variance)
std_c = std(c_hat)        # 标准差 (Standard Deviation)
cv_c = (std_c / mu_c) * 100 # 变异系数 (CV, %)

# 5. 格式化输出结果
println("==========================================")
println("      Buck 变换器辨识稳定性量化分析        ")
println("==========================================")
@printf("分析时间区间:    0.10s - 1.00s\n")
@printf("有效样本总数:    %d\n", length(c_hat))
@printf("辨识均值 (μ):    %.6e F\n", mu_c)
@printf("------------------------------------------\n")
@printf("方差 (Variance): %.6e\n", var_c)
@printf("标准差 (Std):    %.6e\n", std_c)
@printf("变异系数 (CV):   %.4f %%\n", cv_c)
println("------------------------------------------\n")

# 6. 基于 CV 的连贯性判定逻辑
if cv_c < 1.0
    println("稳定性判定结论: [优秀] 算法受噪声干扰极小，逻辑连贯性强。")
elseif cv_c < 5.0
    println("稳定性判定结论: [良好] 辨识结果存在轻微波动，满足工程要求。")
else
    println("稳定性判定结论: [需优化] 辨识结果波动较大，建议调整 BBO 迁移率或 alpha 平滑系数。")
end
println("==========================================")