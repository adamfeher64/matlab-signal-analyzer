function etl_update(varargin)
% Vstupné argumenty funkcie:
% OLD_DATA_PATH =   cesta k prieèinku, v ktorom sa nachádzajú *.csv súbory.
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
% uloená táto funkcia.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = string(join(BASE_PATH(1:end - 2), "\"));
% Táto èas kódu zavolá funkcie ETL procesu v príslušnom poradí:
% Najprv vytvorí èasovú tabu¾ku s názvom values, kde budú uloené všetky
% údaje naèítané z *.CSV súborov po úprave ETL procesom. Následne tá istá
% funkcia s názvom create_values uloí do premennej values_excluded všetky
% údaje vypustené ETL procesom.:
[values_clean, values_excluded, file_count] = ...
    create_values(OLD_DATA_PATH, STEP, UNITS, PROGRESS);
% Následne funkcia s názvom create_missing vytvorí tabu¾ku s názvom
% missing, v ktorej budú uloené všetky údaje o chıbajúcich, resp.
% vypustenıch údajoch.:
if exist("PROGRESS", 'var')
    pd_state = file_count + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Vytvára sa tabu¾ka s názvom missing...";
end
missing = create_missing(values_clean, STEP);
% Táto tabu¾ka bude následne rozšírená o nieko¾ko ståpcov, v ktorıch budú
% uloené vypustené údaje a tie iste údaje doplnené o chıbajúce hodnoty.
% Doplnené údaje budú uloené v èasovej tabu¾ke s názvom values_filled.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Dopåòajú sa chıbajúce hodnoty...";
end
[values_filled, missing] = ...
    create_filled(missing, values_excluded, STEP, TOLERANCE);
% Táto èas kódu spája èisté a doplnené hodnoty a následne ich zotriedi
% pod¾a èasu.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Zluèujú sa èisté a doplnené hodnoty...";
end
if ~isempty(values_filled)
    values_clean = [values_clean; values_filled];
    values_clean = sortrows(values_clean, "Time");
end
% Táto èas kódu vytvorí tabu¾ky s názvom stats pre všetky definované
% èasové intervaly uloené v premennej SIGNAL_LENGTHS.:
SIGNAL_LENGTHS = [10, 12, 15, 20, 30, 60];
SIGNAL_LENGTHS_STRINGS = strings(length(SIGNAL_LENGTHS), 1);
idx = 0;
for i = SIGNAL_LENGTHS
    if exist("PROGRESS", 'var')
        pd_state = pd_state + 1;
        PROGRESS.Value = pd_state / (file_count + 11);
        PROGRESS.Message = "Vytvára sa tabu¾ka štatistickıch " + ...
            "parametrov pre " + i + "-minútové intervaly...";
    end
    idx = idx + 1;
    SIGNAL_LENGTHS_STRINGS(idx) = i + " min";
    eval("stats_" + i + " = create_statistics(values_clean, i);");
end
% Táto èas kódu rozdelí údaje pod¾a rokov.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Rozde¾ujú sa údaje pod¾a rokov...";
end
YEARS = unique(values_clean.Time.Year);
YEARS_STRINGS = string(YEARS);
for i = 1:size(YEARS, 1)
    eval("values_clean_" + YEARS(i) + ...
        " = values_clean(values_clean.Time.Year == YEARS(i), :);");
    eval("values_excluded_" + YEARS(i) + ...
        " = values_excluded(values_excluded.Time.Year == YEARS(i), :);");
    if ~isempty(values_filled)
        eval("values_filled_" + YEARS(i) + ...
            " = values_filled(values_filled.Time.Year == YEARS(i), :);");
    end
    for j = SIGNAL_LENGTHS
        eval("stats_" + j + "_" + YEARS(i) + ...
            " = stats_" + j + "(stats_" + j + ...
            ".DateStart.Year == YEARS(i), :);");
    end
end
% Táto èas kódu uloí všetky údaje do príslušnıch prieèinkov.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Ukladajú sa údaje...";
end
NEW_DATA_PATH = BASE_PATH + "\2. Pripravené údaje\";
ANALYSIS_PATH = BASE_PATH + "\3. Analıza a vizualizácia údajov\";
MISSING_PATH = ANALYSIS_PATH + "Chyby údajov\Automaticky upravené riadky\";
for i = 1:size(YEARS, 1)
    save(NEW_DATA_PATH + "stats_" + YEARS(i) + ".mat", "stats_" + ...
        SIGNAL_LENGTHS(1) + "_" + YEARS(i), "-v7.3");
    for j = 2:length(SIGNAL_LENGTHS)
        save(NEW_DATA_PATH + "stats_" + YEARS(i) + ".mat", "stats_" + ...
            SIGNAL_LENGTHS(j) + "_" + YEARS(i), "-append");
    end
    save(NEW_DATA_PATH + "values_clean_" + YEARS(i) + ...
        ".mat", "values_clean_" + YEARS(i), "-v7.3");
    save(NEW_DATA_PATH + "values_excluded_" + YEARS(i) + ...
        ".mat", "values_excluded_" + YEARS(i), "-v7.3");
    if ~isempty(values_filled)
        save(NEW_DATA_PATH + "values_filled_" + YEARS(i) + ...
            ".mat", "values_filled_" + YEARS(i), "-v7.3");
    end
end
save(ANALYSIS_PATH + "years.mat", "YEARS_STRINGS", "-v7.3");
save(ANALYSIS_PATH + "signal_lengths.mat", "SIGNAL_LENGTHS_STRINGS", "-v7.3");
save(MISSING_PATH + "missing.mat", "missing", "-v7.3");
end
