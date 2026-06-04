using CSV
using DataFrames
using Statistics
using Printf

# 1. 加载数据文件
# 自动匹配您上传的 System_Buck_Twin_Rc.csv
file_path = "System_Buck_Twin_Rc.csv"
if !isfile(file_path)
    error("未找到文件：$(file_path)，请确保文件在当前工作路径。")
end

df = CSV.read(file_path, DataFrame)

# 2. 筛选 0.6s 到 2.0s 的稳态区间
# 严格对应 CSV 列名："Time(s)" 和 "highFreq_Rc_Observer.Rc_hat"
start_time = 0.6
end_time = 2.0
steady_state_df = filter(row -> row."Time(s)" >= start_time && row."Time(s)" <= end_time, df)

if isempty(steady_state_df)
    error("选定时间区间 [$(start_time), $(end_time)] 内无有效数据点。")
end

# 3. 提取 ESR 辨识值序列
rc_hat = steady_state_df."highFreq_Rc_Observer.Rc_hat"

# 4. 执行统计学计算
mu_rc = mean(rc_hat)           # 均值
var_rc = var(rc_hat)           # 方差
std_rc = std(rc_hat)           # 标准差
cv_rc = (std_rc / mu_rc) * 100 # 变异系数 (CV, %)

# 5. 格式化报表输出
println("====================================================")
println("      Buck 变换器 ESR (Rc) 辨识稳定性量化分析")
println("====================================================")
@printf("分析区间:        %.2fs - %.2fs\n", start_time, end_time)
@printf("样本总数:        %d\n", length(rc_hat))
@printf("ESR 辨识均值 (μ): %.6f Ω\n", mu_rc)
@printf("----------------------------------------------------\n")
@printf("方差 (Variance):  %.6e\n", var_rc)
@printf("标准差 (Std):     %.6e\n", std_rc)
@printf("变异系数 (CV):    %.4f %%\n", cv_rc)
println("----------------------------------------------------\n")

# 6. 连贯性与可靠性判定报告
if cv_rc < 2.0
    println("稳定性结论: [极佳] Rc 辨识曲线平滑，成功抑制了电感电流纹波带来的高频噪声干扰。")
elseif cv_rc < 8.0
    println("稳定性结论: [良好] 辨识结果在物理合理范围内波动，可用于老化趋势预测。")
else
    println("稳定性结论: [波动较大] 建议检查 HighFreq_Rc_Observer 的截止频率 f_lp 设置。")
end
println("====================================================")