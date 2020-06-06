function plot_correlation_diagram(varargin)
% Vstupn� argumenty:
% STATS =       Tabu�ka �tatistick�ch parametrov.
% DATE =        Pole za�iato�n�ho d�tumu. Prv� numerick� �daj predstavuje 
%               de�, druh� �daj predstavuje mesiac.
% VARIABLES =   2 Premenn� tabu�ky �tatistick�ch parametrov.
% N =           Po�et dn�, ktor� bud� vykreslen�. Maxim�lne 8 ilustr�cii.
% EQUAL_AXIS =  Logick� hodnota, ktorou rozhodujeme, �i osi v�etk�ch grafov
%               maj� toto�n�, resp. glob�lne hranice.
STATS = varargin{1};
VARIABLES = varargin{2};
DATE = varargin{3};
N = varargin{4};
EQUAL_AXIS = varargin{5};
% T�to �as� funkcie extrahuje z n�zvu vstupnej tabu�ky �tatistick�ch
% parametrov rok. N�sledne extrahuje z po�a DATE de� a mesiac. N�sledne
% vytvor� z t�chto 3 �dajov d�tum, od ktor�ho sa spust� vykres�ovanie N
% po�tu grafov.:
STATS_NAME = inputname(1);
YEAR = str2double(STATS_NAME(10:end));
MONTH = DATE(2);
DAY = DATE(1);
DATE = datetime(YEAR, MONTH, DAY, 'Format', 'dd. MM. uuuu');
% Ak je omylom zadan� v��� po�et grafov ako 8, prep�e t�to hodnotu na
% maxim�lny po�et grafov = 8.:
if N > 8
    N = 8;
end
% Hlavn� cyklus, ktor� postupne vykres�uje grafy.:
i = 0;
plot_data_all = [];
while i ~= N
    % Extrahuje �daje z tabu�ky �tatistick�ch hodn�t na z�klade d�a a
    % mesiaca.:
    MONTH = DATE.Month;
    DAY = DATE.Day;
    cond_1 = STATS.DateStart.Day == DAY;
    cond_2 = STATS.DateStart.Month == MONTH;
    plot_data = STATS(cond_1 & cond_2, VARIABLES);
    plot_data_all = [plot_data_all; plot_data]; %#ok<AGROW>
    % Ak cyklus prejde na posledn� dostupn� de�, ukon�� vykres�ovanie.:
    if DATE.Year ~= YEAR
        break;
    end
    % Ak neexistuj� �daje pre tento de�, cyklus prejde do nasleduj�ceho
    % d�a.:
    if isempty(plot_data)
        DATE = DATE + days(1);
        continue;
    end
    % Vygeneruje nov� (pr�zdne) okno grafu.:
    figure('Name', datestr(DATE), ...
       'WindowStyle', 'docked');
    % Vykresli graf.:
    s = scatter(plot_data{:, 1}, ...
        plot_data{:, 2}, ...
        'filled', ...
        'LineWidth', 0.2, ...
        'MarkerFaceAlpha', 0.4);
    % Nastavenie mrie�ky, n�zvu grafov a osi a re�im zobrazenia "�tvorec".: 
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
    % Priprav� nasleduj�ci cyklus do nasleduj�ceho d�a.:
    i = i + 1;
    DATE = DATE + days(1);
end
% Ak je vstupn� argument EQUAL_AXIS pravdiv� (t.j. 1 alebo true),
% v�etky grafy bud� ma� toto�n� hranice oboch os�.:
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
