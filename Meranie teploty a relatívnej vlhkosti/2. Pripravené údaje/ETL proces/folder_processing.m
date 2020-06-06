function folder_processing(varargin)
%% Funkcia folder_processing.:
% Vstupn� argumenty funkcie.:
% FOLDER =	Cesta k prie�inku, v ktorom sa nach�dza aspo� jeden tak�
%           pod-prie�inok, kde s� ulo�en� �dajov� s�bory s *.edf pr�ponou.
close all;
FOLDER = varargin{1};
subfolders = dir(FOLDER);
subfolders = struct2table(subfolders);
subfolders = string(subfolders.name(subfolders.isdir));
subfolders = subfolders(subfolders ~= "." & subfolders ~= "..");
% Cyklus, ktor� spracuje postupne ka�d� pod-prie�inok. Najprv vytvor�
% do�asn� tabu�ku �dajov, n�sledne ulo�� grafy �asov�ch priebehov 
% teplomerov a priebehy prvej diferenci�lnej funkcie vektora �asov�ch 
% zna�iek. Vygeneruje a ulo�� �daje vo form�te *.csv. do prislu�n�ch
% pod-prie�inkov:
for i = 1:length(subfolders)
    path = FOLDER + "\" + subfolders{i};
    cd(path);
    disp(i + "/" + length(subfolders))
    [H, T] = create_table_thermometer(path);
    fig = plot_all_thermometers(T, "Value");
    if ~isempty(fig)
        saveas(fig, 'Value_T.fig');
        saveas(fig, 'Value_T.png');
    end
    fig = plot_all_thermometers(H, "Value");
    if ~isempty(fig)
        saveas(fig, 'Value_RH.fig');
        saveas(fig, 'Value_RH.png');
    end
    fig = plot_all_thermometers(T, "Diff_1");
    if ~isempty(fig)
        saveas(fig, 'Diff_T.fig');
        saveas(fig, 'Diff_T.png');
    end
    fig = plot_all_thermometers(H, "Diff_1");
    if ~isempty(fig)
        saveas(fig, 'Diff_RH.fig');
        saveas(fig, 'Diff_RH.png');
    end
end
end
function varargout = create_table_thermometer(varargin)
%% Funkcia create_table_thermometer.:
% Vstupn� argumenty.:
% PATH =	Cesta k prie�inku, v ktorom sa nach�dza aspo� jeden tak�
%           pod-prie�inok, kde s� ulo�en� �dajov� s�bory s *.edf pr�ponou.
PATH = varargin{1};
% Definuj� sa s�riov� ��sla teplomerov.:
ID = [
    "MyAmbience_7EF0";
    "MyAmbience_4F95";
    "MyAmbience_AD3D";
    "MyAmbience_DC93";
    "MyAmbience_D577";
    "MyAmbience_703C";
    "MyAmbience_AEE2";
    "MyAmbience_CC2C"
];
ID = table((0:length(ID) - 1)', ID,...
    'VariableNames', {'Key', 'Value'});
% Definuj� sa typy meranej veli�iny teplomerov.:
TYPE = [
    "HUMIDITY";
    "TEMPERATURE"
];
TYPE = table((0:length(TYPE) - 1)', TYPE,...
    'VariableNames', {'Key', 'Value'});
% Extrahuje cesty k s�borom a mno�stvo s�borov.:
DS = datastore(PATH,...
    'Type', "tabulartext",...
    'FileExtensions', ".edf",...
    'ReadVariableNames', false);
FILES = DS.Files;
L = size(FILES, 1);
fprintf("V prie�inku sa na�lo %d platn�ch s�borov.\n", L);
fprintf("Pr�prava tabu�ky...\n");
% Pre-alok�cia tabu�ky s n�zvom senzor.:
sensor = table;
sensor.ID = ID.Value;
sensor.HUMIDITY{size(ID, 1)} = timetable;
sensor.TEMPERATURE{size(ID, 1)} = timetable;
% Naplnenie tabu�ky senzor �dajmi z *.edf s�borov.:
for i = 0:size(ID, 1) - 1 
    for j = 0:size(TYPE, 1) - 1
        ID_V = ID.Value(ID.Key == i);
        TYPE_V = TYPE.Value(TYPE.Key == j);
        COND_1 = contains(FILES, ID_V);
        COND_2 = contains(FILES, TYPE_V);
        FILE = FILES(COND_1 & COND_2);
        NAME = (ID_V + "_" + TYPE_V);
        data = prepare_thermometer(FILE, NAME);
        sensor.(j + 2){i + 1, 1} = data;
    end
