% Zatvorí všetky otvorené okna programu MATLAB, vymae všetky premenné a
% obsah príkazového riadku.:
close all; clear; clc
% Definuje plné cesty k prieèinkom, s ktorımi funkcia potrebuje pracova.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
PREPARED_PATH = BASE_PATH + "\2. Pripravené údaje\";
% Volanie pomocnej funkcie join_data pre zlúèenie jednotlivıch údajovıch
% súborov.:
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
% Uloí všetky tabu¾ky do prieèinku pripravenıch údajov do súboru
% voltage_data.mat.:
save(PREPARED_PATH + 'voltage_data.mat', '-v7.3');
%
% Zrejme chybné merania... Je potrebne ich samostatne prešetri!
% o01 = join_data("o01a", "o01b");
% o02 = join_data("o02a", "o02b", "o02c", "o02d");
% zz = join_data("zz0", "zz1", "zz2");
%
% Pomocná funkcia na zlúèenie viacerıch tabuliek v mieste ich prieseèníka.:
function varargout = join_data(varargin)
% Definuje plné cesty k prieèinkom, s ktorımi funkcia potrebuje pracova.:
SCRIPT_PATH = split(string(mfilename('fullpath')), "\");
SCRIPT_PATH = join(SCRIPT_PATH(1:end - 1), "\");
BASE_PATH = split(SCRIPT_PATH, "\");
BASE_PATH = join(BASE_PATH(1:end - 2), "\");
DATA_PATH = BASE_PATH + "\1. Pôvodné údaje\Meranie U na skrate\"; %#ok<NASGU>
PREPARED_PATH = BASE_PATH + "\2. Pripravené údaje\";
% Cyklus, v ktorom prebieha spájanie jednotlivıch vstupnıch tabuliek. 
% Funkcia intersect vyh¾adá prieseèník medzi údajmi a následne ich zlúèi do
% jednej tabu¾ky s názvom t1.:
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
% Uloí obrázok priebehu vo formáte *.png do zloky pripravenıch údajov.:
f = figure('Visible', 'off');
plot(t1.Var2 * 1000000);
ylabel("Odpor vodièa (\mu\Omega)");
saveas(f, PREPARED_PATH + t1_name.extractBetween(1, 1) + '.png');
% Funkcia vráti finálnu tabu¾ku ako vıstupnı parameter.:
varargout{1} = t1;
end
