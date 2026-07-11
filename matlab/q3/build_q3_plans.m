function plans = build_q3_plans(profiles, paramMap)
% BUILD_Q3_PLANS  构建 5 类画像各 3 套针对性候选方案。
% 所有数值均通过所选四项指南范围初筛；方案细节属于专家规则细化。

baselineWeightKg = get_param(paramMap, 'P03');
kcalPerKg = get_param(paramMap, 'P27');
periodDays = round(get_param(paramMap, 'P05') * 30);
targetMinKg = baselineWeightKg * get_param(paramMap, 'P06') / 100;
targetMaxKg = baselineWeightKg * get_param(paramMap, 'P07') / 100;

specCells = cell(height(profiles), 3);
planTypeCells = cell(height(profiles), 1);
allTimeBurden = zeros(height(profiles) * 3, 1);
timeIndex = 0;

for i = 1:height(profiles)
    [planTypes, specs] = profile_plan_specs(profiles.profile_name(i));
    planTypeCells{i} = planTypes;
    for j = 1:3
        specCells{i, j} = specs{j};
        timeIndex = timeIndex + 1;
        allTimeBurden(timeIndex) = specs{j}.time_burden_min_day;
    end
end

timeMin = min(allTimeBurden);
timeMax = max(allTimeBurden);
rows = {};

for i = 1:height(profiles)
    profile = profiles(i, :);
    planTypes = planTypeCells{i};

    for j = 1:3
        spec = specCells{i, j};
        planType = planTypes(j);

        dietLossKg = spec.energy_deficit_kcal_day * periodDays / kcalPerKg;
        exerciseLossKg = spec.aerobic_min_week * 6.0 * 4.345 * ...
            get_param(paramMap, 'P05') / kcalPerKg;
        rawLossKg = 0.35 * dietLossKg + 0.45 * exerciseLossKg;
        expectedLossKg = min(max(rawLossKg, targetMinKg * 0.70), targetMaxKg);

        effectScore = min(100, 100 * expectedLossKg / targetMaxKg);
        feasibilityScore = compute_feasibility_score(spec, profile);
        persistenceScore = compute_persistence_score(spec, profile);
        coverageVector = [ ...
            spec.cover_activity, spec.cover_energy, spec.cover_monitoring, ...
            spec.cover_unhealthy_food, spec.cover_fruit_veg];
        failureCoverageScore = mean(coverageVector) * 100;
        timeAdaptationScore = reverse_time_score( ...
            spec.time_burden_min_day, timeMin, timeMax);
        profileMatchScore = compute_profile_match_score( ...
            spec, profile, timeAdaptationScore);

        rows(end+1, :) = { ...
            sprintf('P%d_%d', profile.profile_id, j), profile.profile_id, ...
            string(profile.profile_name), string(planType), ...
            spec.energy_deficit_kcal_day, spec.aerobic_min_week, ...
            spec.strength_days_week, spec.monitoring_days_week, ...
            spec.sleep_hours_target, spec.sleep_action_score, ...
            spec.diet_structure_score, spec.time_burden_min_day, ...
            timeAdaptationScore, expectedLossKg, effectScore, ...
            feasibilityScore, persistenceScore, failureCoverageScore, ...
            profileMatchScore, spec.cover_activity, spec.cover_energy, ...
            spec.cover_monitoring, spec.cover_unhealthy_food, ...
            spec.cover_fruit_veg, string(spec.plan_summary)};
    end
end

plans = cell2table(rows, 'VariableNames', { ...
    'plan_id','profile_id','profile_name','plan_type', ...
    'energy_deficit_kcal_day','aerobic_min_week','strength_days_week', ...
    'monitoring_days_week','sleep_hours_target','sleep_action_score', ...
    'diet_structure_score','time_burden_min_day','time_adaptation_score', ...
    'expected_loss_kg_6m','effect_score','feasibility_score', ...
    'persistence_score','failure_coverage_score','profile_match_score', ...
    'cover_activity','cover_energy','cover_monitoring', ...
    'cover_unhealthy_food','cover_fruit_veg','plan_summary'});
