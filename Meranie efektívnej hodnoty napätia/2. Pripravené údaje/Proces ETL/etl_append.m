function etl_append(varargin)
% Vstupné argumenty funkcie:
% OLD_DATA_PATH =   cesta k prieèinku, v ktorom sa nachádzajú *.csv súbory
%                   alebo cesta ku konkrétnemu *.csv súboru.
% STEP =            interval krokovania meracieho prístroja v sekundách.
% UNITS =           jednotky meranıch velièín.
% TOLERANCE =       poèet maximálne tolerovanıch hodín, ktoré budú
%                   automatickı doplnené.
% PROGRESS =        ak je táto funkcia spustená cez aplikáciu, tak vïaka
%                   tomuto argumentu sa bude zobrazova v dialógovom okne
%                   progres vıpoètov.
OLD_DATA_PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};
TOLERANCE = varargin{4};
if nargin == 5
    PROGRESS = varargin{5};
end

% Táto èas kódu uloí do premennej s názvom BASE_PATH cestu v ktorej je
% uloená táto funkcia:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = string(join(BASE_PATH(1:end - 2), "\"));

% Táto èas kódu zavolá funkcie ETL procesu v príslušnom poradí:
% Najprv vytvorí èasovú tabu¾ku s názvom values_clean_NEW, kde budú uloené
% všetky údaje naèítané z *.CSV súborov po úprave ETL procesom. Následne tá
% istá funkcia s názvom create_values, resp. create_values_file uloí do
% premennej values_excluded_NEW všetky údaje vyradené ETL procesom.
% Podmienka: Ak je prvım vstupnım argumentom cesta k *.csv súboru, zavolá
% sa funkcia create_values_file.:
is_file = contains(OLD_DATA_PATH, ".csv");
if is_file
    % Inicializaèná èas funkcie create_values_file:
    % V tejto èasti sa spusti èasovaè a zaznamenávanie všetkého, èo sa
    % prostredníctvom funkcie fprintf ocitne v okne príkazového riadku.
    % Záznam sa následne uloí pod názvom log_create_values.txt do zloky
    % Proces ETL.:
    tic;
    LOG_PATH = BASE_PATH + "\2. Pripravené údaje\Proces ETL\";
    diary (LOG_PATH + "\log_create_values.txt");

    fprintf("Dátum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
    fprintf("Èas:\t" + datestr(now, "HH:MM") + "\n");
    fprintf("-----VSTUPNÉ-ARGUMENTY-----\n");
    fprintf("Cesta k súboru:\t\t""%s""\n", OLD_DATA_PATH);
    fprintf("Krokovanie (s):\t\t%d\n", STEP);
    fprintf("Jednotky:\t\t\t""%s""\n", UNITS);
    fprintf("---------------------------\n");

    % Volanie funkcie create_values_file.:
    file_count = 1;
    [values_clean_NEW, values_excluded_NEW] = ...
        create_values_file(OLD_DATA_PATH, STEP, UNITS);

    % Ukonèovacia èas funkcie create_values_file:
    % V tejto èasti funkcia vráti všetky vıstupné argumenty a vypíše dåku
    % trvania vıpoètov tejto funkcie. Zároveò sa ukonèí a uloí záznam do
    % textového súboru log_create_values.txt.:
    fprintf("Uplynutı èas: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
    fprintf("Vytváranie tabu¾ky bolo úspešne dokonèené.\n");
    fprintf("===========================\n");
    diary off;
    beep;
% Podmienka: Ak je prvım vstupnım argumentom cesta k prieèinku, zavolá sa
% funkcia create_values.:
else
    % Volanie funkcie create_values.:
    [values_clean_NEW, values_excluded_NEW, file_count] = ...
        create_values(OLD_DATA_PATH, STEP, UNITS, PROGRESS);
end

% Následne funkcia s názvom create_missing vytvorí tabu¾ku s názvom
% missing_NEW, v ktorej budú uloené všetky údaje o chıbajúcich, resp.
% vyradenıch údajoch.:
if exist("PROGRESS", 'var')
    pd_state = file_count + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Vytvára sa tabu¾ka s názvom missing_NEW...";
end
missing_NEW = create_missing(values_clean_NEW, STEP);

% Táto tabu¾ka bude následne rozšírená o nieko¾ko ståpcov, v ktorıch budú
% uloené vyradené údaje a tieto údaje doplnené o chıbajúce hodnoty. Nové
% údaje budú uloené v èasovej tabu¾ke s názvom values_filled_NEW.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Dopåòajú sa chıbajúce hodnoty...";
end
[values_filled_NEW, missing_NEW] = ...
    create_filled(missing_NEW, values_excluded_NEW, STEP, TOLERANCE);

% Táto èas kódu spája èisté a doplnené hodnoty a následne ich triedi pod¾a
% èasu.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Zluèujú sa èisté a doplnené hodnoty...";
end
values_clean_NEW = [values_clean_NEW; values_filled_NEW];
values_clean_NEW = sortrows(values_clean_NEW, "Time");

% Táto èas kódu vytvorí tabu¾ky s názvom stats_YYYY_NEW
% (prièom YYYY = rok) pre všetky definované èasové intervaly uloené v
% premennej SIGNAL_LENGTHS.:
SIGNAL_LENGTHS = [10, 12, 15, 20, 30, 60];
SIGNAL_LENGTHS_STRINGS_NEW = strings(length(SIGNAL_LENGTHS), 1);
idx = 0;
for i = SIGNAL_LENGTHS
    if exist("PROGRESS", 'var')
        pd_state = pd_state + 1;
        PROGRESS.Value = pd_state / (file_count + 13);
        PROGRESS.Message = ...
            "Vytvára sa tabu¾ka štatistickıch parametrov pre " + i + ...
            "-minútové intervaly...";
    end
    idx = idx + 1;
    SIGNAL_LENGTHS_STRINGS_NEW(idx) = i + " min";
    eval("stats_" + i + "_NEW = create_statistics(values_clean_NEW, i);");
end

% Táto èas kódu rozdelí èisté údaje pod¾a rokov:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Rozde¾ujú sa údaje pod¾a rokov...";
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

% Táto èas otvorí súèasné údaje:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Otvárajú sa súèasné údaje...";
end
NEW_DATA_PATH = BASE_PATH + "\2. Pripravené údaje\";
ANALYSIS_PATH = BASE_PATH + "\3. Analıza údajov\";
MISSING_PATH = BASE_PATH + "\3. Analıza údajov\" + ...
    "Chyby údajov\Automaticky upravené riadky\";
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

% Táto èas kódu pridá k súèasnım údajom nové údaje s koncovkou _NEW:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Pridávajú sa nové údaje...";
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

% Táto èas kódu uloí všetky údaje do príslušnıch prieèinkov:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 13);
    PROGRESS.Message = "Ukladajú sa údaje...";
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
