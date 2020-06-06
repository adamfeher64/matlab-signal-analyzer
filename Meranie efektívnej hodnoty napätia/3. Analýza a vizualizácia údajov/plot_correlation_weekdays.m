function plot_correlation_weekdays(varargin)
% Vstupné argumenty:
% STATS =       Tabu¾ka štatistickıch parametrov.
% VARIABLE =    Premenná (ståpec) tabu¾ky STATS. Napríklad 'Mean' pre
%               aritmetickı priemer.
% SELECTION =	Pole vıberu. Prvá numerická hodnota predstavuje deò v 
%               tıdni zvoleného mesiaca. Napríklad 5 pre piatok. Druhá
%               numerická hodnota predstavuje mesiac v roku. Napríklad 2 
%               pre február.
STATS = varargin{1};
VARIABLE = varargin{2};
SELECTION = varargin{3};
% Táto èas kódu pripraví pole dátumov dní days na základe vstupu.:
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
% V tejto èasti kódu sa vyplní tabu¾ka final_tab všetkımi údajmi potrebnımi
% k vypoèítaniu všetkıch korelácií.:
idx = 1;
for i = 1:days_count
    final_tab{idx, 1} = tab(tab.DateStart.Day == days(i), :);
    idx = idx + 1;
end
% V tejto èasti kódu sa vypoèítajú všetky korelácie medzi štatistickım
% parametrom jednotlivıch dni daného mesiaca, èím vygeneruje maticu
% vısledkov s názvom final_corr.:
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
% V tejto èasti kódu funkcia vykresli maticu vıslednıch korelácií.:
labels = datetime(labels, 'Format', 'd. M. uuuu');
[~, week_day_label] = weekday(labels(1), 'long');
month_label = datetime(labels(1), 'Format', 'MMMM');
hm = heatmap(final_corr);
% Nastavenia zobrazenia ako limit farieb, názov grafu a osí.:
hm.XDisplayLabels = labels;
hm.YDisplayLabels = labels;
hm.Title = {
    "Variable: " + VARIABLE;
    "Week day: " + week_day_label;
    "Month: " + string(month_label);
};
hm.ColorLimits = [0.5, 1];
end