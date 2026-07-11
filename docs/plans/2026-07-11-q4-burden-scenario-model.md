# 问题四人口负担情景模型实施计划

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完成问题四的数据归档、DPSIR逻辑框架、人口负担情景模型、蒙特卡洛不确定性分析、MATLAB制图、论文写作与整篇编译验证。

**Architecture:** 以问题一逐年Logistic预测为主基准、Gompertz与饱和上限网格为结构稳健性边界；用联合国WPP 2024中国人口预测构造成人负担；以覆盖率、条件依从率和相对负担削减比例的低中高情景计算可避免人数。DPSIR仅组织风险和响应关系，不进行主观打分。

**Tech Stack:** MATLAB R2024a、Python 3.11（仅用于独立复算和包检查）、CSV/MAT/PNG、LaTeX/Tectonic。

---

### Task 1: 数据与来源归档

**Files:**
- Create: `数据来源/q4/WPP2024_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT.xlsx`
- Create: `数据来源/q4/q4_population_projection.csv`
- Create: `数据来源/q4/q4_scenario_parameters.csv`
- Create: `数据来源/q4/q4_source_manifest.csv`
- Create: `数据来源/q4/q4_evidence_notes.md`

1. 下载联合国WPP 2024官方紧凑人口表，记录下载URL、文件大小、SHA-256和口径。
2. 只提取中国、2024--2050年、中方案所需人口列；保留原始单位与转换后的“人”。
3. 将覆盖率、条件依从率和效果量全部标记为情景假设，记录下限、众数、上限和解释边界。
4. 核对年份连续、人口为正、单位换算无误。

### Task 2: 先写失败测试

**Files:**
- Create: `matlab/q4/tests/test_q4_pipeline.py`

1. 编写输入文件、年度范围、Q1锚点、情景恒等式、单调性、不确定性分位数、敏感性字段和图片存在性测试。
2. 运行测试，确认因Q4输出尚未生成而失败。

### Task 3: MATLAB数值流水线

**Files:**
- Create: `matlab/q4/run_q4_all.m`
- Create: `matlab/q4/load_q4_data.m`
- Create: `matlab/q4/build_q4_baseline.m`
- Create: `matlab/q4/run_q4_scenarios.m`
- Create: `matlab/q4/q4_uncertainty_analysis.m`
- Create: `matlab/q4/q4_model_checks.m`

1. 从问题一参数直接逐年计算Logistic与Gompertz，不对五年检查点线性插值。
2. 对每个K网格重新拟合两类S形模型，形成年度结构网格。
3. 计算基准负担、低中高点情景和2024--2030线性爬坡。
4. 以固定种子进行50000次三角分布抽样，分别输出主模型条件区间和联合结构情景区间。
5. 计算2030、2050年Spearman敏感性，并执行物理边界、恒等式和复现自检。

### Task 4: MATLAB中文制图与输出

**Files:**
- Create: `matlab/q4/plot_q4_dpsir.m`
- Create: `matlab/q4/plot_q4_burden.m`
- Create: `matlab/q4/plot_q4_scenarios.m`
- Create: `matlab/q4/plot_q4_sensitivity.m`
- Create: `figures/q4/*.png`
- Create: `matlab/q4/output/*`

1. 生成DPSIR中文传导框架图。
2. 生成预测率与基准人数上下分面图，避免双纵轴。
3. 生成基准与三种干预情景对比图。
4. 生成中情景2050年参数敏感性图。
5. 所有图采用中文标题、坐标、图例和单位，300dpi导出。

### Task 5: 独立复算与材料检查

**Files:**
- Create: `matlab/q4/q4_python_smoke_test.py`
- Create: `matlab/q4/check_q4_package.ps1`
- Create: `matlab/q4/README_运行说明.md`

1. Python独立重算Q1模型网格、点情景和蒙特卡洛分位数。
2. 读取MATLAB导出的共同随机数，不另造随机样本。
3. 检查全部CSV、MAT、日志和PNG存在且无NaN/Inf。
4. 运行MATLAB主入口、Python复算和PowerShell包检查，全部通过后进入论文写作。

### Task 6: 论文与公共章节联动

**Files:**
- Modify: `sections/q4.tex`
- Modify: `sections/analysis.tex`
- Modify: `sections/assumption.tex`
- Modify: `sections/symbols.tex`
- Modify: `sections/refs.tex`
- Modify: `sections/appendix.tex`

1. 写入研究边界、来源与参数类型、DPSIR、模型、关键数值、模拟区间、敏感性、典型危险与机会、局限性和本题小结。
2. 明确区分真实/预测数据、模型输出和情景假设；不使用“置信区间”“政策已实现效果”等错误表述。
3. 同步公共假设、符号、文献与附录清单；不修改摘要、关键词和综合模型评价。

### Task 7: 编译与目视验证

**Files:**
- Modify: `output/main.pdf`

1. 运行Tectonic编译，修复LaTeX错误、未定义引用和严重溢出。
2. 检查PDF大小、页数、问题四图表、中文标注、重叠和空白页。
3. 重跑Q4测试、MATLAB、Python复算、包检查和编译命令，记录新鲜验证证据。
