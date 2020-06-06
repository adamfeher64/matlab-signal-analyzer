function varargout = create_statistics(varargin)
% Vstupné argumenty funkcie:
% CLEAN =       Èasová tabu¾ka èistıch údajov po úprave ETL procesom.
% SAMPLE_SIZE = Šírka èasového intervalu, pod¾a ktorého sa budú vypoèítava
%               štatistické parametre. Dåka je uvedená v minútach.
CLEAN = varargin{1};
SAMPLE_SIZE = varargin{2};

% Inicializaèná èas funkcie:
% V tejto èasti sa spusti èasovaè a zaznamenávanie všetkého, èo sa
% prostredníctvom funkcie fprintf ocitne v okne príkazového riadku. Záznam
% sa následne uloí pod názvom log_create_statistics.txt do zloky Proces
% ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripravené údaje\Proces ETL\";
diary (LOG_PATH + "log_create_statistics.txt");

fprintf("Dátum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("Èas:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPNÉ-ARGUMENTY-----\n");
fprintf("Tabu¾ka values_clean:\t%s\n", inputname(1));
fprintf("Šírka intervalu:\t\t%d\n", SAMPLE_SIZE);
fprintf("---------------------------\n");
fprintf("Vytvára sa tabu¾ka...\n");

% Zistí poèet riadkov èasovej tabu¾ky èistıch údajov a na základe toho
% vypoèíta poèet riadkov, ktorı je nevyhnutnı pre tvorbu tabu¾ky
% štatistickıch parametrov:
SIZE_CLEAN = size(CLEAN, 1);
SAMPLE_SECONDS = seconds(minutes(SAMPLE_SIZE));
LENGHT = floor(SIZE_CLEAN / SAMPLE_SECONDS);


% Matica údajovıch typov a názvov ståpcov tabu¾ky štatistickıch parametrov.
% Nevyhnutná pri tvorbe, resp. definovaní akejko¾vek prázdnej tabu¾ky.:
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

% Vytvorí sa prázdna tabu¾ka, do ktorej sa v ïalšej èasti funkcie uloia
% štatistické parametre.:
STATS = table(...
    'Size', [LENGHT, size(SETUP, 1)],...
    'VariableTypes', SETUP(:, 1),...
    'VariableNames', SETUP(:, 2));

% Textovı reazec pre cyklus for, ktorı definuje hranice intervalu v
% tabu¾ke èistıch údajov.:
LOCATION = "CLEAN.Value(((i - 1) * SAMPLE_SECONDS) + 1:";
LOCATION = LOCATION + "((i - 1) * SAMPLE_SECONDS) + SAMPLE_SECONDS)";

% Vypoèíta všetky štatistické parametre pre kadı interval tabu¾ky èistıch
% údajov. Zároveò tieto vypoèítané hodnoty ukladá do tabu¾ky štatistickıch
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

% Vypoèíta a doplní tabu¾ku štatistickıch parametrov o ïalšie štatistické
% parametre, ktoré sú odvodené z vyššie vypoèítanıch parametrov.:
STATS.RSD = (STATS.SD ./ STATS.Mean) * 100;
STATS.Equality = std([STATS.Mean, STATS.Mode, STATS.Median], [], 2);
STATS.SEM = STATS.SD / sqrt(SAMPLE_SECONDS);
STATS.ProbableError = STATS.SD * 0.6745;
STATS.AccuracyRate = 1 ./ (STATS.SD * sqrt(2));

% Ukonèovacia èas funkcie:
% V tejto èasti funkcia vráti všetky vıstupné argumenty a vypíše dåku
% trvania vıpoètov tejto funkcie. Zároveò sa ukonèí a uloí záznam do
% textového súboru log_create_statistics.txt.:
fprintf("Uplynutı èas: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytváranie tabu¾ky bolo úspešne dokonèené.\n");
fprintf("===========================\n");
diary off;
beep;

% Vıstupné argumenty funkcie:
% STATS =   Tabu¾ka štatistickıch parametrov.
varargout{1} = STATS;

end
