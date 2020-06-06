function varargout = create_values_file(varargin)
% Vstupné argumenty:
% PATH =	Cesta k súboru s príponou *.CSV.
% STEP =	Šírka krokov medzi jednotlivımi meraniami v sekundách.
% UNITS =	Jednotky, ktoré sa uloili spolu s èíselnou hodnotou do jedného
%           ståpca a je potrebné ich odstráni. Je potrebné ponecha len
%           èíselné údaje. Ak nemajú údaje iadne jednotky, neuvádza sa
%           niè.
PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};

% V tejto èastí sa do príslušnıch premennıch funkcie naèíta *.CSV súbor,
% poèet jeho riadkov a numerickı vyjadrené k¾úèové èasové dåky, ktoré sa
% vyuívajú v ïalších èastiach tejto funkcie:
CLEAN = readtable(PATH);
ROWS_ALL = size(CLEAN, 1);
HOUR = 60;
MINUTES = minutes(HOUR);
SECONDS = seconds(MINUTES);
STEP = seconds(STEP);

% Na tomto mieste sa overí, èi je v súbore zaznamenanıch aspoò to¾ko
% riadkov, ko¾ko pri definovanej šírke kroku zodpovedá jednej hodine:
if ROWS_ALL >= SECONDS
    % Inicializaèná èas ETL procesu. V tejto èasti dochádza k úpravám
    % súboru ako úprava názvu jednotlivıch ståpcov, zaokrúh¾ovanie èasovıch
    % údajov na celé sekundy,  zlúèenie ståpcov dátumu a èasu do jedného
    % spoloèného ståpca, konverzia textového údajového typu numerickıch
    % údajov na èíselnı údajovı typ, odstránenie jednotiek velièiny,
    % odstránenie duplicitnıch riadkov (ak také sú), odstránenie prázdnych
    % riadkov a konverzia údajového typu table na timetable:
    CLEAN.Properties.VariableNames = {'Date', 'Time', 'Value'};
    CLEAN.Date = datetime(CLEAN.Date, 'InputFormat', "d.M.uuuu", 'Format', "d.M.uuuu");
    CLEAN.Time = duration(CLEAN.Time, 'Format', "hh:mm:ss");
    CLEAN.Datetime = CLEAN.Date + CLEAN.Time;
    CLEAN = removevars(CLEAN, {'Date', 'Time'});
    CLEAN.Datetime = datetime(CLEAN.Datetime, 'Format', "d. M. uuuu HH:mm:ss");
    CLEAN.Datetime.Second = floor(CLEAN.Datetime.Second);
    CLEAN.Value = replace(CLEAN.Value, " " + UNITS, "");
    CLEAN.Value = replace(CLEAN.Value, ",", ".");
    CLEAN.Value = str2double(CLEAN.Value);
    CLEAN = rmmissing(CLEAN);
    CLEAN = timetable(CLEAN.Datetime, CLEAN.Value);
    CLEAN.Properties.VariableNames = {'Value'};
    CLEAN = sortrows(CLEAN, 'Time');
    CLEAN = retime(CLEAN, unique(CLEAN.Time));
    ROWS_CLEAN = size(CLEAN, 1);
    EXCLUDED = CLEAN;
    
    % V tejto èasti funkcia odstráni krátky úsek merania na zaèiatku aj na
    % konci a to tak, aby meranie zaèínalo od nultej minúty nasledujúcej
    % hodiny a konèilo poslednou minutou predposlednej hodiny merania.:
    begin_of_file = CLEAN.Time.Minute(1:SECONDS) == 0 & ...
        CLEAN.Time.Second(1:SECONDS) == 0;
    end_of_file = CLEAN.Time.Minute(end - SECONDS:end) == 0 & ...
        CLEAN.Time.Second(end - SECONDS:end) == 0;
    begin_index = find(begin_of_file, 1);
    end_index = size(CLEAN, 1) - (SECONDS - find(end_of_file, 1) + 2);
    CLEAN = CLEAN(begin_index:end_index, :);
    
    % V tejto èasti funkcie dochádza k odstráneniu neúplnıch 1-hodinovıch
    % èastí od merania, kde bolo meranie prerušené a zaradí tieto úseky do
    % sekcie vypustenıch údajov.:
    start = (CLEAN.Time(1):MINUTES:CLEAN.Time(end))';
    stop = ((CLEAN.Time(1) + MINUTES - STEP):MINUTES:CLEAN.Time(end))';
    [~, start] = ismember(start, CLEAN.Time);
    [~, stop] = ismember(stop, CLEAN.Time);
    sample = table(start, stop);
    for i = 1:size(sample, 1)
        if (sample.start(i) == 0) && (sample.stop(i) == 0)
            sample.start(i) = NaN;
        end
    end
    sample(isnan(sample.start), :) = [];
    for i = 1:size(sample, 1)
        if sample.start(i) == 0
            sample.start(i) = sample.stop(i - 1) + 1;
        end
        if sample.stop(i) == 0
            if sample.start(i + 1) == 0
                sample.stop(i) = sample.stop(i + 1);
                sample.start(i + 1) = NaN;
            else
                sample.stop(i) = sample.start(i + 1) - 1;
            end
        end
    end
    sample(isnan(sample.start), :) = [];
    sample.observations = abs(sample.stop - sample.start) + 1;
    for i = 1:size(sample, 1)
        sample.c1(i) = ~isregular(CLEAN(sample.start(i):sample.stop(i), []));
        sample.c2(i) = sample.observations(i) ~= SECONDS;
        sample.c3(i) = range(CLEAN.Value(sample.start(i):sample.stop(i))) == 0;
        sample.test(i) = sample.c1(i) + sample.c2(i) + sample.c3(i);
    end
    sample = sortrows(sample, 'test', 'descend');
    for i = 1:nnz(sample.test)
        CLEAN.Value(sample.start(i):sample.stop(i)) = NaN;
    end
    nans = isnan(CLEAN.Value);
    CLEAN(nans, :) = [];
    
    % Funkcia vytvorí èasovú tabu¾ku vyradenıch hodnôt metódou porovnávania
    % vstupnej tabu¾ky s vıstupnou tabu¾kou.:
    EXCLUDED = EXCLUDED(~ismember(EXCLUDED.Time, CLEAN.Time), :);
    
    % Funkcia vypíše vısledné štatistiky ETL procesu:
    ROWS_AFTER = size(CLEAN, 1);
    fprintf("Vytváranie bolo dokonèené.\n");
    fprintf("Celkovı poèet údajov:\t\t%d\n", ROWS_ALL);
    fprintf("Poèet vyèistenıch údajov:\t%d\n", ROWS_AFTER);
    fprintf("Poèet vylúèenıch údajov:\t%d\n", ROWS_CLEAN - ROWS_AFTER);
    fprintf("Poèet poškodenıch údajov:\t%d\n\n", ROWS_ALL - ROWS_CLEAN);
    
% Funkcia vyradí tento *.CSV súbor z ETL procesu, pretoe nemá dostatok 
% meraní. V takomto prípade funkcia vráti prázdne vıstupy:
else
    CLEAN = [];
    EXCLUDED = [];
    fprintf("Nedostatok (%d/%d) meraní. Súbor bol vylúèenı.\n\n", ROWS_ALL, SECONDS);
end

% Vıstupné argumenty:
% CLEAN =       Èasová tabu¾ka èistıch údajov po úprave ETL procesom.
% EXCLUDED =	Èasová tabu¾ka vypustenıch údajov po úprave ETL procesom.
varargout{1} = CLEAN;
varargout{2} = EXCLUDED;
end
