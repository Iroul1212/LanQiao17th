
# 🏭 基于 BBO 算法的 Buck 变换器参数性老化监测研究

> **第17届蓝桥杯 · 智能装备数字化建模大赛 参赛作品**

[![Modelica](https://img.shields.io/badge/Modelica-60.1%25-blue)](https://modelica.org/)
[![Julia](https://img.shields.io/badge/Julia-39.9%25-purple)](https://julialang.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

---

## 📋 项目简介

本项目针对 **DC-DC Buck 变换器** 在长期运行中因电容、电感、MOSFET 等关键器件 **参数性老化** 引发的可靠性问题，提出了一种基于 **生物地理学优化算法（Biogeography-Based Optimization, BBO）** 的全参数在线辨识与健康状态监测方法。获得选拔赛一等奖（决赛因故缺席

核心技术路径：

- 🧠 **BBO 全局优化算法** —— 在低采样率（SSR=4）、强噪声环境下精确辨识 $C$、 $L$、 $R_c$、 $R_s$ 四个关键参数
- 🪞 **高保真数字孪生模型** —— 基于 Modelica/MWORKS 构建包含热耦合、老化注入、噪声模拟的 Buck 变换器虚拟实体
- 📊 **实时 HMI 交互界面** —— 基于 Julia/Syslab 开发的健康状态监测仪表板

---

## 🗂️ 仓库结构

```
LanQiao17th/
├── MWORKS/                              # MWORKS 工程文件
│   ├── Sysplorer/                       # Modelica 系统仿真
│   │   ├── Block/
│   │   │   ├── Full_BBO_Optimizer.mo    # BBO 核心优化算法（Modelica实现）
│   │   │   └── HighFreq_Rc_Observer.mo  # 高频 ESR 观测器
│   │   ├── Buck_Digital_Twin/
│   │   │   ├── System_Buck_Twin.mo      # Buck 变换器数字孪生系统主模型
│   │   │   ├── AgingCapacitor.mo        # 电容老化模型（C衰减 + ESR增长）
│   │   │   ├── PrecisionInductor.mo     # 精密电感模型（含寄生电阻）
│   │   │   ├── ThermalSwitch_NoCaps.mo  # 热耦合开关模型
│   │   │   └── package.mo/package.order
│   │   └── Function/
│   │       └── LocalSearch_Pattern.mo   # BBO 局部搜索与精英保留策略
│   └── Syslab/                          # Julia 计算与HMI
│       ├── DTS_Controller_BBO.jl        # BBO 辨识主控程序
│       ├── Buck_Digital_Twin_HMI/       # 数字孪生人机界面
│       │   ├── app.jl                   # HMI 入口
│       │   ├── app.slapp                # Syslab 应用工程
│       │   └── Buck_Digital_Twin_System_Buck_Twin.fmu
│       └── app/                         # 可安装的 .slappinstall 包
│
├── 组件测试demo及算法文件/                # 组件级测试与算法验证
│   ├── Syslab/                          # Julia 测试脚本与数据
│   │   ├── Untitled-1~6.jl              # 分阶段算法验证脚本
│   │   ├── System_Buck_Twin_C.csv       # 电容值辨识结果数据
│   │   ├── System_Buck_Twin_Rc.csv      # ESR辨识结果数据
│   │   └── ...
│   └── Sysplorer/                       # Modelica 组件测试
│
├── 文件/                                # 文档资料
│   ├── 开题/                            # 开题报告（.docx/.md/.pdf/PPT）
│   ├── 论文/                            # 参考文献（14篇中英文论文）
│   └── 附件/                            # 竞赛规则与报告模板
│
├── 智能装备数字化建模大赛仿真分析报告.docx  # 最终仿真分析报告
├── 智能装备数字化建模大赛仿真分析报告.pdf   # 报告 PDF 版
└── 智能装备数字化建模大赛仿真分析报告_页面_01.jpg
```

---

## 🔬 核心技术

### 1. 问题建模

Buck 变换器非理想物理模型（含寄生参数）：

| 参数 | 含义 | 老化趋势 |
|------|------|----------|
| $C$ | 滤波电容 | 电解液干涸 → 衰减 |
| $R_c$ | 电容等效串联电阻 (ESR) | 逐渐增大 |
| $L$ | 滤波电感 | 磁芯老化 → 缓慢变化 |
| $R_s$ | 电感串联电阻 + 开关导通电阻 | 热疲劳 → 增大 |

### 2. BBO 优化算法

基于 **生物地理学群体智能** 的参数辨识框架：

- 🌍 **栖息地适应度指数（HSI）**：以模型输出与实测数据的误差作为代价函数
- 🐦 **迁移算子**：高 HSI 解向低 HSI 解共享参数特征
- 🧬 **变异算子**：维持种群多样性，防止早熟收敛
- 👑 **精英保留策略**：保护最优解不丢失
- 🔍 **局部搜索**：在最优解邻域精细寻优

### 3. 数字孪生架构

```
┌─────────────────────────────────────┐
│        物理实体 (Physical)           │
│   Buck Converter + ADC + Noise      │
└──────────────┬──────────────────────┘
               │ V_out, I_L (低采样率)
               ▼
┌─────────────────────────────────────┐
│       数字孪生 (Digital Twin)        │
│  ┌─────────────────────────────┐    │
│  │  Full_BBO_Optimizer         │    │
│  │  (C, L, Rc, Rs 在线辨识)     │    │
│  └──────────┬──────────────────┘    │
│             │ estimated params      │
│             ▼                       │
│  ┌─────────────────────────────┐    │
│  │  System_Buck_Twin           │    │
│  │  (Modelica 物理模型)         │    │
│  └──────────┬──────────────────┘    │
│             │                       │
│             ▼                       │
│  ┌─────────────────────────────┐    │
│  │  SOH Estimation             │    │
│  │  (健康状态评估 & RUL预测)     │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### 4. 关键技术指标

| 指标 | 数值 |
|------|------|
| 开关频率 $f_s$ | 20 kHz |
| 采样率 $f_{sample}$ | 5 kHz（SSR = 4） |
| 采样率与开关频率比 | **1/4**（低采样率条件） |
| 量测噪声 | ≥ 7 mV 高斯白噪声 |
| SOH 估计误差 | **< 5%** |
| 可辨识参数 | $C, L, R_c, R_s$ 四参数同步 |

---

## 🚀 快速开始

### 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| [MWORKS Sysplorer](https://www.tongyuan.cc/) | 2024+ | Modelica 系统建模仿真 |
| [MWORKS Syslab](https://www.tongyuan.cc/) | 2024+ | Julia 科学计算与 HMI |

> ℹ️ MWORKS 是同元软控（苏州同元）开发的系统级建模仿真平台，Sysplorer 用于 Modelica 建模，Syslab 用于 Julia 计算与交互界面开发。

### 运行步骤

1. **克隆仓库**

   ```bash
   git clone https://github.com/Iroul1212/LanQiao17th.git
   cd LanQiao17th
   ```

2. **打开 Sysplorer 工程**

   - 启动 MWORKS.Sysplorer
   - 打开 `MWORKS/Sysplorer/Buck_Digital_Twin/System_Buck_Twin.mo`
   - 该模型包含完整的 Buck 变换器回路、PID 控制器、老化注入模块与噪声源

3. **运行 BBO 辨识算法**

   - 编译 `System_Buck_Twin.mo` 导出 FMU
   - 启动 MWORKS.Syslab，打开 `MWORKS/Syslab/DTS_Controller_BBO.jl`
   - 运行脚本进行 BBO 在线参数辨识

4. **启动 HMI 监控界面**

   - 在 Syslab 中打开 `MWORKS/Syslab/Buck_Digital_Twin_HMI/app.jl`
   - 运行即可以图形界面实时查看 $C$、$R_c$ 等参数的老化趋势

---

## 📊 仿真结果摘要

在电容值从 **220μF → 110μF** 的线性老化过程中：

- ✅ BBO 算法在 5kHz 低采样率下精确跟踪电容老化轨迹
- ✅ 电容 ESR（$R_c$）的辨识误差控制在 5% 以内
- ✅ 在 7mV 以上高斯白噪声环境下保持稳定收敛
- ✅ 算法未出现早熟收敛，种群多样性良好

详细结果请参阅 [仿真分析报告](./智能装备数字化建模大赛仿真分析报告.pdf)。

---

## 📚 参考文献

本课题核心参考论文已收录于 `文件/论文/` 目录，包括但不限于：

1. **B. X. Li and K. S. Low**, "Low Sampling Rate Online Parameters Monitoring of DC-DC Converters for Predictive-Maintenance Using Biogeography-Based Optimization," *IEEE Trans. Power Electron.*, vol. 31, no. 4, 2016. ⭐ 核心参考
2. **H. Wang et al.**, "Toward reliable power electronics: Challenges, design tools, and opportunities," *IEEE Ind. Electron. Mag.*, 2013.
3. **S. Zhao and H. Wang**, "Enabling Data-Driven Condition Monitoring of Power Electronic Systems With Artificial Intelligence," *IEEE Power Electron. Mag.*, 2021.
4. 马铭遥 — "一种基于分数阶微积分的CCM Boost变换器准在线无源参数的数字孪生辨识方法"
5. 杨晓婷 — "基于数字孪生模型的DC-DC变换器状态监测方法研究"
6. 徐强 — "基于数字孪生的DC-DC变换器健康状态监测方法设计与实现"
7. 宫元凯 — "面向数字孪生的变流器关键元器件参数与状态监测技术研究"

共 14 篇中英文参考文献，完整列表见 `文件/论文/`。

---

## 📝 竞赛信息

- **赛事**：第17届蓝桥杯全国软件和信息技术专业人才大赛 — 数字科技创新赛（智能装备数字化建模赛道）
- **竞赛规则**：见 `文件/附件/附件2：第十七届蓝桥杯大赛数字科技创新赛（智能装备数字化建模）竞赛规则及说明.pdf`

---

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `文件/开题/开题报告.md` | 开题报告（推荐阅读，含完整研究方案） |
| `文件/开题/开题报告PPT.pdf` | 开题答辩 PPT |
| `智能装备数字化建模大赛仿真分析报告.pdf` | 最终仿真分析报告 |

---

## 📄 License

MIT © [Iroul1212](https://github.com/Iroul1212)

---

*Built with ❤️ using MWORKS.Sysplorer & MWORKS.Syslab*
