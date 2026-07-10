# 问题二 MATLAB 运行说明

## 一、运行前提

- MATLAB R2018b 或更高版本。
- 不需要 Statistics、Optimization 等额外工具箱。
- 保持本目录内的 `.m` 文件和四个输入CSV文件在一起。
- 本机尚未安装 MATLAB 或 Octave，因此这些MATLAB代码目前只完成了静态检查和Python独立复算，**尚未在真实MATLAB中运行**。

## 二、唯一运行入口

1. 在 MATLAB 的“当前文件夹”中打开：

   `D:\数学建模\matlab\q2\`

2. 在命令窗口输入：

```matlab
run_q2_all
```

程序会用 `mfilename('fullpath')` 自动定位自身目录，不需要修改代码中的路径。

## 三、运行后输出

数值文件写入 `output\`：

- `q2_critic_weights.csv`
- `q2_topsis_ranking.csv`
- `q2_sensitivity_results.csv`
- `q2_model_checks.csv`
- `q2_results.mat`
- `q2_run_log.txt`

运行结束后，MATLAB 会直接弹出3个可编辑图窗：

- 减肥失败作用机制图；
- 主要因素CRITIC-TOPSIS排序图；
- 排序稳健性分析热图。

程序不会自动保存 `.fig` 或PNG。请在图窗中调整文字、字体、颜色、位置和图例后，通过 MATLAB 图窗的“文件”菜单手动另存为 `.fig`，并按需要导出PNG。图中文字以中文为主；CRITIC、TOPSIS、Wilson、Laplace等方法名均带有中文解释。

## 四、正常完成的判断

1. 命令窗口显示 `Q2 completed`。
2. `output\q2_run_log.txt` 中的 `State` 为 `SUCCESS`。
3. `output\q2_model_checks.csv` 全部为 `PASS`。
4. 三个可编辑图窗均已弹出，中文显示正常。

MATLAB会将计算结果与Python预计算基准比较，权重和TOPSIS得分的最大误差必须不超过 `1e-8`，否则程序会停止并报告自检失败。

## 五、常见问题

- **中文显示为方框：** 新版程序会优先识别 `Microsoft YaHei`、`Microsoft YaHei UI`、`SimHei`、`Noto Sans CJK SC`、`PingFang SC` 等中文字体，不会再回退到不含中文字符的 `Arial`。若系统没有任何可用中文字体，程序会在开始计算前停止并提示安装或启用中文字体，避免生成不可用图片。
- **提示找不到输入CSV：** 确认四个CSV仍位于 `matlab\q2\`，不要单独移动 `run_q2_all.m`。
- **提示自检失败：** 不要手工改结果。查看 `output\q2_model_checks.csv` 和 `output\q2_run_log.txt`，确认输入CSV是否被修改。
- **图片已存在：** 再次运行会覆盖同名图片和数值输出，使其始终对应当前输入数据。

## 六、Python独立验证

本机已使用指定环境完成独立复算：

```powershell
& "C:\Users\QI\.agents\.venv_skillshare\Scripts\python.exe" "D:\数学建模\matlab\q2\verify_q2_python.py"
```

Python只生成预计算数值，不生成最终论文PNG。
