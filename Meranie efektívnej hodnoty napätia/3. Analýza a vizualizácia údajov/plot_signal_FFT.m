function plot_signal_FFT(varargin)
% Vstupn� argumenty:
% CLEAN =       �asova tabu�ka �ist�ch hodn�t.
% INTERVAL =    D�ka jednej vzorky �dajov v min�tach.
% FREQ =        Frekvencia nameran�ho sign�lu v Hertzoch.
% DATE =        Pole za�iato�n�ho d�tumu a �asu. Prv� numerick� �daj
%               predstavuje de�, druh� �daj predstavuje mesiac, tret�
%               hodinu a �tvrt� min�tu.
% N =           Po�et po sebe id�cich vzoriek, ktor� bud� vykreslen�. 
%               Maxim�lne 8 ilustr�cii.
CLEAN = varargin{1};
INTERVAL = varargin{2};
FREQ = varargin{3};
DATE = varargin{4};
N = varargin{5};
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
    plot_data = table( ...
        CLEAN.Time(timerange(START, STOP)), ...
        CLEAN.Value(timerange(START, STOP)));
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
    % Vykresli graf sign�lu.:
    subplot(2, 1, 1);
    p1 = plot(plot_data.Var1, plot_data.Var2);
    % Nastavenie mrie�ky, n�zvu grafov a osi a re�im zobrazenia "�tvorec".: 
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
    % Nastavenie mrie�ky, n�zvu grafov a osi a re�im zobrazenia "�tvorec".: 
    grid('on');
    title("Single-Sided Fast Fourier Transformation");
    xlabel("Frequency (Hz)");
    ylabel("|X(\omegaj)|");
    p2.DataTipTemplate.DataTipRows(1).Label = "Frequency (Hz)";
    p2.DataTipTemplate.DataTipRows(2).Label = "|X(\omegaj)|";
    axis('tight');
    box('on');
    % Priprav� nasleduj�ci cyklus do nasleduj�ceho d�a.:
    i = i + 1;
    DATE = DATE + minutes(INTERVAL);
end
end
