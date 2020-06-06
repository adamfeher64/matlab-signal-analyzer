function plot_correlation_diagram(varargin)
% Vstupné argumenty:
% STATS =       Tabu¾ka štatistickıch parametrov.
% DATE =        Pole zaèiatoèného dátumu. Prvı numerickı údaj predstavuje 
%               deò, druhı údaj predstavuje mesiac.
% VARIABLES =   2 Premenné tabu¾ky štatistickıch parametrov.
% N =           Poèet dní, ktoré budú vykreslené. Maximálne 8 ilustrácii.
% EQUAL_AXIS =  Logická hodnota, ktorou rozhodujeme, èi osi všetkıch grafov
%               majú totoné, resp. globálne hranice.
STATS = varargin{1};
VARIABLES = varargin{2};
DATE = varargin{3};
N = varargin{4};
EQUAL_AXIS = varargin{5};
% Táto èas funkcie extrahuje z názvu vstupnej tabu¾ky štatistickıch
% parametrov rok. Následne extrahuje z po¾a DATE deò a mesiac. Následne
% vytvorí z tıchto 3 údajov dátum, od ktorého sa spustí vykres¾ovanie N
% poètu grafov.:
STATS_NAME = inputname(1);
YEAR = str2double(STATS_NAME(10:end));
MONTH = DATE(2);
DAY = DATE(1);
DATE = datetime(YEAR, MONTH, DAY, 'Format', 'dd. MM. uuuu');
% Ak je omylom zadanı väèší poèet grafov ako 8, prepíše túto hodnotu na
% maximálny poèet grafov = 8.:
if N > 8
    N = 8;
end
% Hlavnı cyklus, ktorı postupne vykres¾uje grafy.:
i = 0;
plot_data_all = [];
while i ~= N
    % Extrahuje údaje z tabu¾ky štatistickıch hodnôt na základe dòa a
    % mesiaca.:
    MONTH = DATE.Month;
    DAY = DATE.Day;
    cond_1 = STATS.DateStart.Day == DAY;
    cond_2 = STATS.DateStart.Month == MONTH;
    plot_data = STATS(cond_1 & cond_2, VARIABLES);
    plot_data_all = [plot_data_all; plot_data]; %#ok<AGROW>
    % Ak cyklus prejde na poslednı dostupnı deò, ukonèí vykres¾ovanie.:
    if DATE.Year ~= YEAR
        break;
    end
    % Ak neexistujú údaje pre tento deò, cyklus prejde do nasledujúceho
    % dòa.:
    if isempty(plot_data)
        DATE = DATE + days(1);
        continue;
    end
    % Vygeneruje nové (prázdne) okno grafu.:
    figure('Name', datestr(DATE), ...
       'WindowStyle', 'docked');
    % Vykresli graf.:
    s = scatter(plot_data{:, 1}, ...
        plot_data{:, 2}, ...
        'filled', ...
        'LineWidth', 0.2, ...
        'MarkerFaceAlpha', 0.4);
    % Nastavenie mrieky, názvu grafov a osi a reim zobrazenia "štvorec".: 
    grid('on');
    title({"Correlation diagram between " + VARIABLES{1} + " and " ...
        + VARIABLES{2}, ...
        "Date: " + datestr(DATE, 'dd.mm. yyyy')});
    xlabel(VARIABLES{1});
    ylabel(VARIABLES{2});
    s.DataTipTemplate.DataTipRows(1).Label = VARIABLES{1};
    s.DataTipTemplate.DataTipRows(2).Label = VARIABLES{2};
    axis('square');
    axis('tight');
    box('on');
    % Pripraví nasledujúci cyklus do nasledujúceho dòa.:
    i = i + 1;
    DATE = DATE + days(1);
end
% Ak je vstupnı argument EQUAL_AXIS pravdivı (t.j. 1 alebo true),
% všetky grafy budú ma totoné hranice oboch osí.:
if EQUAL_AXIS == true
    x_min = min(plot_data_all{:, 1});
    x_max = max(plot_data_all{:, 1});
    y_min = min(plot_data_all{:, 2});
    y_max = max(plot_data_all{:, 2});
    for fig = 1:i
        xlim(figure(fig).Children, [x_min, x_max]);
        ylim(figure(fig).Children, [y_min, y_max]);
    end
end
end
