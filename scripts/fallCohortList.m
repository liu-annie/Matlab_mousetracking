mouse_names = {'16220', '16221', '16226','16227', '16228', '16229', '16231', '16232'};
mouse_names = {'16220', '16221', '16227', '16231', '19229', '19228'};
folders = {'130912', '130913', '130916', '130917', '130918', '130919', '130920', '130923', '130924', '130925', '130926', ...
           '130927', '130930', '131001', '131002', '131003', '131004', '131007', '131008', '131009', '131010', '131011', '131014', ...
           '131015', '131016', '131017', '131018', '131021', '131022', '131023', '131024', '131025', '131028', '131029', '131030', ...
           '131101', '131104', '131105', '131106', '131108', '131111', '131112', '131113', '131115', '131119', '131120', '131121', ...
           '131125', '131126', '131203', '131204', '131206', '131209', '131210', '131211'};
train_trials = {1:72, 1:76, 1:73, 1:74, 1:70, 1:70}; %LAST TWO ARE GUESS
ctl_trials = {42:72, 46:76, 43:73, 44:74, 40:70, 40:70}; %last TWO ARE GUESSES
ctl2_trials = {104:139, 108:142, 44:74, 105:140, 40:70, 40:70}; %last TWO ARE GUESSES
occr_trials = {140:173, 77:107, 74:111, 75:104, [], []}; %each cell is a mouse
occl_trials = {73:103, 143:163, [], 141:160, [], []};
nMice = length(mouse_names);