# 问题二数据与 MATLAB 交付 Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use test-driven-development and verification-before-completion task by task.

**Goal:** 完成问题二的来源归档、15因素证据矩阵、CRITIC-TOPSIS与六场景灵敏度复算、MATLAB R2018b代码和论文写作输入，但不修改任何 `sections/*.tex`。

**Architecture:** 原始文献和官方资料保存在 `数据来源/q2/`，可计算输入与MATLAB程序保存在 `matlab/q2/`。Python审计脚本先验证数据契约并独立复算，MATLAB入口 `run_q2_all.m` 使用相同公式重新计算、导出CSV/MAT和三张PNG。

**Tech Stack:** CSV、Markdown、Python 3（仅独立验证）、MATLAB R2018b兼容语法、PowerShell下载与哈希核验。

---

### Task 1: 建立来源归档与清单

**Files:**
- Create: `数据来源/q2/*`
- Create: `matlab/q2/q2_source_manifest.csv`

**Steps:**
1. 从官方期刊、PMC、国家卫生健康委等可验证地址下载资料。
2. 保存原始文件名、编号、URL、DOI、页码/表号和SHA256。
3. 验证 `q2论文.zip` 的哈希未变化，并将其标记为不纳入支撑材料。

### Task 2: 建立可追溯数据表

**Files:**
- Create: `matlab/q2/q2_factor_evidence.csv`
- Create: `matlab/q2/q2_supporting_evidence.csv`
- Create: `matlab/q2/q2_exclusion_log.csv`

**Steps:**
1. 从主系统综述原始表格逐项提取15因素。
2. 分开记录研究篇数与方向判断次数，重点验证M4。
3. 将依从性、退出、生理代偿、中国情境写入补充表。
4. 将年龄、性别、社会环境、疾病等写入排除表并说明理由。

### Task 3: 先写失败的Python审计测试

**Files:**
- Create: `matlab/q2/tests/test_q2_pipeline.py`
- Create: `matlab/q2/verify_q2_python.py`

**Steps:**
1. 先写数据完整性、CRITIC、TOPSIS、并列排名、Spearman、六场景输出测试。
2. 在实现脚本前运行测试，确认因缺少实现而失败。
3. 实现独立复算并使测试通过。

### Task 4: 编写MATLAB计算与绘图程序

**Files:**
- Create: `matlab/q2/run_q2_all.m`
- Create: `matlab/q2/load_q2_data.m`
- Create: `matlab/q2/critic_weights.m`
- Create: `matlab/q2/topsis_rank.m`
- Create: `matlab/q2/rank_with_ties.m`
- Create: `matlab/q2/spearman_rank.m`
- Create: `matlab/q2/wilson_lower_bound.m`
- Create: `matlab/q2/sensitivity_analysis_q2.m`
- Create: `matlab/q2/plot_q2_mechanism.m`
- Create: `matlab/q2/plot_q2_ranking.m`
- Create: `matlab/q2/plot_q2_sensitivity.m`
- Create: `matlab/q2/self_check_q2.m`

**Steps:**
1. 使用R2018b兼容接口和自实现统计函数。
2. 入口自动定位自身目录并创建输出目录。
3. 输出指定CSV、MAT、日志和三张300dpi PNG。

### Task 5: 生成预计算结果与写作输入

**Files:**
- Create: `matlab/q2/output/q2_critic_weights.csv`
- Create: `matlab/q2/output/q2_topsis_ranking.csv`
- Create: `matlab/q2/output/q2_sensitivity_results.csv`
- Create: `matlab/q2/output/q2_model_checks.csv`
- Create: `matlab/q2/output/q2_results.mat`
- Create: `matlab/q2/output/q2_run_log.txt`
- Create: `matlab/q2/q2_paper_inputs.md`
- Create: `matlab/q2/README_运行说明.md`

**Steps:**
1. 运行Python独立复算生成预计算结果。
2. 汇总输入矩阵、权重、排名、灵敏度、证据、限制和图表写作建议。
3. 明确三张PNG尚需在真实MATLAB环境生成。

### Task 6: 最终审计

**Steps:**
1. 运行完整Python测试和文件契约检查。
2. 检查所有CSV编码、字段、缺失值和来源可追溯性。
3. 对比不可修改的6个section文件哈希。
4. 对比 `q2论文.zip` 哈希和大小。
5. 明确MATLAB代码未在真实MATLAB或Octave中运行。
