function plot_correlation_weekdays(varargin)
% Vstupn� argumenty:
% STATS =       Tabu�ka �tatistick�ch parametrov.
% VARIABLE =    Premenn� (st�pec) tabu�ky STATS. Napr�klad 'Mean' pre
%               aritmetick� priemer.
% SELECTION =	Pole v�beru. Prv� numerick� hodnota predstavuje de� v 
%               t��dni zvolen�ho mesiaca. Napr�klad 5 pre piatok. Druh�
%               numerick� hodnota predstavuje mesiac v roku. Napr�klad 2 
%               pre febru�r.
STATS = varargin{1};
VARIABLE = varargin{2};
SELECTION = varargin{3};
% T�to �as� k�du priprav� pole d�tumov dn� days na z�klade vstupu.:
WEEK_DAY = SELECTION(1);
MONTH = SELECTION(2);
weekdays = weekday(STATS.DateStart) - 1;
weekdays(weekdays == 0) = 7;
cond_1 = weekdays == WEEK_DAY;
cond_2 = STATS.DateStart.Month == MONTH;
tab = STATS(cond_1 & cond_2, {'DateStart', VARIABLE});
days = unique(tab.DateStart.Day);
days_count = length(days);
final_tab = cell(days_count, 1);
% V tejto �asti k�du sa vypln� tabu�ka final_tab v�etk�mi �dajmi potrebn�mi
% k vypo��taniu v�etk�ch korel�ci�.:
idx = 1;
for i = 1:days_count
    final_tab{idx, 1} = tab(tab.DateStart.Day == days(i), :);
    idx = idx + 1;
end
% V tejto �asti k�du sa vypo��taj� v�etky korel�cie medzi �tatistick�m
% parametrom jednotliv�ch dni dan�ho mesiaca, ��m vygeneruje maticu
% v�sledkov s n�zvom final_corr.:
final_tab_length = length(final_tab);
final_corr = zeros(final_tab_length);
labels = NaT(final_tab_length, 1);
for col = 1:final_tab_length
    labels(col) = datetime(final_tab{col}.DateStart(1));
    for row = 1:final_tab_length
        data_1 = final_tab{row}{:, 2};
        data_2 = final_tab{col}{:, 2};
        if length(data_1) == length(data_2)
            final_corr(row, col) = abs(corr(data_1, data_2));
        else
            final_corr(row, col) = NaN;
        end
    end
end
% V tejto �asti k�du funkcia vykresli maticu v�sledn�ch korel�ci�.:
labels = datetime(labels, 'Format', 'd. M. uuuu');
[~, week_day_label] = weekday(labels(1), 'long');
month_label = datetime(labels(1), 'Format', 'MMMM');
hm = heatmap(final_corr);
% Nastavenia zobrazenia ako limit farieb, n�zov grafu a os�.:
hm.XDisplayLabels = labels;
hm.YDisplayLabels = labels;
hm.Title = {
    "Variable: " + VARIABLE;
    "Week day: " + week_day_label;
    "Month: " + string(month_label);
};
hm.ColorLimits = [0.5, 1];
end