end
fprintf("Tabu�ka bola �spe�ne pripraven�.\n");
% V�stupn� argumenty.:
% varargout{1} =    Tabu�ka s �dajmi meranej vlhkosti vzduchu.
% varargout{2} =    Tabu�ka s �dajmi meranej teploty.
varargout{1} = table(sensor.ID, sensor.HUMIDITY,...
    'VariableNames', {'ID', 'Data'});
varargout{2} = table(sensor.ID, sensor.TEMPERATURE,...
    'VariableNames', {'ID', 'Data'});
end
function varargout = prepare_thermometer(varargin)
%% Funkcia prepare_thermometer.:
% Vstupn� argumenty funkcie.:
% FILE_PATH = Cesta k *.edf s�boru.
% FILE_NAME = N�zov v�stupn�ho *.csv s�boru.
FILE_PATH = varargin{1};
FILE_NAME = varargin{2};
try
    % Na��ta �daje.:
    tab = readtable(string(FILE_PATH),...
        'ReadVariableNames', false,...
        'FileType', "text");
    % ETL proces pr�pravy �dajov.:
    tab(1:2, :) = [];
    tab.Var1 = replace(tab.Var1, ",", ".");
    tab.Var1 = str2double(tab.Var1);
    tab.Var1 = floor(tab.Var1);
    date = datestr(tab.Var1 / 86400 + datenum(1970, 1, 1),...
        'dd-mmm-yyyy HH:MM:SS');
    tab.Var1 = datetime(date,...
        'InputFormat', 'dd-MMM-yyyy HH:mm:ss',...
        'Format', 'dd-MMM-yyyy HH:mm:ss');
    tab = timetable(tab.Var1, tab.Var2);
    tab = retime(tab, unique(tab.Time));
    tab.Properties.VariableNames = {'Value'};
    tab.Value = replace(tab.Value, ",", ".");
    tab.Value = str2double(tab.Value);
    tab = rmmissing(tab);
    tab.Diff_1 = [0; diff(tab.Time)];
    tab.Diff_2 = [-1; diff(tab.Diff_1)];
    tab.Good = tab.Diff_2 ~= 0;
    tab.CUMSUM = cumsum(tab.Good);
    % Ulo�� tabu�ku do *.csv s�boru pod vstupn�m n�zvom.:
    writetimetable(tab, FILE_NAME + ".csv");
    % V�stupn� argumenty.:
    % varargout{1} =	Fin�lna tabu�ka �dajov.:
    varargout{1} = tab;
catch
    % V�stupn� argumenty.:
    % varargout{1} =	Pr�zdna tabu�ka �dajov.
    tab = [];
    varargout{1} = tab;
end
end
function varargout = plot_all_thermometers(varargin)
%% Funkcia plot_all_thermometers.:
% Vstupn� argumenty.:
% DATA =	Typ meran�ch �dajov. (Napr�klad T pre teplotu, H pre vlhkos�)
% COL =     St�pec �dajov. (Napr�klad "Diff_1" pre prv� diferenciu �asov�ho
%           vektora)
DATA = varargin{1}.Data;
names = varargin{1}.ID;
COL = varargin{2};
L = length(DATA);
% Paleta farieb definovan� pre ka�d� krivku (krivka = s�riov� ��slo 
% teplomera).:
colors = [
    0.000, 0.447, 0.741;
    0.850, 0.325, 0.098;
    0.929, 0.694, 0.125;
    0.494, 0.184, 0.556;
    0.466, 0.674, 0.188;
    0.301, 0.745, 0.933;
    0.635, 0.078, 0.184;
    0.250, 0.250, 0.250
];
% Vytvor� pr�zdne pl�tno ako premenn�.:
varargout{1} = figure('Visible', 'off');
% Vytvor� vektor dostupn�ch kriviek.:
index = [];
for i = 1:L
    if ~isempty(DATA{i})
        index = [index, i]; %#ok<AGROW>
    end
end
% Vykresl� dostupn� krivky.:
if ~isempty(index)
    first = index(1);
    plot(DATA{first}.Time, DATA{first}{:, COL});
    varargout{1}.Color = colors(first, :);
    if length(index) > 1
        hold('on');
        for i = index(2:end)
            plot(DATA{i}.Time, DATA{i}{:, COL}, 'Color', colors(i, :));
        end
    end
    labels = names(index);
    labels = replace(labels, "MyAmbience_", "");
    title(COL);
    legend(labels, 'Location', 'best');
    hold('off');
    % V�stupn� argumenty.:
    % varargout{1} =    Grafick� objekt s grafom.
else
    % V�stupn� argumenty.:
    % varargout{1} =    Pr�zdn� grafick� objekt.
    varargout{1} = [];
end
end