end

function [planTypes, specs] = profile_plan_specs(profileName)
switch profileName
    case "久坐办公型"
        planTypes = [ ...
            "久坐中断与步行激活型";
            "下班有氧强化型";
            "能量控制与饮食记录型"];
        specs = {
            create_spec(600, 240, 2, 6, 78, 80, 42, ...
                [1, 0.5, 1, 0.5, 0.5], ...
                "每坐 60 分钟起身活动 3-5 分钟，工作日安排午间步行，并记录久坐中断完成情况。");
            create_spec(550, 300, 3, 4, 70, 72, 64, ...
                [1, 0.5, 0.5, 0, 0.5], ...
                "以每周 300 分钟有氧和 3 次抗阻为主，下班后分次完成，饮食保持保守的膳食能量摄入削减量。");
            create_spec(750, 150, 2, 7, 70, 92, 48, ...
                [0.5, 1, 1, 1, 1], ...
                "逐日记录总能量和体重，替换甜食油炸快餐并增加蔬菜全谷物，运动保持指南下限。")
        };

    case "夜班熬夜型"
        planTypes = [ ...
            "睡眠窗口与夜间餐次管理型";
            "夜间加餐能量管理型";
            "低负担活动安排型"];
        specs = {
            create_spec(620, 180, 2, 6, 95, 82, 32, ...
                [0.5, 0.5, 1, 0.5, 0.5], ...
                "按班次固定不少于 7 小时睡眠窗口，夜班日采用 3+1 餐次并记录夜间进食。");
            create_spec(720, 150, 2, 7, 88, 90, 40, ...
                [0.5, 1, 1, 1, 0.5], ...
                "预先准备低能量夜间加餐，控制含糖饮料和高油宵夜，并记录夜班总能量。");
            create_spec(550, 210, 2, 4, 82, 72, 44, ...
                [1, 0.5, 0.5, 0, 0.5], ...
                "在交接班前后安排短时快走和每周 2 次抗阻，避免用高负担训练进一步挤压睡眠。")
        };

    case "高压应酬型"
        planTypes = [ ...
            "应酬饮食与饮酒管理型";
            "压力调节与体重监测型";
            "应酬后补偿活动型"];
        specs = {
            create_spec(750, 150, 2, 6, 78, 94, 40, ...
                [0.5, 1, 1, 1, 1], ...
                "应酬前定量加餐，席间优先蔬菜和优质蛋白、限制酒精，应酬后记录外食能量。");
            create_spec(600, 150, 2, 7, 88, 80, 32, ...
                [0.5, 0.5, 1, 0.5, 0.5], ...
                "通过固定称重、饮食记录和睡眠窗口形成反馈，并用低负担活动缓解压力性进食。");
            create_spec(550, 270, 3, 4, 70, 72, 58, ...
                [1, 0.5, 0.5, 0, 0.5], ...
                "应酬次日不极端节食，采用快走和抗阻补足周活动量，同时保持保守的膳食能量摄入削减量。")
        };

    case "时间受限型"
        planTypes = [ ...
            "碎片运动与周末备餐型";
            "外卖能量管理型";
            "最小时间监测型"];
        specs = {
            create_spec(650, 210, 2, 5, 78, 86, 34, ...
                [1, 0.5, 0.5, 0.5, 1], ...
                "每日安排 3 次 10-15 分钟碎片化运动，周末集中备餐并预留蔬菜和优质蛋白。");
            create_spec(700, 150, 2, 5, 72, 90, 28, ...
                [0.5, 1, 0.5, 1, 0.5], ...
                "外卖按主食、蛋白和蔬菜定量选择，减少油炸和含糖饮料，运动保持指南下限。");
            create_spec(550, 150, 2, 7, 72, 74, 26, ...
                [0.5, 0.5, 1, 0.5, 0.5], ...
                "用手机完成每日体重和饮食简记，以最少记录时间维持反馈，活动按周累计完成。")
        };

    case "饮食失衡型"
        planTypes = [ ...
            "高糖高油替换型";
            "果蔬全谷提升型";
            "总能量记录与份量控制型"];
        specs = {
            create_spec(750, 150, 2, 5, 68, 96, 38, ...
                [0.5, 1, 0.5, 1, 0.5], ...
                "用低糖低油食物替换甜食、油炸和快餐，保持每日膳食能量摄入削减量并记录替换完成率。");
            create_spec(650, 150, 2, 4, 72, 96, 42, ...
                [0.5, 0.5, 0.5, 0.5, 1], ...
                "保证每日蔬菜 300-500 克并增加全谷杂豆，以食物结构改善为主要抓手。");
            create_spec(700, 150, 2, 7, 68, 90, 34, ...
                [0.5, 1, 1, 0.5, 0.5], ...
                "记录总能量和份量，固定餐具与进餐份量，通过每日称重反馈调整摄入。")
        };

    otherwise
        error('未知画像：%s', profileName);
