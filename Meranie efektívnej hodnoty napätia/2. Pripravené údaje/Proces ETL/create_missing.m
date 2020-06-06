function varargout = create_missing(varargin)
% Vstupn� argumenty funkcie:
% CLEAN =       �asov� tabu�ka �ist�ch �dajov po �prave ETL procesom.
% RECORD_STEP = Interval krokovania meracieho pr�stroja v sekund�ch.
CLEAN = varargin{1};
RECORD_STEP = varargin{2};

% Inicializa�n� �as� funkcie:
% V tejto �asti sa spusti �asova� a zaznamen�vanie v�etk�ho, �o sa
% prostredn�ctvom funkcie fprintf ocitne v okne pr�kazov�ho riadku. Z�znam
% sa n�sledne ulo�� pod n�zvom log_create_missing.txt do zlo�ky Proces
% ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripraven� �daje\Proces ETL\";
diary (LOG_PATH + "log_create_missing.txt");

fprintf("D�tum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("�as:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPN�-ARGUMENTY-----\n");
fprintf("Tabu�ka values_clean:\t%s\n", inputname(1));
fprintf("Krokovanie (s):\t\t\t%d\n", RECORD_STEP);
fprintf("---------------------------\n");
fprintf("Vytv�ra sa tabu�ka...\n");

% Vytvor� pr�zdne tabu�ky s n�zvami MISSING (v�stup tejto funkcie) a temp
% (pomocn� tabu�ka pre v�po�ty).:
STEP = seconds(RECORD_STEP);
MISSING = table;
temp = table;

% Pomocn� tabu�ka pre tvorbu hlavnej v�stupnej tabu�ky MISSING:
% Pomocou met�dy porovn�vania rozdielov v �ase medzi riadkami, v ktor�ch s�
% ulo�en� �daje o d�tume a �ase, funkcia zist� interval ch�baj�cich riadkov
% z h�adiska �asu.:
temp.time = datetime(CLEAN.Time(1):STEP:CLEAN.Time(end))';
temp.membership = ismember(temp.time, CLEAN.Time);
temp.diff = [0; diff(temp.membership)];
temp(temp.diff == 0, :) = [];
temp = sortrows(temp, "diff", "ascend");

% Hlavn� v�stupn� tabu�ka MISSING:
% V prvom st�pci sa bud� nach�dza� d�tumy a �asy, kedy meranie bolo z
% nezn�meho d�vodu pozastaven�. V druhom st�pci sa bud� nach�dza� d�tumy a
% �asy, kedy meranie pokra�uje. V tre�om st�pci sa bud� nach�dza� numerick�
% hodnoty predstavuj�ce po�et ch�baj�cich hod�n, preto�e ch�ba� m��u len
% presn� n�sobky hod�n po ETL procese spracovania zozbieran�ch �dajov.:
MISSING.Begin = temp.time(1:(size(temp, 1) / 2));
MISSING.End = temp.time(((size(temp, 1) / 2) + 1):end);
MISSING.Hours = hours(MISSING.End - MISSING.Begin);
MISSING = sortrows(MISSING, "Hours", "ascend");

% Ukon�ovacia �as� funkcie:
% V tejto �asti funkcia vr�ti v�etky v�stupn� argumenty a vyp�e d�ku
% trvania v�po�tov tejto funkcie. Z�rove� sa ukon�� a ulo�� z�znam do
% textov�ho s�boru log_create_missing.txt.:
fprintf("Uplynut� �as: %s.\n", datestr(seconds(toc), 'HH:MM:SS'));
fprintf("Vytv�ranie tabu�ky bolo �spe�ne dokon�en�.\n");
fprintf("===========================\n");
diary off;
beep;

% V�stupn� argumenty funkcie:
% MISSING = Tabu�ka z�znamov ch�baj�cich hodn�t, ktor� boli vypusten�
%           ETL procesom z anal�zy �dajov.
varargout{1} = MISSING;

end
