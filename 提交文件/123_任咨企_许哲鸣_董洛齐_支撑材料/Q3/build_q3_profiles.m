function profiles = build_q3_profiles()
% BUILD_Q3_PROFILES  构建 5 类典型工作生活方式画像。
% 风险等级按 q3_scoring_rules.csv 固定映射为 25/50/75/95 分。
% 分数越高表示该风险越突出。

profile_id = (1:5)';
profile_name = [
    "久坐办公型";
    "夜班熬夜型";
    "高压应酬型";
    "时间受限型";
    "饮食失衡型"];

sedentary_level = ["极高"; "高"; "高"; "高"; "中"];
sleep_level = ["中"; "极高"; "高"; "高"; "中"];
diet_level = ["高"; "高"; "极高"; "中"; "极高"];
stress_level = ["中"; "高"; "极高"; "高"; "中"];
time_level = ["高"; "极高"; "高"; "极高"; "中"];
monitoring_level = ["高"; "高"; "高"; "高"; "高"];

sedentary_risk = level_to_score(sedentary_level);
sleep_risk = level_to_score(sleep_level);
diet_risk = level_to_score(diet_level);
stress_risk = level_to_score(stress_level);
time_constraint = level_to_score(time_level);
monitoring_gap = level_to_score(monitoring_level);

profiles = table(profile_id, profile_name, sedentary_risk, sleep_risk, ...
    diet_risk, stress_risk, time_constraint, monitoring_gap, ...
    sedentary_level, sleep_level, diet_level, stress_level, ...
    time_level, monitoring_level);
end

function scores = level_to_score(levels)
scores = zeros(numel(levels), 1);
for i = 1:numel(levels)
    switch levels(i)
        case "低"
            scores(i) = 25;
        case "中"
            scores(i) = 50;
        case "高"
            scores(i) = 75;
        case "极高"
            scores(i) = 95;
        otherwise
            error('未知风险等级：%s', levels(i));
    end
end
end
