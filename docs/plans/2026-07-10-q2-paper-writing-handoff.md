# Q2 Paper Writing Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task.

**Goal:** Use the prepared Q2 evidence, verified CRITIC-TOPSIS results, and three supplied figures to write and integrate the complete Problem 2 section of the paper.

**Architecture:** Keep `sections/q2.tex` responsible only for Q2 exposition. Synchronize Q2-dependent shared content in `analysis.tex`, `assumption.tex`, `symbols.tex`, `refs.tex`, and `appendix.tex`; leave the abstract and cross-question evaluation untouched because Q3 and Q4 are incomplete.

**Tech Stack:** Chinese LaTeX (`ctex`), Tectonic, existing MATLAB/Python Q2 evidence package.

---

## Authoritative Inputs

- Q2 writing brief and verified results: `D:\数学建模\matlab\q2\q2_paper_inputs.md`
- 15-factor input data: `D:\数学建模\matlab\q2\q2_factor_evidence.csv`
- Supporting mechanism data: `D:\数学建模\matlab\q2\q2_supporting_evidence.csv`
- Source traceability: `D:\数学建模\matlab\q2\q2_source_manifest.csv`
- Exclusion rationale: `D:\数学建模\matlab\q2\q2_exclusion_log.csv`
- Numerical outputs: `D:\数学建模\matlab\q2\output\`
- Archived source materials: `D:\数学建模\数据来源\q2\`
- Final figures already supplied: `D:\数学建模\figures\q2\`
  - `减肥失败作用机制.png`
  - `减重维持因素排行.png`
  - `名词稳健性.png`

## Immutable Q2 Results

- The formal ranking contains exactly 15 comparable weight-loss-maintenance factors.
- Baseline CRITIC weights: study count `0.238194473347`, consistency `0.419561680818`, evidence level `0.342243845835`.
- Baseline TOPSIS top five: `M1`; `M2` and `M3` tied at rank 2; `M4` rank 4; `M5` rank 5.
- M4 must remain `n_studies=7`, `measurement_count=8`, `support_count=7`, and `consistency=0.875`; never call it eight studies.
- All six sensitivity scenarios retain five top-five factors; minimum Spearman correlation is `0.865245356821`.
- Time, family support, treatment dropout, disease, physiological compensation, and ACTION-China barriers are mechanism evidence only; they must not enter the 15-factor TOPSIS ranking.

## Scope Guardrails

Modify:

- `D:\数学建模\sections\q2.tex`
- `D:\数学建模\sections\analysis.tex`
- `D:\数学建模\sections\assumption.tex`
- `D:\数学建模\sections\symbols.tex`
- `D:\数学建模\sections\refs.tex`
- `D:\数学建模\sections\appendix.tex`
- `D:\数学建模\preamble.tex` only if equation numbering needs the required `section-equation` form.

Do not modify:

- `sections/q1.tex`, `sections/q3.tex`, `sections/q4.tex`
- `sections/intro.tex`
- `sections/evaluate.tex`
- the abstract and keyword placeholders in `main.tex`
- Q2 CSV data, archived sources, MATLAB/Python code, or supplied PNG files.

Before modifying `preamble.tex`, make a same-directory backup and verify the backup exists. Do not alter any user changes outside the stated scope.

## Task 1: Preflight and Image Check

1. Read `AGENTS.md`, all six Q2 input/output files above, `q2.tex`, shared sections, `main.tex`, `preamble.tex`, and the current Q1 writing style.
2. Open all three files in `figures/q2` and confirm that the text is readable Chinese, the figures are nonblank, and the displayed content matches the expected mechanism diagram, factor ranking, and sensitivity heatmap.
3. Use the exact existing filenames in LaTeX. Do not rename images merely for cosmetic reasons.
4. Verify all edited Chinese text remains UTF-8 after writing.

## Task 2: Write `sections/q2.tex`

Replace the placeholder with a complete Q2 chapter. Use the existing Q1 style: one `\section{}` followed by descriptive `\subsection{}` and `\subsubsection{}` headings, three-line tables, equation explanations, and citations as `\textsuperscript{[n]}`.

Required narrative order:

1. Problem-two objective and modeling boundary.
2. Evidence sources, inclusion rules, and the distinction between the 15-factor ranking and supplementary mechanism evidence.
3. Decision matrix construction:
   - `n_i`: number of studies;
   - consistency after unified direction;
   - evidence code `Strong=2`, `Moderate=1`;
   - explicit M4 explanation.
4. CRITIC objective weighting:
   - min-max normalization;
   - standard deviation, correlation conflict, information content, and weights;
   - define every symbol immediately after its formula.
5. TOPSIS ranking:
   - vector normalization;
   - weighted matrix;
   - positive/negative ideal solutions;
   - distances and closeness score;
   - competition ranking rule `1,2,2,4`.
6. Baseline result interpretation:
   - show all 15 factors in a table;
   - state the top five exactly;
   - explain that the result is evidence priority, not an individual causal probability.
7. Four-layer failure mechanism:
   - behavior, psychology, support environment, physiology;
   - cite supplementary evidence with the exact adherence, dropout, compensation, ACTION-China, and guideline numbers in `q2_paper_inputs.md`;
   - explicitly state these data do not enter TOPSIS.
8. Six-scenario sensitivity analysis:
   - Wilson, Laplace, log study count, equal weights, and no-evidence-level scenarios;
   - report Spearman range, top-five overlap, and the largest rank change;
   - interpret middle-rank instability without altering the data.
9. Q2 limitations and a concise Q2 conclusion.

Required tables:

- `tab:q2-sources`: source groups, use, and whether they enter the 15-factor ranking.
- `tab:q2-decision-matrix`: M1--M15, category, study count, consistency, and evidence code.
- `tab:q2-ranking`: CRITIC weights plus all TOPSIS scores and competition ranks, or separate the weights into a compact preceding table if readability requires it.
- `tab:q2-sensitivity`: six scenarios, weights, Spearman correlation, top-five overlap, and maximum rank change.

Required figures, each cited before it appears:

- `\label{fig:q2-mechanism}` with `减肥失败作用机制.png`, mechanism-analysis subsection.
- `\label{fig:q2-ranking}` with `减重维持因素排行.png`, after baseline TOPSIS results.
- `\label{fig:q2-sensitivity}` with `名词稳健性.png`, sensitivity-analysis subsection.

Use `\includegraphics[width=0.85\textwidth]{...}` by default; use a wider but safe width only if the heatmap labels require it. Captions must not manually contain “图2.1”; LaTeX numbering supplies it.

## Task 3: Synchronize Shared TeX Files

1. `analysis.tex`: replace the placeholder with a concise Q2 analysis subsection. Explain why evidence comparability requires 15-factor formal ranking and why other evidence is mechanism-only.
2. `assumption.tex`: preserve existing valid assumptions and add the six Q2 assumptions from `q2_paper_inputs.md`; do not invent facts for Q1.
3. `symbols.tex`: keep Q1 symbols and add only necessary Q2 symbols without duplicates: `x_{ij}`, `z_{ij}`, `\sigma_j`, `r_{jk}`, `C_j`, `w_j`, `v_{ij}`, `A^+`, `A^-`, `D_i^+`, `D_i^-`, and `S_i`.
4. `refs.tex`: preserve references 1--10 and append Q2 references in order. Include the main systematic review, adherence meta-analysis, dropout review, Hall and Kahan review, ACTION-China, both 2024 national guidelines, CRITIC, and TOPSIS. Use the project’s manual `\bibitem{refN}` format and correct `[J]`, `[R]`, or `[M]` type tags. Match every Q2 superscript number to the final bibliography.
5. `appendix.tex`: preserve Q1 entries and add the complete Q2 executable code inventory: `run_q2_all.m`, `load_q2_data.m`, `critic_weights.m`, `topsis_rank.m`, `rank_with_ties.m`, `spearman_rank.m`, `wilson_lower_bound.m`, `sensitivity_analysis_q2.m`, `plot_q2_mechanism.m`, `plot_q2_ranking.m`, `plot_q2_sensitivity.m`, `self_check_q2.m`, and `choose_q2_chinese_font.m`. List the four input CSV files and Q2 numerical outputs as supporting materials.
6. If necessary, minimally configure equation numbering as `(\thesection-\arabic{equation})` in `preamble.tex`, then re-check Q1 and Q2 equation formatting.

## Task 4: Compile and Inspect

1. Compile from `D:\数学建模`:

```powershell
& "C:\Users\QI\.codex\plugins\cache\openai-bundled\latex\0.2.4\bin\tectonic.exe" -X compile --print main.tex --outdir output
```

2. Fix hard errors only. Fontconfig notices and first-pass reference warnings are non-fatal only if `output/main.pdf` was refreshed.
3. Compile again if references or layout require it.
4. Inspect the Q2 pages of `output/main.pdf` for:
   - all three figures visible and readable;
   - no undefined references;
   - no missing images;
   - no table overflow, clipped captions, or large blank areas;
   - formula, figure, and table numbering consistent with the paper.
5. Verify the PDF is at `D:\数学建模\output\main.pdf`, has been refreshed, and remains below 20 MB.

## Completion Checklist

- Q2 is complete and numerically faithful to `q2_paper_inputs.md`.
- The three figures are cited and correctly placed.
- All five shared TeX files are synchronized.
- The abstract and `evaluate.tex` remain untouched.
- All source data remain unchanged.
- `output/main.pdf` compiles and visually passes Q2 inspection.
- Final response lists modified files, the compilation result, and any residual limitation. Do not claim MATLAB itself was run locally unless it was actually run.

## Copyable New-Chat Prompt

```text
在 D:\数学建模 中完成“问题二论文撰写与全局联动”，不要只写 q2.tex 后就停止。先完整阅读 AGENTS.md、sections/q1.tex、main.tex、preamble.tex，以及以下问题二资料：

