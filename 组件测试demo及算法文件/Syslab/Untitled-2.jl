using CSV
using DataFrames
using Statistics
using Printf

# 1. 读取 CSV 文件
file_path = "System_Buck_Twin_Rc.csv"
data = CSV.read(file_path, DataFrame)

# 2. 提取列数据
# 根据文件结构：第1列是时间，第2列是 ESR_actual，第3列是 Rc_hat
time_val = data[:, 1]
esr_actual = data[:, 2]
rc_hat = data[:, 3]

# 3. 筛选 0.6s 到 2s 之间的数据
mask = (time_val .>= 0.6) .& (time_val .<= 2.0)
esr_filtered = esr_actual[mask]
rc_filtered = rc_hat[mask]

# 4. 计算百分比误差 (Relative Percentage Error)
# 公式: |(Rc_hat - ESR_actual) / ESR_actual| * 100%
if !isempty(esr_filtered)
    rel_errors = abs.(rc_filtered .- esr_filtered) ./ abs.(esr_filtered) .* 100

    # 5. 计算统计值
    min_error = minimum(rel_errors)
    max_error = maximum(rel_errors)
    mean_error = mean(rel_errors)

    # 6. 格式化输出结果
    println("--- 误差分析报告 (0.6s - 2.0s) ---")
    @printf("误差范围 (Range):  %.6f%% ~ %.6f%%\n", min_error, max_error)
    @printf("平均误差 (Average): %.6f%%\n", mean_error)
    println("----------------------------------")
else
    println("错误：在 0.6s 到 2s 范围内未找到有效数据。")
end