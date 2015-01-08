% fixFallBodyCOMs

fallCohortList;
folders = {'130912', '130913', '130916', '130917', '130918', ...
           '130919', '130920', '130923', '130924', '130925', ...
           '130926', '130927', '130930', '131001', '131002', ...
           '131003', '131004', '131007', '131008', '131009', ...
           '131010', '131011', '131014', '131015', '131016', ...
           '131017', '131018', '131021', '131022', '131023', ...
           '131024', '131025', '131028', '131029', '131030', ...
           '131101', '131104', '131105', '131106', '131108', ...
           '131111', '131112', '131113', '131115', '131119', ...
           '131120', '131121', '131122', '131125', '131126', '131203', ... %should add 131122!
           '131204', '131206', '131209', '131210', '131211'};


for ii = 48:length(folders)
    vids = processVideoFolder(folders{ii},@MouseTrackerKF, 0);
    for jj = 1:length(vids)
        vids(jj).bodyCOM = vids(jj).computeBodyPos(1:vids(jj).nFrames, 0); 
        vids(jj).save;
    end
    
end




