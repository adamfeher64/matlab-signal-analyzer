function plot_signal_2D_maps(varargin)
% Vstupn� argumenty:
% CLEAN =       �asov� tabu�ka �ist�ch �dajov.
% INTERVAL =    D�ka jednej vzorky �dajov v min�tach.
% DATE =        Pole za�iato�n�ho d�tumu a �asu. Prv� numerick� �daj
%               predstavuje de�, druh� �daj predstavuje mesiac, tret�
%               hodinu a �tvrt� min�tu.
% N =           Po�et po sebe id�cich vzoriek, ktor� bud� vykreslen�. 
%               Maxim�lne 8 ilustr�cii.
% EQUAL_AXIS =	Logick� hodnota, ktorou rozhodujeme, �i osi v�etk�ch grafov
%               maj� toto�n�, resp. glob�lne hranice.
CLEAN = varargin{1};
INTERVAL = varargin{2};
DATE = varargin{3};
N = varargin{4};
EQUAL_AXIS = varargin{5};
% T�to �as� funkcie extrahuje z n�zvu vstupnej �asovej tabu�ky �ist�ch
% �dajov rok. N�sledne extrahuje z po�a DATE de�, mesiac, hodinu a min�tu. 
% N�sledne vytvor� z t�chto 5 �dajov d�tum, od ktor�ho sa spust� 
% vykres�ovanie N po�tu grafov.:
CLEAN_NAME = inputname(1);
YEAR = str2double(CLEAN_NAME(14:end));
DAY = DATE(1);
MONTH = DATE(2);
HOUR = DATE(3);
MINUTE = DATE(4);
DATE = datetime(YEAR, MONTH, DAY, HOUR, MINUTE, 0, ...
    'Format', 'dd.MM.uuuu HH:mm');
% Ak je omylom zadan� v��� po�et grafov ako 8, prep�e t�to hodnotu na
% maxim�lny po�et grafov = 8.:
if N > 8
    N = 8;
end
% Hlavn� cyklus, ktor� postupne vykres�uje grafy.:
i = 0;
plot_data_all = [];
while i ~= N
    % Extrahuje �daje z �asovej tabu�ky �ist�ch hodn�t na z�klade d�a,
    % mesiaca, hodiny a min�ty.:
    YEAR_NEW = DATE.Year;
    MONTH = DATE.Month;
    DAY = DATE.Day;
    HOUR = DATE.Hour;
    MINUTE = DATE.Minute;
    START = datetime(YEAR_NEW, MONTH, DAY, HOUR, MINUTE, 0, ...
        'Format', 'dd.MM.uuuu HH:mm');
    STOP = START + minutes(INTERVAL);
    plot_data = [CLEAN.Value(timerange(START, STOP)), ...
        CLEAN.Value(timerange(START + seconds(1), STOP + seconds(1)))];
    plot_data_all = [plot_data_all; plot_data]; %#ok<AGROW>
    % Ak cyklus prejde na posledn� dostupn� vzorku v roku, ukon�� 
    % vykres�ovanie.:
    if DATE.Year ~= YEAR_NEW
        break;
    end
    % Ak neexistuj� �daje pre t�to vzorku, cyklus prejde do nasleduj�cej
    % vzorky.:
    if isempty(plot_data)
        DATE = DATE + minutes(INTERVAL);
        continue;
    end
    % Vygeneruje nov� (pr�zdne) okno grafu.:
    figure('Name', datestr(DATE), ...
       'WindowStyle', 'docked');
    % Vykresli graf.:
    s = scatter(plot_data(:, 1), ...
        plot_data(:, 2), ...
        'filled', ...
        'LineWidth', 0.2, ...
        'MarkerFaceAlpha', 0.3);
    % Nastavenie mrie�ky, n�zvu grafov a osi a re�im zobrazenia "�tvorec".: 
    grid('on');
    title({"2D Map", ...
        "Start: " + datestr(DATE, 'dd.mm. yyyy hh:MM'), ...
        "Length: " + INTERVAL + " minutes"});
    xlabel("Value");
    ylabel("Value");
    s.DataTipTemplate.DataTipRows(1).Label = "Value (N)";
    s.DataTipTemplate.DataTipRows(2).Label = "Value (N+1)";
    axis('square');
    axis('tight');
    box('on');
    % Priprav� nasleduj�ci cyklus do nasleduj�ceho d�a.:
    i = i + 1;
    DATE = DATE + minutes(INTERVAL);
end
% Ak je vstupn� argument EQUAL_AXIS pravdiv� (t.j. 1 alebo true),
% v�etky grafy bud� ma� toto�n� hranice oboch os�.:
if EQUAL_AXIS == true
    x_min = min(plot_data_all(:, 1));
    x_max = max(plot_data_all(:, 1));
    y_min = min(plot_data_all(:, 2));
    y_max = max(plot_data_all(:, 2));
    for fig = 1:i
        xlim(figure(fig).Children, [x_min, x_max]);
        ylim(figure(fig).Children, [y_min, y_max]);
    end
end
end
