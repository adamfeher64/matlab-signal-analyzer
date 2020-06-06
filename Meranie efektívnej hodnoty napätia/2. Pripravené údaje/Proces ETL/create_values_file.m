function varargout = create_values_file(varargin)
% Vstupn� argumenty:
% PATH =	Cesta k s�boru s pr�ponou *.CSV.
% STEP =	��rka krokov medzi jednotliv�mi meraniami v sekund�ch.
% UNITS =	Jednotky, ktor� sa ulo�ili spolu s ��selnou hodnotou do jedn�ho
%           st�pca a je potrebn� ich odstr�ni�. Je potrebn� ponecha� len
%           ��seln� �daje. Ak nemaj� �daje �iadne jednotky, neuv�dza sa
%           ni�.
PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};

% V tejto �ast� sa do pr�slu�n�ch premenn�ch funkcie na��ta *.CSV s�bor,
% po�et jeho riadkov a numerick� vyjadren� k���ov� �asov� d�ky, ktor� sa
% vyu��vaj� v �al��ch �astiach tejto funkcie:
CLEAN = readtable(PATH);
ROWS_ALL = size(CLEAN, 1);
HOUR = 60;
MINUTES = minutes(HOUR);
SECONDS = seconds(MINUTES);
STEP = seconds(STEP);

% Na tomto mieste sa over�, �i je v s�bore zaznamenan�ch aspo� to�ko
% riadkov, ko�ko pri definovanej ��rke kroku zodpoved� jednej hodine:
if ROWS_ALL >= SECONDS
    % Inicializa�n� �as� ETL procesu. V tejto �asti doch�dza k �prav�m
    % s�boru ako �prava n�zvu jednotliv�ch st�pcov, zaokr�h�ovanie �asov�ch
    % �dajov na cel� sekundy,  zl��enie st�pcov d�tumu a �asu do jedn�ho
    % spolo�n�ho st�pca, konverzia textov�ho �dajov�ho typu numerick�ch
    % �dajov na ��seln� �dajov� typ, odstr�nenie jednotiek veli�iny,
    % odstr�nenie duplicitn�ch riadkov (ak tak� s�), odstr�nenie pr�zdnych
    % riadkov a konverzia �dajov�ho typu table na timetable:
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
    
    % V tejto �asti funkcia odstr�ni kr�tky �sek merania na za�iatku aj na
    % konci a to tak, aby meranie za��nalo od nultej min�ty nasleduj�cej
    % hodiny a kon�ilo poslednou minutou predposlednej hodiny merania.:
    begin_of_file = CLEAN.Time.Minute(1:SECONDS) == 0 & ...
        CLEAN.Time.Second(1:SECONDS) == 0;
    end_of_file = CLEAN.Time.Minute(end - SECONDS:end) == 0 & ...
        CLEAN.Time.Second(end - SECONDS:end) == 0;
    begin_index = find(begin_of_file, 1);
    end_index = size(CLEAN, 1) - (SECONDS - find(end_of_file, 1) + 2);
    CLEAN = CLEAN(begin_index:end_index, :);
    
    % V tejto �asti funkcie doch�dza k odstr�neniu ne�pln�ch 1-hodinov�ch
    % �ast� od merania, kde bolo meranie preru�en� a zarad� tieto �seky do
    % sekcie vypusten�ch �dajov.:
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
    
    % Funkcia vytvor� �asov� tabu�ku vyraden�ch hodn�t met�dou porovn�vania
    % vstupnej tabu�ky s v�stupnou tabu�kou.:
    EXCLUDED = EXCLUDED(~ismember(EXCLUDED.Time, CLEAN.Time), :);
    
    % Funkcia vyp�e v�sledn� �tatistiky ETL procesu:
    ROWS_AFTER = size(CLEAN, 1);
    fprintf("Vytv�ranie bolo dokon�en�.\n");
    fprintf("Celkov� po�et �dajov:\t\t%d\n", ROWS_ALL);
    fprintf("Po�et vy�isten�ch �dajov:\t%d\n", ROWS_AFTER);
    fprintf("Po�et vyl��en�ch �dajov:\t%d\n", ROWS_CLEAN - ROWS_AFTER);
    fprintf("Po�et po�koden�ch �dajov:\t%d\n\n", ROWS_ALL - ROWS_CLEAN);
    
% Funkcia vyrad� tento *.CSV s�bor z ETL procesu, preto�e nem� dostatok 
% meran�. V takomto pr�pade funkcia vr�ti pr�zdne v�stupy:
else
    CLEAN = [];
    EXCLUDED = [];
    fprintf("Nedostatok (%d/%d) meran�. S�bor bol vyl��en�.\n\n", ROWS_ALL, SECONDS);
end

% V�stupn� argumenty:
% CLEAN =       �asov� tabu�ka �ist�ch �dajov po �prave ETL procesom.
% EXCLUDED =	�asov� tabu�ka vypusten�ch �dajov po �prave ETL procesom.
varargout{1} = CLEAN;
varargout{2} = EXCLUDED;
end
