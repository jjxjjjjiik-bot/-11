function plans = q3_apply_safety_constraints(plans, paramMap)
% Q3_APPLY_SAFETY_CONSTRAINTS  用指南约束筛选安全候选方案。
% 未通过安全闸门的方案仍保留在方案表中，但不进入 TOPSIS 排序。

if get_param(paramMap, 'P29') ~= 1
    error('指南范围初筛未启用。请检查参数 P29。');
end

energyMin = get_param(paramMap, 'P08');
energyMax = get_param(paramMap, 'P09');
aerobicMin = get_param(paramMap, 'P14');
aerobicMax = get_param(paramMap, 'P15');
strengthMin = get_param(paramMap, 'P16');
strengthMax = get_param(paramMap, 'P17');
sleepTarget = get_param(paramMap, 'P20');

isSafe = false(height(plans), 1);
reason = strings(height(plans), 1);

for i = 1:height(plans)
    failures = strings(0, 1);
    if plans.energy_deficit_kcal_day(i) < energyMin || plans.energy_deficit_kcal_day(i) > energyMax
        failures(end+1, 1) = "膳食能量摄入削减量不在 500-1000 kcal/day 内";
    end
    if plans.aerobic_min_week(i) < aerobicMin || plans.aerobic_min_week(i) > aerobicMax
        failures(end+1, 1) = "有氧运动不在 150-300 min/week 内";
    end
    if plans.strength_days_week(i) < strengthMin || plans.strength_days_week(i) > strengthMax
        failures(end+1, 1) = "抗阻训练不在 2-3 day/week 内";
    end
    if plans.sleep_hours_target(i) < sleepTarget
        failures(end+1, 1) = "睡眠目标不足 7 hour/day";
    end

    isSafe(i) = isempty(failures);
    if isSafe(i)
        reason(i) = "通过";
    else
        reason(i) = strjoin(failures, "；");
    end
end

plans.is_safe = isSafe;
plans.safety_gate_result = reason;
end

function value = get_param(paramMap, parameterId)
if ~isKey(paramMap, parameterId)
    error('缺少参数：%s。请检查 q3_parameter_table.csv。', parameterId);
end
value = paramMap(parameterId);
end
