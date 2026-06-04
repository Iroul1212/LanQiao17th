using CSV
using DataFrames
using Statistics

# 1. 读取 CSV 文件
file_path = "System_Buck_Twin_C.csv"
data = CSV.read(file_path, DataFrame)

# 2. 获取列名（处理可能存在的特殊字符）
# 假设列顺序为：Time(s), SOH_C_Out, agingCapacitor.C_actual(F)
time_val = data[:, 1]
soh_out = data[:, 2]
c_actual = data[:, 3]

# 3. 筛选第一秒内的数据 (0 <= t <= 1)
mask = time_val .<= 1.0
soh_filtered = soh_out[mask]
c_actual_filtered = c_actual[mask]

# 4. 计算百分比误差
# 公式: |(SOH_C_Out - C_actual) / C_actual| * 100%
relative_errors = abs.(soh_filtered .- c_actual_filtered) ./ abs.(c_actual_filtered) .* 100

# 5. 计算统计结果
min_error = minimum(relative_errors)
max_error = maximum(relative_errors)
mean_error = mean(relative_errors)

# 6. 打印结果
println("--- 第一秒内 (0s - 1s) 误差分析结果 ---")
@printf("误差范围 (Range): %.6f%% ~ %.6f%%\n", min_error, max_error)
@printf("平均误差 (Mean): %.6f%%\n", mean_error)