function varargout = create_filled(varargin)
% Vstupn� argumenty funkcie:
% TABLE =       Tabu�ka z�znamov ch�baj�cich hodn�t, ktor� boli vypusten�
%               ETL procesom z anal�zy �dajov.
% EXCLUDED =	�asov� tabu�ka vypusten�ch �dajov po �prave ETL procesom.
% RECORD_STEP = Interval krokovania meracieho pr�stroja v sekund�ch.
% TOLERANCE =   Numerick� hodnota, ktor� predstavuje horn� hranicu po�tu
%               hod�n vr�tane, kedy e�te algoritmus tejto funkcie vypln�
%               ch�baj�ce riadky �dajov.
TABLE = varargin{1};
EXCLUDED = varargin{2};
RECORD_STEP = varargin{3};
TOLERANCE = varargin{4};

% Inicializa�n� �as� funkcie:
% V tejto �asti sa spusti �asova� a zaznamen�vanie v�etk�ho, �o sa
% prostredn�ctvom funkcie fprintf ocitne v okne pr�kazov�ho riadku. Z�znam
% sa n�sledne ulo�� pod n�zvom log_create_filled.txt do zlo�ky Proces ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripraven� �daje\Proces ETL\";
diary (LOG_PATH + "log_create_filled.txt");

