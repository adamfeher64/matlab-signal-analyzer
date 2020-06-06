% Zatvor� v�etky otvoren� okna programu MATLAB, vyma�e v�etky premenn� a
% obsah pr�kazov�ho riadku.:
close all; clear; clc
% Definuje pln� cesty k prie�inkom, s ktor�mi funkcia potrebuje pracova�.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
PREPARED_PATH = BASE_PATH + "\2. Pripraven� �daje\";
% Volanie pomocnej funkcie join_data pre zl��enie jednotliv�ch �dajov�ch
% s�borov.:
a = join_data("a");
d = join_data("d");
e = join_data("e");
ff = join_data("ff0", "ff1", "ff2");
gg = join_data("gg0", "gg1", "gg2");
hh = join_data("hh");
ii = join_data("ii");
jj = join_data("jj");
kk = join_data("kk", "kk0new");
ll = join_data("ll0", "ll1new", "ll2");
mmm = join_data("mmm0", "mmm1", "mmm2");
nn = join_data("nn0", "nn1", "nn2");
oo = join_data("oo0", "oo1", "oo2");
pp = join_data("pp0");
qq = join_data("qq0", "qq1");
rr = join_data("rr0");
ss = join_data("ss0", "ss1", "ss2");
tt = join_data("tt0", "tt1", "tt2");
uu = join_data("uu0", "uu1", "uu2");
vv = join_data("vv0", "vv1asi", "vv2");
ww = join_data("ww0", "ww1asi", "ww2");
xx = join_data("xx0bezzac", "xx1", "xx2", "xx3");
yy = join_data("yy0", "yy1", "yy2");
% Ulo�� v�etky tabu�ky do prie�inku pripraven�ch �dajov do s�boru
% voltage_data.mat.:
save(PREPARED_PATH + 'voltage_data.mat', '-v7.3');
%
% Zrejme chybn� merania... Je potrebne ich samostatne pre�etri�!
% o01 = join_data("o01a", "o01b");
% o02 = join_data("o02a", "o02b", "o02c", "o02d");
% zz = join_data("zz0", "zz1", "zz2");
%
% Pomocn� funkcia na zl��enie viacer�ch tabuliek v mieste ich priese�n�ka.:
function varargout = join_data(varargin)
% Definuje pln� cesty k prie�inkom, s ktor�mi funkcia potrebuje pracova�.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
DATA_PATH = BASE_PATH + "\1. P�vodn� �daje\Meranie U na skrate\"; %#ok<NASGU>
PREPARED_PATH = BASE_PATH + "\2. Pripraven� �daje\";
% Cyklus, v ktorom prebieha sp�janie jednotliv�ch vstupn�ch tabuliek. 
% Funkcia intersect vyh�ad� priese�n�k medzi �dajmi a n�sledne ich zl��i do
% jednej tabu�ky s n�zvom t1.:
for i = 1:nargin
    eval("t" + i + "_name = varargin{" + i + "};");
    eval("t" + i + " = readtable(DATA_PATH + t" + i + "_name + '.csv');");
    eval("t" + i + "(:, 'Var1') = [];");
    if i >= 2
        eval("is = intersect(t1, t" + i + ", 'stable');");
        idx = ismember(t1, is);
        t1(idx, :) = []; %#ok<AGROW>
        eval("t1 = [t1; t" + i + "];");
    end
end
% Ulo�� obr�zok priebehu vo form�te *.png do zlo�ky pripraven�ch �dajov.:
f = figure('Visible', 'off');
plot(t1.Var2 * 1000000);
ylabel("Odpor vodi�a (\mu\Omega)");
saveas(f, PREPARED_PATH + t1_name.extractBetween(1, 1) + '.png');
% Funkcia vr�ti fin�lnu tabu�ku ako v�stupn� parameter.:
varargout{1} = t1;
end
