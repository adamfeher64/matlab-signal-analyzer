function plot_signal_FFT(varargin)
% Vstupné argumenty:
% CLEAN =       Èasova tabu¾ka èistých hodnôt.
% INTERVAL =    Dåžka jednej vzorky údajov v minútach.
% FREQ =        Frekvencia nameraného signálu v Hertzoch.
% DATE =        Pole zaèiatoèného dátumu a èasu. Prvý numerický údaj
%               predstavuje deò, druhý údaj predstavuje mesiac, tretí
%               hodinu a štvrtý minútu.
% N =           Poèet po sebe idúcich vzoriek, ktoré budú vykreslené. 
%               Maximálne 8 ilustrácii.
CLEAN = varargin{1};
INTERVAL = varargin{2};
FREQ = varargin{3};
DATE = varargin{4};
N = varargin{5};
% Táto èas funkcie extrahuje z názvu vstupnej èasovej tabu¾ky èistých
% údajov rok. Následne extrahuje z po¾a DATE deò, mesiac, hodinu a minútu. 
% Následne vytvorí z týchto 5 údajov dátum, od ktorého sa spustí 
% vykres¾ovanie N poètu grafov.:
CLEAN_NAME = inputname(1);
YEAR = str2double(CLEAN_NAME(14:end));
DAY = DATE(1);
MONTH = DATE(2);
HOUR = DATE(3);
MINUTE = DATE(4);
DATE = datetime(YEAR, MONTH, DAY, HOUR, MINUTE, 0, ...
    'Format', 'dd.MM.uuuu HH:mm');
% Ak je omylom zadaný väèší poèet grafov ako 8, prepíše túto hodnotu na
% maximálny poèet grafov = 8.:
if N > 8
    N = 8;
end
% Hlavný cyklus, ktorý postupne vykres¾uje grafy.:
i = 0;
while i ~= N
    % Extrahuje údaje z èasovej tabu¾ky èistých hodnôt na základe dòa,
    % mesiaca, hodiny a minúty.:
    YEAR_NEW = DATE.Year;
    MONTH = DATE.Month;
    DAY = DATE.Day;
    HOUR = DATE.Hour;
    MINUTE = DATE.Minute;
    START = datetime(YEAR_NEW, MONTH, DAY, HOUR, MINUTE, 0, ...
        'Format', 'dd.MM.uuuu HH:mm');
    STOP = START + minutes(INTERVAL);
    plot_data = table( ...
        CLEAN.Time(timerange(START, STOP)), ...
        CLEAN.Value(timerange(START, STOP)));
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
    % Vykresli graf signálu.:
    subplot(2, 1, 1);
    p1 = plot(plot_data.Var1, plot_data.Var2);
    % Nastavenie mriežky, názvu grafov a osi a režim zobrazenia "štvorec".: 
    grid('on');
    title({"Signal", ...
        "Start: " + datestr(DATE, 'dd.mm. yyyy hh:MM'), ...
        "Length: " + INTERVAL + " minutes"});
    ylabel("Value");
    p1.DataTipTemplate.DataTipRows(1).Label = "Time";
    p1.DataTipTemplate.DataTipRows(2).Label = "Value";
    axis('tight');
    box('on');
    % Vykresli graf FFT.:
    subplot(2, 1, 2);
    LENGTH = length(plot_data.Var2); 
    COUNT = 2 ^ nextpow2(LENGTH);
    half = COUNT / 2;
    FFT = fft(plot_data.Var2, COUNT);
    x_fft = (1:COUNT) * (FREQ / COUNT);
    y_fft = abs(FFT) / COUNT;
    p2 = plot(x_fft(2:half), y_fft(2:half));
    % Nastavenie mriežky, názvu grafov a osi a režim zobrazenia "štvorec".: 
    grid('on');
    title("Single-Sided Fast Fourier Transformation");
    xlabel("Frequency (Hz)");
    ylabel("|X(\omegaj)|");
    p2.DataTipTemplate.DataTipRows(1).Label = "Frequency (Hz)";
    p2.DataTipTemplate.DataTipRows(2).Label = "|X(\omegaj)|";
    axis('tight');
    box('on');
    % Pripraví nasledujúci cyklus do nasledujúceho dòa.:
    i = i + 1;
    DATE = DATE + minutes(INTERVAL);
end
end