fprintf("D�tum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("�as:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPN�-ARGUMENTY-----\n");
fprintf("Tabu�ka missing:\t\t\t%s\n", inputname(1));
fprintf("Tabu�ka values_excluded:\t%s\n", inputname(2));
fprintf("Tolerancia (h):\t\t\t\t%d\n", TOLERANCE);
fprintf("---------------------------\n");
fprintf("Vytv�ra sa tabu�ka...\n");

% Funkcia na��ta tabu�ku MISSING, ktor� je v�stupom funkcie create_missing.
% Funkcia zorad� tabu�ku pod�a po�tu ch�baj�cich hod�n a na z�klade po�tu
% riadkov tabu�ky MISSING funkcia ur�i po�et cyklov nasleduj�cej �asti
% k�du.:
TABLE = sortrows(TABLE, "Hours", 'ascend');
LENGHT = size(TABLE, 1);
STEP = seconds(RECORD_STEP);
FILLED = [];

% V tejto �asti k�du, postupne od prv�ho riadku tabu�ky MISSING zbehne
% hlavn� cyklus for, ktor� pre ka�d� ne�pln� N-hodinov� interval
% (pri�om N = TOLERANCE), dopo��ta pomocou met�dy automatick�ho dop��ania
% ch�baj�cich �dajov a pomocou pohybliv�ho priemeru vypo��tan�ho z
% okolit�ch �dajov dopln� tieto medzery v riadkoch.:
for i = 1:LENGHT
    % Funkcia od��ta hranice intervalu ch�baj�cich hodn�t v danom riadku
    % tabu�ky MISSING. Na z�klade t�chto �dajov, funkcia vyextrahuje z
    % �asovej tabu�ky EXCLUDED v�etky nameran� �daje v tomto intervale,
    % ktor� s� pochopite�ne ne�pln�. V tejto �asti sa stanov� po�et
    % ch�baj�cich riadkov, po�et predpokladan�ch riadkov a po�et aktu�lnych
    % riadkov.:
    BEGIN = TABLE.Begin(i);
    END = TABLE.End(i);
    HOURS = TABLE.Hours(i);
    old_data = EXCLUDED(timerange(BEGIN, END), :);
    REGULAR_TIMES = datetime(BEGIN:STEP:END - seconds(1))';
    old_data = retime(old_data, REGULAR_TIMES);
    MISSING = sum(isnan(old_data.Value));
    EXPECTED = seconds(hours(HOURS)) / RECORD_STEP;
    ACTUAL = EXPECTED - MISSING;

    % �lohou tejto �asti k�du je doplni� ne�pln� �asov� tabu�ky pomocou
    % met�dy pohybliv�ho priemeru a to v z�vislosti od predpokladanej
    % pr��iny absencie t�chto �dajov. Ke�e nevieme s istotou ur�i�
    % pr��inu, m��eme sa len domnieva� na z�klade po�tu ch�baj�cich
    % hodn�t aj to len v nieko�k�ch konkr�tnych pr�padoch.:
    TABLE.OLD_Data{i} = old_data;
    TABLE.OLD_Missing(i) = MISSING;
    TABLE.OLD_Missing_Percents(i) = round(MISSING / EXPECTED, 4) * 100;
    if HOURS <= TOLERANCE
        % Pr�pad �.1:
        % Pr�pad, kedy nebola v danom �asovom intervale nameran� ani jedn�
        % hodnota. V takomto pr�pade nie je �o dop��a� a �sek ost�va
        % pr�zdny.:
        if ACTUAL == 0
            TABLE.NEW_Data{i} = [];
            TABLE.NEW_Missing(i) = EXPECTED;
        % Pr�pad �.2:
        % Pr�pad, kedy sa v�etky nameran� hodnoty rovnaj� jedn�mu a tomu
        % ist�mu ��slu a z�rove� nebolo meranie po�as tohto �asov�ho �seku
        % vynechan�. V takomto pr�pade sa do tabu�ky MISSING zap�e k
        % tomuto z�znamu nere�lna hodnota -1 do st�pca s po�tom vynechan�ch
        % hodn�t. Sl��i len na odl�enie pre pou��vate�a, �e sa jedn� o
        % tento �pecifick� pr�pad.:
        elseif ACTUAL == EXPECTED && range(old_data.Value) == 0
            TABLE.NEW_Data{i} = [];
            TABLE.NEW_Missing(i) = -1;
            TABLE.NEW_Missing(i) = EXPECTED;
        % Pr�pad �.3:
        % Pr�pad podobn� pr�padu �.2 av�ak s t�m rozdielom, �e meran�
        % sign�l nie je kon�tantn�. Ide o �pecifick� pr�pad, kedy bol
        % (pravdepodobne) bezchybn� �asov� �sek vyhodnoten� ako chybn�.
        % Ke�e tak�to �asov� �sek nem� �iadne ch�baj�ce riadky, funkcia
        % nevykon� �iadne zmeny a posunie tento �sek do tabu�ky FILLED bez
        % �prav.:
        elseif ACTUAL == EXPECTED && range(old_data.Value) > 0
            TABLE.NEW_Data{i} = old_data;
            TABLE.NEW_Missing(i) = sum(isnan(TABLE.NEW_Data{i}.Value));
        % Pr�pad �.4:
        % �pecifick� pr�pad, kedy nast�va zmena zimn�ho �asu na letn� �as.
        % Opa�n� pr�pad kedy nast�va zmena letn�ho �asu na zimn� �as sa
        % nem��e dosta� do tabu�ky ne�pln�ch �asov�ch �sekov, preto�e do
        % tejto tabu�ky sa cez ETL proces dostan� len ne�pln� �asov� �seky.
        % To znamen�, �e by tam musela by� zaznamenan� aspo� jedn� hodnota
        % v tom �ase. Naopak v tomto pr�pade je vyhodnoten� v�dy 2-hodinov�
        % �asov� �sek, preto�e posledn� hodnota pred zmenou �asu sa
        % zaznamen� v�dy o 02:00:01 a kon�� o 03:00:00. V�aka posunu o
        % jednu sekundu dozadu sa vyhodnotil tento 1-hodinov� �asov� �sek
        % ako 2-hodinov� �asov� �sek, �o napom�ha funkcii identifikova�
        % tento �pecificky pr�pad. Z�rove� to znamen�, �e po�et ch�baj�cich
        % hodn�t (3600 riadkov) je rovn� po�tu aktu�lnych meran� (1. riadok
        % + 3599 riadkov, ktor� nasleduj� po hodinovej medzere). Podobne
        % ako v druhom pr�pade je tento �pecificky pr�pad ozna�en�
        % nere�lnou hodnotou po�tu ch�baj�cich riadkov a to -2.:
        elseif HOURS == 2 && ...
                MISSING == ACTUAL && ...
                old_data.Time.Month(1) == 3
            TABLE.Hours(i) = 1;
            old_data(isnan(old_data.Value), :) = [];
            old_data.Time(1) = old_data.Time(2) - seconds(1);
            TABLE.NEW_Data{i} = old_data;
            TABLE.NEW_Missing(i) = -2;
        % Pr�pad �.5:
        % Sem patria v�etky ostatn� pr�pady, ktor� je potrebn� doplni�
        % met�dou pohybliv�ho priebehu. V tomto pr�pade sa kontroluje
        % len podmienka, �i po�et riadkov je nenulov�. Do v�slednej �asovej
        % tabu�ky sa pos�va doplnen� �asov� �sek.:
        elseif ACTUAL > 0
            RANGE = seconds(MISSING + 1);
            TABLE.NEW_Data{i} = fillmissing(old_data, 'movmean', RANGE);
            TABLE.NEW_Data{i}.Value = round(TABLE.NEW_Data{i}.Value, 1);
            TABLE.NEW_Missing(i) = sum(isnan(TABLE.NEW_Data{i}.Value));
        end

        % Do v�stupnej �asovej tabu�ky FILLED, prid� funkcia doplnen�
        % �asov� �sek.:
        if i == 1
            FILLED = TABLE.NEW_Data{1};
        else
            FILLED = [FILLED; TABLE.NEW_Data{i}]; %#ok<AGROW>
        end
    end
end

% T�to �as� k�du ulo�� v�etky grafick� priebehy sign�lov, ktor� boli
% doplnen� v z�vislosti od stanovenej tolerancie dop��ania �dajov.:
FIGURES_PATH = BASE_PATH + "\3. Anal�za a vizualiz�cia �dajov\" ...
    + "Chyby �dajov\Automaticky upraven� riadky\Obr�zky\";
TABLE = sortrows(TABLE, {'Hours', 'Begin'}, 'ascend');
for i = 1:LENGHT
    if TABLE.Hours(i) <= TOLERANCE
        try
            h = figure;
            plot(h, TABLE.NEW_Data{i}.Time, TABLE.NEW_Data{i}.Value);
            savefig(h, FIGURES_PATH + i + ".fig");
            close(h);
        catch
            close(h);
        end
    end
end

% Ukon�ovacia �as� funkcie:
% V tejto �asti funkcia vr�ti v�etky v�stupn� argumenty a vyp�e d�ku
% trvania v�po�tov tejto funkcie. Z�rove� sa ukon�� a ulo�� z�znam do
% textov�ho s�boru log_create_filled.txt.:
fprintf("Uplynut� �as: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytv�ranie tabu�ky bolo �spe�ne dokon�en�.\n");
fprintf("===========================\n");
diary off;
beep;

% V�stupn� argumenty funkcie:
% TABLE =   Tabu�ka z�znamov ch�baj�cich hodn�t, ktor� boli vypusten�
%           ETL procesom z anal�zy �dajov. T�to tabu�ka je roz��ren� o
%           st�pce vyraden�ch hodn�t a st�pce doplnen�ch hodn�t.
% FILLED =  �asov� tabu�ka doplnen�ch �dajov po �prave ETL procesom.
varargout{1} = FILLED;
varargout{2} = TABLE;
end
