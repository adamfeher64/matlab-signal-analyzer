function etl_append(varargin)
% Vstupn� argumenty funkcie:
% OLD_DATA_PATH =   cesta k prie�inku, v ktorom sa nach�dzaj� *.csv s�bory
%                   alebo cesta ku konkr�tnemu *.csv s�boru.
% STEP =            interval krokovania meracieho pr�stroja v sekund�ch.
% UNITS =           jednotky meran�ch veli��n.
% TOLERANCE =       po�et maxim�lne tolerovan�ch hod�n, ktor� bud�
%                   automatick� doplnen�.
% PROGRESS =        ak je t�to funkcia spusten� cez aplik�ciu, tak v�aka
%                   tomuto argumentu sa bude zobrazova� v dial�govom okne
%                   progres v�po�tov.
OLD_DATA_PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};
TOLERANCE = varargin{4};
if nargin == 5
    PROGRESS = varargin{5};
end

% T�to �as� k�du ulo�� do premennej s n�zvom BASE_PATH cestu v ktorej je
% ulo�en� t�to funkcia:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = string(join(BASE_PATH(1:end - 2), "\"));

% T�to �as� k�du zavol� funkcie ETL procesu v pr�slu�nom porad�:
% Najprv vytvor� �asov� tabu�ku s n�zvom values_clean_NEW, kde bud� ulo�en�
% v�etky �daje na��tan� z *.CSV s�borov po �prave ETL procesom. N�sledne t�
% ist� funkcia s n�zvom create_values, resp. create_values_file ulo�� do
% premennej values_excluded_NEW v�etky �daje vyraden� ETL procesom.
% Podmienka: Ak je prv�m vstupn�m argumentom cesta k *.csv s�boru, zavol�
% sa funkcia create_values_file.:
is_file = contains(OLD_DATA_PATH, ".csv");
if is_file
    % Inicializa�n� �as� funkcie create_values_file:
    % V tejto �asti sa spusti �asova� a zaznamen�vanie v�etk�ho, �o sa
    % prostredn�ctvom funkcie fprintf ocitne v okne pr�kazov�ho riadku.
    % Z�znam sa n�sledne ulo�� pod n�zvom log_create_values.txt do zlo�ky
    % Proces ETL.:
    tic;
    LOG_PATH = BASE_PATH + "\2. Pripraven� �daje\Proces ETL\";
    diary (LOG_PATH + "\log_create_values.txt");

    fprintf("D�tum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
    fprintf("�as:\t" + datestr(now, "HH:MM") + "\n");
    fprintf("-----VSTUPN�-ARGUMENTY-----\n");
    fprintf("Cesta k s�boru:\t\t""%s""\n", OLD_DATA_PATH);
    fprintf("Krokovanie (s):\t\t%d\n", STEP);
    fprintf("Jednotky:\t\t\t""%s""\n", UNITS);
    fprintf("---------------------------\n");

    % Volanie funkcie create_values_file.:
    file_count = 1;
    [values_clean_NEW, values_excluded_NEW] = ...
        create_values_file(OLD_DATA_PATH, STEP, UNITS);

    % Ukon�ovacia �as� funkcie create_values_file:
    % V tejto �asti funkcia vr�ti v�etky v�stupn� argumenty a vyp�e d�ku
    % trvania v�po�tov tejto funkcie. Z�rove� sa ukon�� a ulo�� z�znam do
    % textov�ho s�boru log_create_values.txt.:
    fprintf("Uplynut� �as: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
    fprintf("Vytv�ranie tabu�ky bolo �spe�ne dokon�en�.\n");
    fprintf("===========================\n");
    diary off;
    beep;
% Podmienka: Ak je prv�m vstupn�m argumentom cesta k prie�inku, zavol� sa
% funkcia create_values.:
else
    % Volanie funkcie create_values.:
    [values_clean_NEW, values_excluded_NEW, file_count] = ...
        create_values(OLD_DATA_PATH, STEP, UNITS, PROGRESS);
end

% N�sledne funkcia s n�zvom create_missing vytvor� tabu�ku s n�zvom
% missing_NEW, v ktorej bud� ulo�en� v�etky �daje o ch�baj�cich, resp.
% vyraden�ch �dajoch.:
if exist("PROGRESS", 'var')
    pd_state = file_count + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Vytv�ra sa tabu�ka s n�zvom missing_NEW...";
end
missing_NEW = create_missing(values_clean_NEW, STEP);

% T�to tabu�ka bude n�sledne roz��ren� o nieko�ko st�pcov, v ktor�ch bud�
% ulo�en� vyraden� �daje a tieto �daje doplnen� o ch�baj�ce hodnoty. Nov�
% �daje bud� ulo�en� v �asovej tabu�ke s n�zvom values_filled_NEW.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Dop��aj� sa ch�baj�ce hodnoty...";
end
[values_filled_NEW, missing_NEW] = ...
    create_filled(missing_NEW, values_excluded_NEW, STEP, TOLERANCE);

% T�to �as� k�du sp�ja �ist� a doplnen� hodnoty a n�sledne ich triedi pod�a
% �asu.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Zlu�uj� sa �ist� a doplnen� hodnoty...";
end
values_clean_NEW = [values_clean_NEW; values_filled_NEW];
values_clean_NEW = sortrows(values_clean_NEW, "Time");

% T�to �as� k�du vytvor� tabu�ky s n�zvom stats_YYYY_NEW
% (pri�om YYYY = rok) pre v�etky definovan� �asov� intervaly ulo�en� v
% premennej SIGNAL_LENGTHS.:
SIGNAL_LENGTHS = [10, 12, 15, 20, 30, 60];
SIGNAL_LENGTHS_STRINGS_NEW = strings(length(SIGNAL_LENGTHS), 1);
idx = 0;
for i = SIGNAL_LENGTHS
    if exist("PROGRESS", 'var')
        pd_state = pd_state + 1;
        PROGRESS.Value = pd_state / (file_count + 13);
        PROGRESS.Message = ...
            "Vytv�ra sa tabu�ka �tatistick�ch parametrov pre " + i + ...
            "-min�tov� intervaly...";
    end
    idx = idx + 1;
    SIGNAL_LENGTHS_STRINGS_NEW(idx) = i + " min";
    eval("stats_" + i + "_NEW = create_statistics(values_clean_NEW, i);");
end

% T�to �as� k�du rozdel� �ist� �daje pod�a rokov:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Rozde�uj� sa �daje pod�a rokov...";
end
YEARS = unique(values_clean_NEW.Time.Year);
YEARS_STRINGS_NEW = string(YEARS);
for i = 1:size(YEARS, 1)
    eval("values_clean_" + YEARS(i) + ...
        "_NEW = values_clean_NEW(values_clean_NEW.Time.Year == " + ...
        "YEARS(i), :);");
    eval("values_excluded_" + YEARS(i) + ...
        "_NEW = values_excluded_NEW(values_excluded_NEW.Time.Year == " + ...
        "YEARS(i), :);");
    if ~isempty(values_filled_NEW)
        eval("values_filled_" + YEARS(i) + ...
            "_NEW = values_filled_NEW(values_filled_NEW.Time.Year == " + ...
            "YEARS(i), :);");
    end
    for j = SIGNAL_LENGTHS
        eval("stats_" + j + "_" + YEARS(i) + ...
            "_NEW = stats_" + j + "_NEW(stats_" + j + ...
            "_NEW.DateStart.Year == YEARS(i), :);");
    end
end

% T�to �as� otvor� s��asn� �daje:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Otv�raj� sa s��asn� �daje...";
end
NEW_DATA_PATH = BASE_PATH + "\2. Pripraven� �daje\";
ANALYSIS_PATH = BASE_PATH + "\3. Anal�za �dajov\";
MISSING_PATH = BASE_PATH + "\3. Anal�za �dajov\" + ...
    "Chyby �dajov\Automaticky upraven� riadky\";
for i = 1:size(YEARS, 1)
    try
        for j = 1:size(SIGNAL_LENGTHS, 2)
            load(NEW_DATA_PATH + "stats_" + YEARS(i) + ...
                ".mat", "stats_" + SIGNAL_LENGTHS(j) + "_" + YEARS(i));
        end
        load(NEW_DATA_PATH + "values_clean_" + YEARS(i) + ...
            ".mat", "values_clean_" + YEARS(i));
        load(NEW_DATA_PATH + "values_excluded_" + YEARS(i) + ...
            ".mat", "values_excluded_" + YEARS(i));
        if ~isempty(values_filled_NEW)
            load(NEW_DATA_PATH + "values_filled_" + YEARS(i) + ...
                ".mat", "values_filled_" + YEARS(i));
        end
    catch
        for j = 1:size(SIGNAL_LENGTHS, 2)
            eval("stats_" + SIGNAL_LENGTHS(j) + "_" + YEARS(i) + " = [];");
        end
        eval("values_clean_" + YEARS(i) + " = [];");
        eval("values_excluded_" + YEARS(i) + " = [];");
        if ~isempty(values_filled_NEW)
            eval("values_filled_" + YEARS(i) + " = [];");
        end
    end
end
load(ANALYSIS_PATH + "years.mat", "YEARS_STRINGS");
load(ANALYSIS_PATH + "signal_lengths.mat", "SIGNAL_LENGTHS_STRINGS");
load(MISSING_PATH + "missing.mat", "missing");

% T�to �as� k�du prid� k s��asn�m �dajom nov� �daje s koncovkou _NEW:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Prid�vaj� sa nov� �daje...";
end
for i = 1:size(YEARS, 1)
    for j = 1:size(SIGNAL_LENGTHS, 2)
        eval("stats_" + SIGNAL_LENGTHS(j) + "_" + YEARS(i) + ...
            " = [stats_" + SIGNAL_LENGTHS(j) + "_" + YEARS(i) + ...
            "; stats_" + SIGNAL_LENGTHS(j) + "_" + YEARS(i) + "_NEW];");
    end
    eval("values_clean_" + YEARS(i) + " = [values_clean_" + YEARS(i) + ...
        "; values_clean_" + YEARS(i) + "_NEW];");
    eval("values_excluded_" + YEARS(i) + " = [values_excluded_" + ...
        YEARS(i) + "; values_excluded_" + YEARS(i) + "_NEW];");
    if ~isempty(values_filled_NEW)
        eval("values_filled_" + YEARS(i) + " = [values_filled_" + ...
            YEARS(i) + "; values_filled_" + YEARS(i) + "_NEW];");
    end
end
YEARS_STRINGS = unique([YEARS_STRINGS; YEARS_STRINGS_NEW]);
SIGNAL_LENGTHS_STRINGS = ...
    unique([SIGNAL_LENGTHS_STRINGS; SIGNAL_LENGTHS_STRINGS_NEW]);
if isempty(missing_NEW)
    missing_NEW = [];
elseif size(missing, 2) ~= size(missing_NEW, 2)
    missing.NEW_Data = cell(height(missing), 1);
    missing.NEW_Missing = zeros(height(missing), 1);
end
missing = [missing; missing_NEW];

% T�to �as� k�du ulo�� v�etky �daje do pr�slu�n�ch prie�inkov:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Ukladaj� sa �daje...";
end
for i = 1:size(YEARS, 1)
    save(NEW_DATA_PATH + "stats_" + YEARS(i) + ".mat", "stats_" + ...
        SIGNAL_LENGTHS(1) + "_" + YEARS(i), "-v7.3");
    for j = 2:length(SIGNAL_LENGTHS)
        save(NEW_DATA_PATH + "stats_" + YEARS(i) + ".mat", "stats_" + ...
            SIGNAL_LENGTHS(j) + "_" + YEARS(i), "-append");
    end
    save(NEW_DATA_PATH + "values_clean_" + YEARS(i) + ".mat", ...
        "values_clean_" + YEARS(i), "-v7.3");
    save(NEW_DATA_PATH + "values_excluded_" + YEARS(i) + ".mat", ...
        "values_excluded_" + YEARS(i), "-v7.3");
    if ~isempty(values_filled_NEW)
        save(NEW_DATA_PATH + "values_filled_" + YEARS(i) + ".mat", ...
            "values_filled_" + YEARS(i), "-v7.3");
    end
end
save(ANALYSIS_PATH + "years.mat", "YEARS_STRINGS", "-v7.3");
save(ANALYSIS_PATH + "signal_lengths.mat", "SIGNAL_LENGTHS_STRINGS", "-v7.3");
save(MISSING_PATH + "missing.mat", "missing", "-v7.3");

end
