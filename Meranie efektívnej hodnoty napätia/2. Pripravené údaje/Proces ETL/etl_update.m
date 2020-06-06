function etl_update(varargin)
% Vstupn� argumenty funkcie:
% OLD_DATA_PATH =   cesta k prie�inku, v ktorom sa nach�dzaj� *.csv s�bory.
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
% ulo�en� t�to funkcia.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = string(join(BASE_PATH(1:end - 2), "\"));
% T�to �as� k�du zavol� funkcie ETL procesu v pr�slu�nom porad�:
% Najprv vytvor� �asov� tabu�ku s n�zvom values, kde bud� ulo�en� v�etky
% �daje na��tan� z *.CSV s�borov po �prave ETL procesom. N�sledne t� ist�
% funkcia s n�zvom create_values ulo�� do premennej values_excluded v�etky
% �daje vypusten� ETL procesom.:
[values_clean, values_excluded, file_count] = ...
    create_values(OLD_DATA_PATH, STEP, UNITS, PROGRESS);
% N�sledne funkcia s n�zvom create_missing vytvor� tabu�ku s n�zvom
% missing, v ktorej bud� ulo�en� v�etky �daje o ch�baj�cich, resp.
% vypusten�ch �dajoch.:
if exist("PROGRESS", 'var')
    pd_state = file_count + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Vytv�ra sa tabu�ka s n�zvom missing...";
end
missing = create_missing(values_clean, STEP);
% T�to tabu�ka bude n�sledne roz��ren� o nieko�ko st�pcov, v ktor�ch bud�
% ulo�en� vypusten� �daje a tie iste �daje doplnen� o ch�baj�ce hodnoty.
% Doplnen� �daje bud� ulo�en� v �asovej tabu�ke s n�zvom values_filled.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Dop��aj� sa ch�baj�ce hodnoty...";
end
[values_filled, missing] = ...
    create_filled(missing, values_excluded, STEP, TOLERANCE);
% T�to �as� k�du sp�ja �ist� a doplnen� hodnoty a n�sledne ich zotriedi
% pod�a �asu.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Zlu�uj� sa �ist� a doplnen� hodnoty...";
end
if ~isempty(values_filled)
    values_clean = [values_clean; values_filled];
    values_clean = sortrows(values_clean, "Time");
end
% T�to �as� k�du vytvor� tabu�ky s n�zvom stats pre v�etky definovan�
% �asov� intervaly ulo�en� v premennej SIGNAL_LENGTHS.:
SIGNAL_LENGTHS = [10, 12, 15, 20, 30, 60];
SIGNAL_LENGTHS_STRINGS = strings(length(SIGNAL_LENGTHS), 1);
idx = 0;
for i = SIGNAL_LENGTHS
    if exist("PROGRESS", 'var')
        pd_state = pd_state + 1;
        PROGRESS.Value = pd_state / (file_count + 11);
        PROGRESS.Message = "Vytv�ra sa tabu�ka �tatistick�ch " + ...
            "parametrov pre " + i + "-min�tov� intervaly...";
    end
    idx = idx + 1;
    SIGNAL_LENGTHS_STRINGS(idx) = i + " min";
    eval("stats_" + i + " = create_statistics(values_clean, i);");
end
% T�to �as� k�du rozdel� �daje pod�a rokov.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Rozde�uj� sa �daje pod�a rokov...";
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
% T�to �as� k�du ulo�� v�etky �daje do pr�slu�n�ch prie�inkov.:
if exist("PROGRESS", 'var')
    pd_state = pd_state + 1;
    PROGRESS.Value = pd_state / (file_count + 11);
    PROGRESS.Message = "Ukladaj� sa �daje...";
end
NEW_DATA_PATH = BASE_PATH + "\2. Pripraven� �daje\";
ANALYSIS_PATH = BASE_PATH + "\3. Anal�za a vizualiz�cia �dajov\";
MISSING_PATH = ANALYSIS_PATH + "Chyby �dajov\Automaticky upraven� riadky\";
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
