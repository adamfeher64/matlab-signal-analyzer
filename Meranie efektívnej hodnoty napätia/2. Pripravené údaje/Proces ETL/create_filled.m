function varargout = create_filled(varargin)
% Vstupné argumenty funkcie:
% TABLE =       Tabu¾ka záznamov chıbajúcich hodnôt, ktoré boli vypustené
%               ETL procesom z analızy údajov.
% EXCLUDED =	Èasová tabu¾ka vypustenıch údajov po úprave ETL procesom.
% RECORD_STEP = Interval krokovania meracieho prístroja v sekundách.
% TOLERANCE =   Numerická hodnota, ktorá predstavuje hornú hranicu poètu
%               hodín vrátane, kedy ešte algoritmus tejto funkcie vyplní
%               chıbajúce riadky údajov.
TABLE = varargin{1};
EXCLUDED = varargin{2};
RECORD_STEP = varargin{3};
TOLERANCE = varargin{4};

% Inicializaèná èas funkcie:
% V tejto èasti sa spusti èasovaè a zaznamenávanie všetkého, èo sa
% prostredníctvom funkcie fprintf ocitne v okne príkazového riadku. Záznam
% sa následne uloí pod názvom log_create_filled.txt do zloky Proces ETL.:
tic;
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
LOG_PATH = BASE_PATH + "\2. Pripravené údaje\Proces ETL\";
diary (LOG_PATH + "log_create_filled.txt");

fprintf("Dátum:\t" + datestr(now, "dd.mm.yyyy") + "\n");
fprintf("Èas:\t" + datestr(now, "HH:MM") + "\n");
fprintf("-----VSTUPNÉ-ARGUMENTY-----\n");
fprintf("Tabu¾ka missing:\t\t\t%s\n", inputname(1));
fprintf("Tabu¾ka values_excluded:\t%s\n", inputname(2));
fprintf("Tolerancia (h):\t\t\t\t%d\n", TOLERANCE);
fprintf("---------------------------\n");
fprintf("Vytvára sa tabu¾ka...\n");

% Funkcia naèíta tabu¾ku MISSING, ktorá je vıstupom funkcie create_missing.
% Funkcia zoradí tabu¾ku pod¾a poètu chıbajúcich hodín a na základe poètu
% riadkov tabu¾ky MISSING funkcia urèi poèet cyklov nasledujúcej èasti
% kódu.:
TABLE = sortrows(TABLE, "Hours", 'ascend');
LENGHT = size(TABLE, 1);
STEP = seconds(RECORD_STEP);
FILLED = [];

