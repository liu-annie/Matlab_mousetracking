%mouse_names = {'16220', '16221', '16226','16227', '16228', '16229', '16231', '16232'};
mouse_names = {'16220', '16221', '16227', '16231', '16229', '16228', '16226'};
%mouse_names = {'16228'};
%mouse_names = {'16229', '16228'};
folders = {'130912', '130913', '130916', '130917', '130918', ...
           '130919', '130920', '130923', '130924', '130925', ...
           '130926', '130927', '130930', '131001', '131002', ...
           '131003', '131004', '131007', '131008', '131009', ...
           '131010', '131011', '131014', '131015', '131016', ...
           '131017', '131018', '131021', '131022', '131023', ...
           '131024', '131025', '131028', '131029', '131030', ...
           '131101', '131104', '131105', '131106', '131108', ...
           '131111', '131112', '131113', '131115', '131119', ...
           '131120', '131121', '131125', '131126', '131203', ... %should add 131122!
           '131204', '131206', '131209', '131210', '131211'};
           

train_trials = {1:72,       1:76,       1:73,   1:74,       1:77,       1:79,   1:73}; 
ctl_trials =   {42:72,      46:76,      43:73,  44:74,      44:77,       49:79,  30:73}; 
ctl2_trials =  {104:139,    108:142,    [],     105:140,    115:145,    [],     106:135}; 
occr_trials =  {140:173,    77:107,     74:111, 75:104,     78:114,     [],     []}; 
occl_trials =  {73:103,     143:163,    [],     141:160,    146:186,    80:118, []};

% These are the indices that correspond to the folders of the days under each condition
train_dirs = {1:15,  1:15,  1:15,    1:15,  1:15,  1:15,  1:15}; % Initial training
ctl_dirs = {16:23,  16:23,  16:22,  16:23,  16:22, 16:22, 16:23}; % Control behavior
ctl2_dirs = {35:44, 35:44,  35:44,  35:44,  35:44,    [],    35:44}; % Control behavior period 2

occr_dirs = {45:55, 24:34,  24:34,  24:34,  23:34,    [],     [] }; % Occlude R nares
occl_dirs = {24:34, 45:55,  [],     45:55,  45:55, 23:34,     [] }; % Occlude L nares

occ1_dirs = {24:34, 24:34,  24:34,  24:34,  23:34, 23:34,     [] }; % First occlusion
occ2_dirs = {45:55, 45:55,  [],     45:55,  45:55,    [],     [] }; % Second occlusion

nMice = length(mouse_names);
