function varargout = create_values(varargin)
% Vstupné argumenty funkcie:
% PATH =	 Cesta k súboru s príponou *.CSV.
% STEP =	 Šírka krokov medzi jednotlivımi meraniami v sekundách.
% UNITS =	 Jednotky, ktoré sa uloili spolu s èíselnou hodnotou do
%            jedného ståpca a je potrebné ich odstráni, pretoe je 
%            potrebné ponecha len èíselné údaje. Ak nemajú údaje iadne 
%            jednotky, neuvádza sa niè.
% PROGRESS = Je potrebné uvies objekt dialógového okna v aplikácii, pokia¾
%            bola táto funkcia zavolaná z aplikácie.
DATA_PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};
if nargin == 4
    PROGRESS = varargin{4};
end

% Inicializaèná èas funkcie:
% V tejto èasti sa spusti èasovaè a zaznamenávanie všetkého, èo sa
% prostredníctvom funkcie fprintf ocitne v okne príkazového riadku. Záznam
% sa následne uloí pod názvom log_create_values.txt do zloky Proces ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripravené údaje\Proces ETL\";
diary (LOG_PATH + "\log_create_values.txt");

fprintf("Dátum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("Èas:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPNÉ-ARGUMENTY-----\n");
fprintf("Cesta k prieèinku:\t""%s""\n", DATA_PATH);
fprintf("Krokovanie (s):\t\t%d\n", STEP);
fprintf("Jednotky:\t\t\t""%s""\n", UNITS);
fprintf("---------------------------\n");

% Funkcia vytvorí zoznam všetkıch *.CSV súborov v zadanej zloke a vypíše
% ich poèet do príkazového riadku.:
FOLDER = datastore(DATA_PATH + "\*.csv");
FILE_PATHS = FOLDER.Files;
FILE_COUNT = size(FILE_PATHS, 1);
fprintf("V prieèinku sa našlo %d platnıch súborov.\n\n", FILE_COUNT);

% Z textovıch reazcov celıch ciest k jednotlivım súborom, funkcia
% vyextrahuje len názvy súborov.:
FILE_NAMES = split(FILE_PATHS, "\");
FILE_NAMES = string(FILE_NAMES(:, end));

% Funkcia vyhradí priestor na RAM pamäti pre údaje, ktoré sa budú v
% nasledujúcom cykle naèítava.:
data = cell(4, 1);

% Hlavnı cyklus for:
% Cyklus postupne zavolá pre kadı *.CSV súbor v prieèinku funkciu
% create_values_file a zlúèi jednotlivé súbory do jednej èasovej tabu¾ky.
for i = 1:FILE_COUNT
    % Funkcia vypíše do príkazového riadku informáciu o názve súboru, ktorı
    % vstupuje do ETL procesu.:
    MSG = "Pripravuje sa " + i + ". súbor z celkového poètu " ...
        + FILE_COUNT + "...";
    fprintf("(%s)\n%s\n", FILE_NAMES(i), MSG);
    if exist("PROGRESS", 'var')
        PROGRESS.Value = i / (FILE_COUNT + 11);
        PROGRESS.Message = MSG;
    end

    % Funkcia postupne spája èasové tabu¾ky, ktoré sú vıstupmi funkcie
    % create_values_file do jednej tabu¾ky.:
    [data{3}, data{4}] = create_values_file(FILE_PATHS{i}, STEP, UNITS);
    data{1} = [data{1}; data{3}];
    data{2} = [data{2}; data{4}];
    data{3} = [];
    data{4} = [];
end

% V tejto èasti sa riadky vıslednıch èasovıch tabuliek zoradia pod¾a èasu a
% zaokrúh¾ujú sa merané hodnoty na prvé desatinné miesto.:
if size(data{1}, 1) > 0
    % Èasová tabu¾ka èistıch údajov:
    fprintf("Vytvára sa èasová tabu¾ka èistıch údajov...\n");
    CLEAN = sortrows(data{1}, 'Time');
    CLEAN.Value = round(CLEAN.Value, 1);
    CLEAN = retime(CLEAN, unique(CLEAN.Time));
    if size(data{2}, 1) > 0
        % Èasová tabu¾ka vypustenıch údajov:
        fprintf("Vytvára sa èasová tabu¾ka vypustenıch údajov...\n");
        EXCLUDED = sortrows(data{2}, "Time");
        EXCLUDED.Value = round(EXCLUDED.Value, 1);
        EXCLUDED = retime(EXCLUDED, unique(EXCLUDED.Time));
    end
else
    % Pokia¾ nebol nájdenı iadny súbor s viac ako 3600 meraniami, funkcia
    % vráti prázdne èasové tabu¾ky.:
    fprintf("Nebol nájdenı iadny súbor s viac ako 3600 meraniami.\n");
    CLEAN = [];
    EXCLUDED = [];
end

% Ukonèovacia èas funkcie:
% V tejto èasti funkcia vráti všetky vıstupné argumenty a vypíše dåku
% trvania vıpoètov tejto funkcie. Zároveò sa ukonèí a uloí záznam do
% textového súboru log_create_values.txt.:
fprintf("Uplynutı èas: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytváranie tabu¾ky bolo úspešne dokonèené.\n");
fprintf("===========================\n");
diary off;

% Vıstupné argumenty funkcie:
% CLEAN =       Èasová tabu¾ka èistıch údajov po úprave ETL procesom.
% EXCLUDED =	Èasová tabu¾ka vypustenıch údajov po úprave ETL procesom.
% FILE_COUNT =  Poèet *.CSV súborov v prieèinku.
varargout{1} = CLEAN;
varargout{2} = EXCLUDED;
varargout{3} = FILE_COUNT;

end