% V tejto èasti kódu, postupne od prvého riadku tabu¾ky MISSING zbehne
% hlavnı cyklus for, ktorı pre kadı neúplnı N-hodinovı interval
% (prièom N = TOLERANCE), dopoèíta pomocou metódy automatického dopåòania
% chıbajúcich údajov a pomocou pohyblivého priemeru vypoèítaného z
% okolitıch údajov doplní tieto medzery v riadkoch.:
for i = 1:LENGHT
    % Funkcia odèíta hranice intervalu chıbajúcich hodnôt v danom riadku
    % tabu¾ky MISSING. Na základe tıchto údajov, funkcia vyextrahuje z
    % èasovej tabu¾ky EXCLUDED všetky namerané údaje v tomto intervale,
    % ktoré sú pochopite¾ne neúplné. V tejto èasti sa stanoví poèet
    % chıbajúcich riadkov, poèet predpokladanıch riadkov a poèet aktuálnych
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

    % Úlohou tejto èasti kódu je doplni neúplné èasové tabu¾ky pomocou
    % metódy pohyblivého priemeru a to v závislosti od predpokladanej
    % príèiny absencie tıchto údajov. Keïe nevieme s istotou urèi
    % príèinu, môeme sa len domnieva na základe poètu chıbajúcich
    % hodnôt aj to len v nieko¾kıch konkrétnych prípadoch.:
    TABLE.OLD_Data{i} = old_data;
    TABLE.OLD_Missing(i) = MISSING;
    TABLE.OLD_Missing_Percents(i) = round(MISSING / EXPECTED, 4) * 100;
    if HOURS <= TOLERANCE
        % Prípad è.1:
        % Prípad, kedy nebola v danom èasovom intervale nameraná ani jedná
        % hodnota. V takomto prípade nie je èo dopåòa a úsek ostáva
        % prázdny.:
        if ACTUAL == 0
            TABLE.NEW_Data{i} = [];
            TABLE.NEW_Missing(i) = EXPECTED;
        % Prípad è.2:
        % Prípad, kedy sa všetky namerané hodnoty rovnajú jednému a tomu
        % istému èíslu a zároveò nebolo meranie poèas tohto èasového úseku
        % vynechané. V takomto prípade sa do tabu¾ky MISSING zapíše k
        % tomuto záznamu nereálna hodnota -1 do ståpca s poètom vynechanıch
        % hodnôt. Slúi len na odlíšenie pre pouívate¾a, e sa jedná o
        % tento špecifickı prípad.:
        elseif ACTUAL == EXPECTED && range(old_data.Value) == 0
            TABLE.NEW_Data{i} = [];
            TABLE.NEW_Missing(i) = -1;
            TABLE.NEW_Missing(i) = EXPECTED;
        % Prípad è.3:
        % Prípad podobnı prípadu è.2 avšak s tım rozdielom, e meranı
        % signál nie je konštantnı. Ide o špecifickı prípad, kedy bol
        % (pravdepodobne) bezchybnı èasovı úsek vyhodnotenı ako chybnı.
        % Keïe takıto èasovı úsek nemá iadne chıbajúce riadky, funkcia
        % nevykoná iadne zmeny a posunie tento úsek do tabu¾ky FILLED bez
        % úprav.:
        elseif ACTUAL == EXPECTED && range(old_data.Value) > 0
            TABLE.NEW_Data{i} = old_data;
            TABLE.NEW_Missing(i) = sum(isnan(TABLE.NEW_Data{i}.Value));
        % Prípad è.4:
        % Špecifickı prípad, kedy nastáva zmena zimného èasu na letnı èas.
        % Opaènı prípad kedy nastáva zmena letného èasu na zimnı èas sa
        % nemôe dosta do tabu¾ky neúplnıch èasovıch úsekov, pretoe do
        % tejto tabu¾ky sa cez ETL proces dostanú len neúplné èasové úseky.
        % To znamená, e by tam musela by zaznamenaná aspoò jedná hodnota
        % v tom èase. Naopak v tomto prípade je vyhodnotenı vdy 2-hodinovı
        % èasovı úsek, pretoe posledná hodnota pred zmenou èasu sa
        % zaznamená vdy o 02:00:01 a konèí o 03:00:00. Vïaka posunu o
        % jednu sekundu dozadu sa vyhodnotil tento 1-hodinovı èasovı úsek
        % ako 2-hodinovı èasovı úsek, èo napomáha funkcii identifikova
        % tento špecificky prípad. Zároveò to znamená, e poèet chıbajúcich
        % hodnôt (3600 riadkov) je rovnı poètu aktuálnych meraní (1. riadok
        % + 3599 riadkov, ktoré nasledujú po hodinovej medzere). Podobne
        % ako v druhom prípade je tento špecificky prípad oznaèenı
        % nereálnou hodnotou poètu chıbajúcich riadkov a to -2.:
        elseif HOURS == 2 && ...
                MISSING == ACTUAL && ...
                old_data.Time.Month(1) == 3
            TABLE.Hours(i) = 1;
            old_data(isnan(old_data.Value), :) = [];
            old_data.Time(1) = old_data.Time(2) - seconds(1);
            TABLE.NEW_Data{i} = old_data;
            TABLE.NEW_Missing(i) = -2;
        % Prípad è.5:
        % Sem patria všetky ostatné prípady, ktoré je potrebné doplni
        % metódou pohyblivého priebehu. V tomto prípade sa kontroluje
        % len podmienka, èi poèet riadkov je nenulovı. Do vıslednej èasovej
        % tabu¾ky sa posúva doplnenı èasovı úsek.:
        elseif ACTUAL > 0
            RANGE = seconds(MISSING + 1);
            TABLE.NEW_Data{i} = fillmissing(old_data, 'movmean', RANGE);
            TABLE.NEW_Data{i}.Value = round(TABLE.NEW_Data{i}.Value, 1);
            TABLE.NEW_Missing(i) = sum(isnan(TABLE.NEW_Data{i}.Value));
        end

        % Do vıstupnej èasovej tabu¾ky FILLED, pridá funkcia doplnenı
        % èasovı úsek.:
        if i == 1
            FILLED = TABLE.NEW_Data{1};
        else
            FILLED = [FILLED; TABLE.NEW_Data{i}]; %#ok<AGROW>
        end
    end
end

% Táto èas kódu uloí všetky grafické priebehy signálov, ktoré boli
% doplnené v závislosti od stanovenej tolerancie dopåòania údajov.:
FIGURES_PATH = BASE_PATH + "\3. Analıza a vizualizácia údajov\" ...
    + "Chyby údajov\Automaticky upravené riadky\Obrázky\";
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

% Ukonèovacia èas funkcie:
% V tejto èasti funkcia vráti všetky vıstupné argumenty a vypíše dåku
% trvania vıpoètov tejto funkcie. Zároveò sa ukonèí a uloí záznam do
% textového súboru log_create_filled.txt.:
fprintf("Uplynutı èas: %s.\n", datestr(seconds(toc), "HH:MM:SS"));
fprintf("Vytváranie tabu¾ky bolo úspešne dokonèené.\n");
fprintf("===========================\n");
diary off;
beep;

% Vıstupné argumenty funkcie:
% TABLE =   Tabu¾ka záznamov chıbajúcich hodnôt, ktoré boli vypustené
%           ETL procesom z analızy údajov. Táto tabu¾ka je rozšírená o
%           ståpce vyradenıch hodnôt a ståpce doplnenıch hodnôt.
% FILLED =  Èasová tabu¾ka doplnenıch údajov po úprave ETL procesom.
varargout{1} = FILLED;
varargout{2} = TABLE;
end
