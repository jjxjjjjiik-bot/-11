# 问题三 MATLAB 运行说明

本目录用于“问题三资料与代码准备”。代码只生成 CSV、MAT、TXT 等结果文件，并打开 3 个 MATLAB 图形窗口；不会自动导出 PNG/JPG。

## 运行入口

在 MATLAB 中打开并运行：

```matlab
D:\数学建模\matlab\q3\run_q3_all.m
```

或在 MATLAB 命令行输入：

```matlab
cd('D:\数学建模\matlab\q3')
run_q3_all
```

## 运行前检查

请确认以下文件存在：

- `D:\数学建模\数据来源\q3\q3_parameter_table.csv`
- `D:\数学建模\数据来源\q3\q3_source_manifest.csv`
- `D:\数学建模\matlab\q3\run_q3_all.m`

代码使用 UTF-8 编码的 CSV 文件。Windows 版 MATLAB 一般可以正常读取；如果命令行显示中文不完整，不影响 CSV 结果和图窗标题。

## 运行后自动输出

输出目录：

```text
D:\数学建模\matlab\q3\output\
```

运行后会生成：

- `q3_profile_scores.csv`
- `q3_plan_scores.csv`
- `q3_plan_ranking.csv`
- `q3_parameter_table_used.csv`
- `q3_scoring_rules_used.csv`
- `q3_model_checks.csv`
- `q3_weight_sensitivity.csv`
- `q3_weight_sensitivity_summary.csv`
- `q3_run_log.txt`
- `q3_results.mat`

## 需要手动导出的 3 张图

运行 `run_q3_all.m` 后会打开 3 个图形窗口：

1. `问题三-典型生活方式画像雷达图`
2. `问题三-各画像候选方案组内得分`
3. `问题三-15套候选方案失败因素覆盖热图`

请在 MATLAB 图形窗口中手动导出 PNG。代码中没有 `saveas`、`exportgraphics`、`print` 等自动导图命令。

## 字体与排版

绘图函数会优先使用 `Microsoft YaHei`（微软雅黑），如果当前 MATLAB 找不到该字体，会依次尝试 `SimHei`、`SimSun`，最后才使用 MATLAB 默认字体。

为了避免文字重叠，图窗默认使用较大尺寸，标题、标签和数值标注都设置了较大的字号。导出 PNG 时建议选择较高分辨率。

## 运行后请发回

请把以下结果发回给 AI，用于后续按 AGENTS.md 写论文：

- `D:\数学建模\matlab\q3\output\q3_plan_ranking.csv`
- `D:\数学建模\matlab\q3\output\q3_plan_scores.csv`
- `D:\数学建模\matlab\q3\output\q3_model_checks.csv`
- `D:\数学建模\matlab\q3\output\q3_weight_sensitivity_summary.csv`
- 手动导出的 3 张 PNG 图片

建议同时发回 `q3_weight_sensitivity.csv`，便于后续核对每一个权重扰动情景。

## 注意

本模型用于数学建模中的方案比较，不是医学诊断或个体化处方。药物治疗、代谢手术、极低能量饮食等必须由医生评估，本代码不生成此类方案。

模型先进行四项指南范围初筛：膳食能量摄入削减量、有氧运动、抗阻训练和睡眠目标不满足所选范围的方案不会进入 TOPSIS 排名。该初筛没有使用个体基础能量需要量、性别和实际总摄入量，不能替代临床安全评估。画像风险、失败因素覆盖和可执行性评分规则见：

```text
D:\数学建模\数据来源\q3\q3_scoring_rules.csv
```

候选集中不再使用通用“综合平衡型”，而是为每类画像设置 3 套针对性方案。TOPSIS 使用减重效果、可执行性、长期坚持性、失败因素覆盖度、画像匹配度和时间负担 6 个指标。画像匹配度只复用现有画像风险、方案覆盖度、睡眠措施和时间负担计算。

权重敏感性分析会对 6 个 TOPSIS 指标分别进行 `-20%` 和 `+20%` 单项扰动：被扰动项固定为基准权重的 80% 或 120%，其余权重按原相对比例重新分配后重算排序。每类画像共 12 个情景，总计 60 个情景。
