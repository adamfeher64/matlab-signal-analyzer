function varargout = create_statistics(varargin)
% Vstupn� argumenty funkcie:
% CLEAN =       �asov� tabu�ka �ist�ch �dajov po �prave ETL procesom.
% SAMPLE_SIZE = ��rka �asov�ho intervalu, pod�a ktor�ho sa bud� vypo��tava�
%               �tatistick� parametre. D�ka je uveden� v min�tach.
CLEAN = varargin{1};
SAMPLE_SIZE = varargin{2};

% Inicializa�n� �as� funkcie:
% V tejto �asti sa spusti �asova� a zaznamen�vanie v�etk�ho, �o sa
% prostredn�ctvom funkcie fprintf ocitne v okne pr�kazov�ho riadku. Z�znam
% sa n�sledne ulo�� pod n�zvom log_create_statistics.txt do zlo�ky Proces
% ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripraven� �daje\Proces ETL\";
diary (LOG_PATH + "log_create_statistics.txt");

fprintf("D�tum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("�as:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPN�-ARGUMENTY-----\n");
fprintf("Tabu�ka values_clean:\t%s\n", inputname(1));
fprintf("��rka intervalu:\t\t%d\n", SAMPLE_SIZE);
fprintf("---------------------------\n");
fprintf("Vytv�ra sa tabu�ka...\n");

% Zist� po�et riadkov �asovej tabu�ky �ist�ch �dajov a na z�klade toho
% vypo��ta po�et riadkov, ktor� je nevyhnutn� pre tvorbu tabu�ky
% �tatistick�ch parametrov:
SIZE_CLEAN = size(CLEAN, 1);
SAMPLE_SECONDS = seconds(minutes(SAMPLE_SIZE));
LENGHT = floor(SIZE_CLEAN / SAMPLE_SECONDS);


% Matica �dajov�ch typov a n�zvov st�pcov tabu�ky �tatistick�ch parametrov.
% Nevyhnutn� pri tvorbe, resp. definovan� akejko�vek pr�zdnej tabu�ky.:
SETUP = [
    "datetime", "DateStart";...
    "datetime", "DateStop";...
    "double", "Mean";...
    "double", "Mode";...
    "double", "Median";...
    "double", "Minimum";...
    "double", "Maximum";...
    "double", "Range";...
    "double", "IQR";...
    "double", "Variance";...
    "double", "SD";...
    "double", "RSD";...
    "double", "Skewness";...
    "double", "Kurtosis";...
    "double", "Equality";...
    "double", "SEM";...
    "double", "ProbableError";...
    "double", "AccuracyRate";...
];

% Vytvor� sa pr�zdna tabu�ka, do ktorej sa v �al�ej �asti funkcie ulo�ia
% �tatistick� parametre.:
STATS = table(...
    'Size', [LENGHT, size(SETUP, 1)],...
    'VariableTypes', SETUP(:, 1),...
    'VariableNames', SETUP(:, 2));

% Textov� re�azec pre cyklus for, ktor� definuje hranice intervalu v
% tabu�ke �ist�ch �dajov.:
LOCATION = "CLEAN.Value(((i - 1) * SAMPLE_SECONDS) + 1:";
LOCATION = LOCATION + "((i - 1) * SAMPLE_SECONDS) + SAMPLE_SECONDS)";

% Vypo��ta v�etky �tatistick� parametre pre ka�d� interval tabu�ky �ist�ch
% �dajov. Z�rove� tieto vypo��tan� hodnoty uklad� do tabu�ky �tatistick�ch
% parametrov.:
for i = 1:LENGHT
    STATS.DateStart(i) = CLEAN.Time(((i - 1) * SAMPLE_SECONDS) + 1);
    STATS.DateStop(i) = CLEAN.Time(((i - 1) * SAMPLE_SECONDS) + SAMPLE_SECONDS);
    STATS.Mean(i) = eval(sprintf("mean(%s)", LOCATION));
    STATS.Mode(i) = eval(sprintf("mode(%s)", LOCATION));
    STATS.Median(i) = eval(sprintf("median(%s)", LOCATION));
    STATS.Minimum(i) = eval(sprintf("min(%s)", LOCATION));
    STATS.Maximum(i) = eval(sprintf("max(%s)", LOCATION));
    STATS.Range(i) = eval(sprintf("range(%s)", LOCATION));
    STATS.IQR(i) = eval(sprintf("iqr(%s)", LOCATION));
    STATS.Variance(i) = eval(sprintf("var(%s)", LOCATION));
    STATS.SD(i) = eval(sprintf("std(%s)", LOCATION));
    STATS.Skewness(i) = eval(sprintf("skewness(%s)", LOCATION));
    STATS.Kurtosis(i) = eval(sprintf("kurtosis(%s)", LOCATION));
end

% Vypo��ta a dopln� tabu�ku �tatistick�ch parametrov o �al�ie �tatistick�
% parametre, ktor� s� odvoden� z vy��ie vypo��tan�ch parametrov.:
STATS.RSD = (STATS.SD ./ STATS.Mean) * 100;
STATS.Equality = std([STATS.Mean, STATS.Mode, STATS.Median], [], 2);
STATS.SEM = STATS.SD / sqrt(SAMPLE_SECONDS);
STATS.ProbableError = STATS.SD * 0.6745;
STATS.AccuracyRate = 1 ./ (STATS.SD * sqrt(2));

% Ukon�ovacia �as� funkcie:
% V tejto �asti funkcia vr�ti v�etky v�stupn� argumenty a vyp�e d�ku
% trvania v�po�tov tejto funkcie. Z�rove� sa ukon�� a ulo�� z�znam do
% textov�ho s�boru log_create_statistics.txt.:
fprintf("Uplynut� �as: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytv�ranie tabu�ky bolo �spe�ne dokon�en�.\n");
fprintf("===========================\n");
diary off;
beep;

% V�stupn� argumenty funkcie:
% STATS =   Tabu�ka �tatistick�ch parametrov.
varargout{1} = STATS;

end
