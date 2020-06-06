function varargout = create_missing(varargin)
% Vstupné argumenty funkcie:
% CLEAN =       Èasová tabu¾ka èistıch údajov po úprave ETL procesom.
% RECORD_STEP = Interval krokovania meracieho prístroja v sekundách.
CLEAN = varargin{1};
RECORD_STEP = varargin{2};

% Inicializaèná èas funkcie:
% V tejto èasti sa spusti èasovaè a zaznamenávanie všetkého, èo sa
% prostredníctvom funkcie fprintf ocitne v okne príkazového riadku. Záznam
% sa následne uloí pod názvom log_create_missing.txt do zloky Proces
% ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripravené údaje\Proces ETL\";
diary (LOG_PATH + "log_create_missing.txt");

fprintf("Dátum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("Èas:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPNÉ-ARGUMENTY-----\n");
fprintf("Tabu¾ka values_clean:\t%s\n", inputname(1));
fprintf("Krokovanie (s):\t\t\t%d\n", RECORD_STEP);
fprintf("---------------------------\n");
fprintf("Vytvára sa tabu¾ka...\n");

% Vytvorí prázdne tabu¾ky s názvami MISSING (vıstup tejto funkcie) a temp
% (pomocná tabu¾ka pre vıpoèty).:
STEP = seconds(RECORD_STEP);
MISSING = table;
temp = table;

% Pomocná tabu¾ka pre tvorbu hlavnej vıstupnej tabu¾ky MISSING:
% Pomocou metódy porovnávania rozdielov v èase medzi riadkami, v ktorıch sú
% uloené údaje o dátume a èase, funkcia zistí interval chıbajúcich riadkov
% z h¾adiska èasu.:
temp.time = datetime(CLEAN.Time(1):STEP:CLEAN.Time(end))';
temp.membership = ismember(temp.time, CLEAN.Time);
temp.diff = [0; diff(temp.membership)];
temp(temp.diff == 0, :) = [];
temp = sortrows(temp, "diff", "ascend");

% Hlavná vıstupná tabu¾ka MISSING:
% V prvom ståpci sa budú nachádza dátumy a èasy, kedy meranie bolo z
% neznámeho dôvodu pozastavené. V druhom ståpci sa budú nachádza dátumy a
% èasy, kedy meranie pokraèuje. V treom ståpci sa budú nachádza numerické
% hodnoty predstavujúce poèet chıbajúcich hodín, pretoe chıba môu len
% presné násobky hodín po ETL procese spracovania zozbieranıch údajov.:
MISSING.Begin = temp.time(1:(size(temp, 1) / 2));
MISSING.End = temp.time(((size(temp, 1) / 2) + 1):end);
MISSING.Hours = hours(MISSING.End - MISSING.Begin);
MISSING = sortrows(MISSING, "Hours", "ascend");

% Ukonèovacia èas funkcie:
% V tejto èasti funkcia vráti všetky vıstupné argumenty a vypíše dåku
% trvania vıpoètov tejto funkcie. Zároveò sa ukonèí a uloí záznam do
% textového súboru log_create_missing.txt.:
fprintf("Uplynutı èas: %s.\n", datestr(seconds(toc), 'HH:MM:SS'));
fprintf("Vytváranie tabu¾ky bolo úspešne dokonèené.\n");
fprintf("===========================\n");
diary off;
beep;

% Vıstupné argumenty funkcie:
% MISSING = Tabu¾ka záznamov chıbajúcich hodnôt, ktoré boli vypustené
%           ETL procesom z analızy údajov.
varargout{1} = MISSING;

end