end
end

function spec = create_spec(energyDeficit, aerobicMinutes, strengthDays, ...
    monitoringDays, sleepActionScore, dietStructureScore, timeBurden, ...
    coverage, summary)
spec = struct();
spec.energy_deficit_kcal_day = energyDeficit;
spec.aerobic_min_week = aerobicMinutes;
spec.strength_days_week = strengthDays;
spec.monitoring_days_week = monitoringDays;
spec.sleep_hours_target = 7;
spec.sleep_action_score = sleepActionScore;
spec.diet_structure_score = dietStructureScore;
spec.time_burden_min_day = timeBurden;
spec.cover_activity = coverage(1);
spec.cover_energy = coverage(2);
spec.cover_monitoring = coverage(3);
spec.cover_unhealthy_food = coverage(4);
spec.cover_fruit_veg = coverage(5);
spec.plan_summary = summary;
end

function score = compute_feasibility_score(spec, profile)
timeRisk = profile.time_constraint / 100;
sleepRisk = profile.sleep_risk / 100;
stressRisk = profile.stress_risk / 100;

burdenPenalty = max(0, spec.time_burden_min_day - 30) * ...
    (0.20 + 0.35 * timeRisk);
sleepFit = spec.sleep_action_score / 100 * (5 + 5 * sleepRisk);
monitoringFit = spec.monitoring_days_week / 7 * 8;
score = 84 - burdenPenalty - 7 * stressRisk + sleepFit + monitoringFit;
score = max(0, min(100, score));
end

function score = compute_persistence_score(spec, profile)
monitoring = spec.monitoring_days_week / 7 * 100;
stressRisk = profile.stress_risk / 100;
score = 48 + 0.18 * monitoring + 0.18 * spec.sleep_action_score + ...
    0.14 * spec.diet_structure_score - ...
    max(0, spec.time_burden_min_day - 45) * 0.35 - 8 * stressRisk;
score = max(0, min(100, score));
end

function score = reverse_time_score(timeBurden, timeMin, timeMax)
if timeMax <= timeMin
    score = 100;
else
    score = 100 * (timeMax - timeBurden) / (timeMax - timeMin);
end
score = max(0, min(100, score));
end

function score = compute_profile_match_score(spec, profile, timeAdaptationScore)
dietAction = mean([ ...
    spec.cover_energy, spec.cover_unhealthy_food, spec.cover_fruit_veg]);
numerator = ...
    profile.sedentary_risk * spec.cover_activity + ...
    profile.diet_risk * dietAction + ...
    profile.monitoring_gap * spec.cover_monitoring + ...
    profile.sleep_risk * spec.sleep_action_score / 100 + ...
    profile.time_constraint * timeAdaptationScore / 100;
denominator = profile.sedentary_risk + profile.diet_risk + ...
    profile.monitoring_gap + profile.sleep_risk + profile.time_constraint;

score = 100 * numerator / denominator;
score = max(0, min(100, score));
end

function value = get_param(paramMap, parameterId)
if ~isKey(paramMap, parameterId)
    error('缺少参数：%s。请检查 q3_parameter_table.csv。', parameterId);
end
value = paramMap(parameterId);
end
