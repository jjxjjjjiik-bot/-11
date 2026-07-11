# 问题一模型修复 Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在保持五个已核实年份及数值不变的前提下，修正问题一的数据来源说明、稀疏样本建模、交叉验证、敏感性分析、图表和论文结论。

**Architecture:** 将五个观测点作为固定输入。主模型采用物理上限固定为100%的两参数Logistic，Gompertz作为模型结构稳健性对照；非等间距GM(1,1)不再承担预测结论。MATLAB负责正式计算和出图，Python测试独立复算关键结果，LaTeX只引用正式输出。

**Tech Stack:** MATLAB R2024a、Python 3.11 + NumPy/SciPy/Pandas、LaTeX + Tectonic。

---

### Task 1: 建立独立回归测试

**Files:**
- Create: `matlab/q1/tests/test_q1_pipeline.py`

1. 固定输入为年份`[1992, 2002, 2012, 2020, 2023]`和数值`[20.0, 29.9, 42.0, 50.7, 57.0]`。
2. 用SciPy独立复算固定上限Logistic和Gompertz的参数、拟合指标、LOO-CV与关键年份预测。
3. 要求MATLAB输出CSV与独立复算在数值容差内一致，并要求模型自检全部为PASS。
4. 首次运行应因正式输出不存在或仍是旧结构而失败。

### Task 2: 修正正式MATLAB流水线

**Files:**
- Modify: `matlab/q1/main_question1.m`
- Modify: `matlab/q1/logistic_fit.m`
- Modify: `matlab/q1/gompertz_fit.m`
- Modify: `matlab/q1/leave_one_out_cv.m`
- Modify: `matlab/q1/sensitivity_analysis.m`
- Create: `matlab/q1/output/*.csv`

1. 固定`K=100`，每个S形模型只估计两个参数。
2. 删除错误的三参数置信区间打印和静默回退逻辑。
3. LOO-CV每次使用4点重新拟合，记录逐点预测和汇总指标。
4. `K=75,80,...,100`敏感性场景中，每个K都重新拟合其余参数。
5. 导出模型结果、预测、LOO、敏感性和自检CSV，并输出5幅300 dpi PNG。

### Task 3: 同步问题一论文和公共章节

**Files:**
- Modify: `sections/q1.tex`
- Modify: `sections/analysis.tex`
- Modify: `sections/assumption.tex`
- Modify: `sections/symbols.tex`
- Modify: `sections/refs.tex`
- Modify: `sections/appendix.tex`

1. 五个数据点不变；将每个点的来源口径写清楚，2023年不得再写“综合公开报道”。
2. 用两参数模型公式、正式输出和正确的模型选择理由重写问题一。
3. 把主预测、模型结构差异、饱和上限敏感性分开解释，不把模型差异解释为政策因果效果。
4. 同步问题分析、假设、符号、参考文献和附录代码清单，不改问题二、问题三正文。

### Task 4: 完整验证

1. 运行MATLAB正式流水线。
2. 运行Python独立回归测试，要求全部通过。
3. 使用Tectonic编译`main.tex`到`output/main.pdf`。
4. 检查编译日志、PDF大小、更新时间和问题一页面图表。

