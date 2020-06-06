function plot_signal_2D_maps(varargin)
% Vstupné argumenty:
% CLEAN =       Èasová tabu¾ka èistıch údajov.
% INTERVAL =    Dåka jednej vzorky údajov v minútach.
% DATE =        Pole zaèiatoèného dátumu a èasu. Prvı numerickı údaj
%               predstavuje deò, druhı údaj predstavuje mesiac, tretí
%               hodinu a štvrtı minútu.
% N =           Poèet po sebe idúcich vzoriek, ktoré budú vykreslené. 
%               Maximálne 8 ilustrácii.
% EQUAL_AXIS =	Logická hodnota, ktorou rozhodujeme, èi osi všetkıch grafov
%               majú totoné, resp. globálne hranice.
CLEAN = varargin{1};
INTERVAL = varargin{2};
DATE = varargin{3};
N = varargin{4};
EQUAL_AXIS = varargin{5};
% Táto èas funkcie extrahuje z názvu vstupnej èasovej tabu¾ky èistıch
% údajov rok. Následne extrahuje z po¾a DATE deò, mesiac, hodinu a minútu. 
% Následne vytvorí z tıchto 5 údajov dátum, od ktorého sa spustí 
% vykres¾ovanie N poètu grafov.:
CLEAN_NAME = inputname(1);
YEAR = str2double(CLEAN_NAME(14:end));
DAY = DATE(1);
MONTH = DATE(2);
HOUR = DATE(3);
MINUTE = DATE(4);
DATE = datetime(YEAR, MONTH, DAY, HOUR, MINUTE, 0, ...
    'Format', 'dd.MM.uuuu HH:mm');
% Ak je omylom zadanı väèší poèet grafov ako 8, prepíše túto hodnotu na
% maximálny poèet grafov = 8.:
if N > 8
    N = 8;
end
% Hlavnı cyklus, ktorı postupne vykres¾uje grafy.:
i = 0;
plot_data_all = [];
while i ~= N
    % Extrahuje údaje z èasovej tabu¾ky èistıch hodnôt na základe dòa,
    % mesiaca, hodiny a minúty.:
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
    % Ak cyklus prejde na poslednú dostupnú vzorku v roku, ukonèí 
    % vykres¾ovanie.:
    if DATE.Year ~= YEAR_NEW
        break;
    end
    % Ak neexistujú údaje pre túto vzorku, cyklus prejde do nasledujúcej
    % vzorky.:
    if isempty(plot_data)
        DATE = DATE + minutes(INTERVAL);
        continue;
    end
    % Vygeneruje nové (prázdne) okno grafu.:
    figure('Name', datestr(DATE), ...
       'WindowStyle', 'docked');
    % Vykresli graf.:
    s = scatter(plot_data(:, 1), ...
        plot_data(:, 2), ...
        'filled', ...
        'LineWidth', 0.2, ...
        'MarkerFaceAlpha', 0.3);
    % Nastavenie mrieky, názvu grafov a osi a reim zobrazenia "štvorec".: 
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
    % Pripraví nasledujúci cyklus do nasledujúceho dòa.:
    i = i + 1;
    DATE = DATE + minutes(INTERVAL);
end
% Ak je vstupnı argument EQUAL_AXIS pravdivı (t.j. 1 alebo true),
% všetky grafy budú ma totoné hranice oboch osí.:
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