- matlab\q2\q2_paper_inputs.md（唯一数值写作依据）
- matlab\q2\q2_factor_evidence.csv
- matlab\q2\q2_supporting_evidence.csv
- matlab\q2\q2_source_manifest.csv
- matlab\q2\q2_exclusion_log.csv
- matlab\q2\output\ 下的全部数值结果
- 数据来源\q2\ 下的归档材料
- figures\q2\ 下的三张最终PNG：减肥失败作用机制.png、减重维持因素排行.png、名词稳健性.png

先打开并检查三张图片中文是否正常、内容是否与机制图/因素排序图/稳健性热图对应；图片有问题就报告，不要擅自重画。图片正常则直接实施，不要只给方案。

修改范围：
1. 完整写 sections/q2.tex；
2. 同步更新 sections/analysis.tex、sections/assumption.tex、sections/symbols.tex、sections/refs.tex、sections/appendix.tex；
3. 仅在实现章节-公式编号确有必要时，备份后最小修改 preamble.tex。

禁止修改：sections/q1.tex、sections/q3.tex、sections/q4.tex、sections/intro.tex、sections/evaluate.tex、main.tex 中摘要和关键词、任何问题二CSV/源文件/MATLAB代码/PNG图片。q3/q4尚未完成，不能提前写摘要和综合评价。

