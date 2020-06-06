function varargout = create_values(varargin)
% Vstupn� argumenty funkcie:
% PATH =	 Cesta k s�boru s pr�ponou *.CSV.
% STEP =	 ��rka krokov medzi jednotliv�mi meraniami v sekund�ch.
% UNITS =	 Jednotky, ktor� sa ulo�ili spolu s ��selnou hodnotou do
%            jedn�ho st�pca a je potrebn� ich odstr�ni�, preto�e je 
%            potrebn� ponecha� len ��seln� �daje. Ak nemaj� �daje �iadne 
%            jednotky, neuv�dza sa ni�.
% PROGRESS = Je potrebn� uvies� objekt dial�gov�ho okna v aplik�cii, pokia�
%            bola t�to funkcia zavolan� z aplik�cie.
DATA_PATH = varargin{1};
STEP = varargin{2};
UNITS = varargin{3};
if nargin == 4
    PROGRESS = varargin{4};
end

% Inicializa�n� �as� funkcie:
% V tejto �asti sa spusti �asova� a zaznamen�vanie v�etk�ho, �o sa
% prostredn�ctvom funkcie fprintf ocitne v okne pr�kazov�ho riadku. Z�znam
% sa n�sledne ulo�� pod n�zvom log_create_values.txt do zlo�ky Proces ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripraven� �daje\Proces ETL\";
diary (LOG_PATH + "\log_create_values.txt");

fprintf("D�tum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("�as:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPN�-ARGUMENTY-----\n");
fprintf("Cesta k prie�inku:\t""%s""\n", DATA_PATH);
fprintf("Krokovanie (s):\t\t%d\n", STEP);
fprintf("Jednotky:\t\t\t""%s""\n", UNITS);
fprintf("---------------------------\n");

% Funkcia vytvor� zoznam v�etk�ch *.CSV s�borov v zadanej zlo�ke a vyp�e
% ich po�et do pr�kazov�ho riadku.:
FOLDER = datastore(DATA_PATH + "\*.csv");
FILE_PATHS = FOLDER.Files;
FILE_COUNT = size(FILE_PATHS, 1);
fprintf("V prie�inku sa na�lo %d platn�ch s�borov.\n\n", FILE_COUNT);

% Z textov�ch re�azcov cel�ch ciest k jednotliv�m s�borom, funkcia
% vyextrahuje len n�zvy s�borov.:
FILE_NAMES = split(FILE_PATHS, "\");
FILE_NAMES = string(FILE_NAMES(:, end));

% Funkcia vyhrad� priestor na RAM pam�ti pre �daje, ktor� sa bud� v
% nasleduj�com cykle na��tava�.:
data = cell(4, 1);

% Hlavn� cyklus for:
% Cyklus postupne zavol� pre ka�d� *.CSV s�bor v prie�inku funkciu
% create_values_file a zl��i jednotliv� s�bory do jednej �asovej tabu�ky.
for i = 1:FILE_COUNT
    % Funkcia vyp�e do pr�kazov�ho riadku inform�ciu o n�zve s�boru, ktor�
    % vstupuje do ETL procesu.:
    MSG = "Pripravuje sa " + i + ". s�bor z celkov�ho po�tu " ...
        + FILE_COUNT + "...";
    fprintf("(%s)\n%s\n", FILE_NAMES(i), MSG);
    if exist("PROGRESS", 'var')
        PROGRESS.Value = i / (FILE_COUNT + 11);
        PROGRESS.Message = MSG;
    end

    % Funkcia postupne sp�ja �asov� tabu�ky, ktor� s� v�stupmi funkcie
    % create_values_file do jednej tabu�ky.:
    [data{3}, data{4}] = create_values_file(FILE_PATHS{i}, STEP, UNITS);
    data{1} = [data{1}; data{3}];
    data{2} = [data{2}; data{4}];
    data{3} = [];
    data{4} = [];
end

% V tejto �asti sa riadky v�sledn�ch �asov�ch tabuliek zoradia pod�a �asu a
% zaokr�h�uj� sa meran� hodnoty na prv� desatinn� miesto.:
if size(data{1}, 1) > 0
    % �asov� tabu�ka �ist�ch �dajov:
    fprintf("Vytv�ra sa �asov� tabu�ka �ist�ch �dajov...\n");
    CLEAN = sortrows(data{1}, 'Time');
    CLEAN.Value = round(CLEAN.Value, 1);
    CLEAN = retime(CLEAN, unique(CLEAN.Time));
    if size(data{2}, 1) > 0
        % �asov� tabu�ka vypusten�ch �dajov:
        fprintf("Vytv�ra sa �asov� tabu�ka vypusten�ch �dajov...\n");
        EXCLUDED = sortrows(data{2}, "Time");
        EXCLUDED.Value = round(EXCLUDED.Value, 1);
        EXCLUDED = retime(EXCLUDED, unique(EXCLUDED.Time));
    end
else
    % Pokia� nebol n�jden� �iadny s�bor s viac ako 3600 meraniami, funkcia
    % vr�ti pr�zdne �asov� tabu�ky.:
    fprintf("Nebol n�jden� �iadny s�bor s viac ako 3600 meraniami.\n");
    CLEAN = [];
    EXCLUDED = [];
end

% Ukon�ovacia �as� funkcie:
% V tejto �asti funkcia vr�ti v�etky v�stupn� argumenty a vyp�e d�ku
% trvania v�po�tov tejto funkcie. Z�rove� sa ukon�� a ulo�� z�znam do
% textov�ho s�boru log_create_values.txt.:
fprintf("Uplynut� �as: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytv�ranie tabu�ky bolo �spe�ne dokon�en�.\n");
fprintf("===========================\n");
diary off;

% V�stupn� argumenty funkcie:
% CLEAN =       �asov� tabu�ka �ist�ch �dajov po �prave ETL procesom.
% EXCLUDED =	�asov� tabu�ka vypusten�ch �dajov po �prave ETL procesom.
% FILE_COUNT =  Po�et *.CSV s�borov v prie�inku.
varargout{1} = CLEAN;
varargout{2} = EXCLUDED;
varargout{3} = FILE_COUNT;

end
