# 问题四运行说明

## 一键运行

```powershell
& "D:\Matla R2024a\bin\matlab.exe" -batch "cd('D:/数学建模/matlab/q4'); run_q4_all"
```

主程序会重新拟合问题一的Logistic与Gompertz模型，计算2024--2050年基准负担和低、中、高点情景，完成50000次蒙特卡洛模拟、自检，并自动覆盖导出4张300dpi中文PNG。

## 重新提取人口数据

```powershell
& "C:\Users\QI\.agents\.venv_skillshare\Scripts\python.exe" ".\matlab\q4\prepare_q4_inputs.py"
```

该脚本从`数据来源/q4/WPP2024_PopulationBySingleAgeSex_Medium_2024-2100.csv.gz`流式提取中国、2024--2050年、18岁及以上、中方案人口，生成`q4_population_projection.csv`。

## 独立核验

```powershell
& "C:\Users\QI\.agents\.venv_skillshare\Scripts\python.exe" ".\matlab\q4\q4_python_smoke_test.py"
& "C:\Users\QI\.agents\.venv_skillshare\Scripts\python.exe" -m unittest ".\matlab\q4\tests\test_q4_pipeline.py" -v
& ".\matlab\q4\check_q4_package.ps1"
```

Python脚本使用SciPy独立重新拟合两类模型，读取MATLAB导出的共同随机数复算情景和模拟分位数。PowerShell脚本检查输入、代码、输出和图片是否齐全。

## 口径边界

- WPP人口是7月1日年中预测，不是国家统计局年末观测值。
- 低、中、高覆盖率、条件依从率和干预效果均为情景假设。
- 模拟区间不是统计置信区间。
- 可避免人数是该年相对基准减少的现患人数，不是治愈人数，也不能跨年相加后仍称人数。