问题二必须严格使用以下口径：
- 正式CRITIC-TOPSIS排序只有15项同口径减重维持因素；
- 时间、家庭支持、治疗退出、疾病、生理代偿、ACTION-China管理障碍只作机制分析，绝不混入15项排序；
- 指标为研究数量、方向一致率、证据等级，Strong=2、Moderate=1；
- M4必须写成7篇研究、8次方向判断、7次支持、一致率0.875，不能误写为8篇研究；
- CRITIC权重必须是：0.238194473347、0.419561680818、0.342243845835；
- 前五必须为M1第一，M2和M3并列第二，M4第四，M5第五；
- 六场景敏感性前五重合均为5，最低Spearman为0.865245356821；
- 排名使用1,2,2,4的竞赛排名；TOPSIS分数是证据优先级，不是个体因果概率。

q2.tex至少包括：数据来源与纳入规则；15项决策矩阵和M4说明；CRITIC公式；TOPSIS公式；基准结果；四层失败机制；六场景灵敏度分析；局限性和本题结论。每个公式后解释新增变量。至少放置来源表、决策矩阵表、TOPSIS结果表、灵敏度表；三个图必须先在正文引用再插入，标签建议使用 fig:q2-mechanism、fig:q2-ranking、fig:q2-sensitivity。图题不要手写“图2.1”，使用LaTeX自动编号。

参考文献延续当前 refs.tex 的手工编号和 \textsuperscript{[n]} 引用格式，保留原有1--10条，在后面增加主系统综述、依从性Meta分析、退出综述、生理代偿综述、ACTION-China、两份2024国家卫健委指南、CRITIC、TOPSIS等问题二文献，并确保引用编号准确。

附录必须在保留问题一代码清单的基础上，补齐 matlab\q2\ 的全部可运行MATLAB文件、四个输入CSV和数值输出清单。符号表必须保留问题一符号并补充Q2符号；假设和问题分析同理更新而非只追加占位文字。

所有图表使用三线表、正文引用、学术中文；关键结论必须给出数值，不要空泛表述。写完后用：
& "C:\Users\QI\.codex\plugins\cache\openai-bundled\latex\0.2.4\bin\tectonic.exe" -X compile --print main.tex --outdir output
编译，修复硬错误并检查 output/main.pdf 中问题二页面的图片、表格、编号、引用和排版。最终汇报修改文件、编译结果和未能验证的事项；不得声称本机运行过MATLAB。
```
