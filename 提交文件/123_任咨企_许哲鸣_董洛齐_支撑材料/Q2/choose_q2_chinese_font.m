function fontName = choose_q2_chinese_font()
%CHOOSE_Q2_CHINESE_FONT Find an installed font with Chinese glyphs.

override = strtrim(getenv('Q2_CHINESE_FONT'));
candidates = {
    override;
    'Microsoft YaHei';
    'Microsoft YaHei UI';
    'SimHei';
    'SimSun';
    'NSimSun';
    'DengXian';
    'KaiTi';
    'FangSong';
    'Noto Sans CJK SC';
    'Noto Serif CJK SC';
    'Source Han Sans SC';
    'Source Han Sans CN';
    'WenQuanYi Zen Hei';
    'PingFang SC';
    'Heiti SC';
    'Songti SC';
    'STHeiti';
    'Arial Unicode MS'
};

available = listfonts;
for i = 1:numel(candidates)
    candidate = candidates{i};
    if ~isempty(candidate) && any(strcmpi(available, candidate))
        fontName = candidate;
        return;
    end
end

error('Q2:MissingChineseFont', ...
    ['未检测到可显示中文的字体。请安装或启用“Microsoft YaHei”、' ...
     '“Noto Sans CJK SC”等中文字体后重新运行；也可设置环境变量 ' ...
     'Q2_CHINESE_FONT 为已安装的中文字体名称。']);
end
