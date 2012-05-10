classdef MouseTracker < handle
    properties
        videoFN = []; % filename of the video
        framesPerSeg = 400 %the # of frames read at one time
        avgSubsample = 10 %sample every X frames to make the average
        width % movie dimensions
        height
        frameRate 
        totalDuration %total length of the movie
        nFrames 
        frameRange % frame numbers loaded in reference to original file
        avgFrame % the time averaged frame
        nMice = 1 % number of mice tracked
        COM % center of mass for each mouse
        orient % orientation of each mouse
        vel % velocity
        direction %movement direction
        times % frame times
        areas % mouse regions
    end
    properties (GetAccess = private)
        exitMovie = 0
    end
    
    methods
        function this = MouseTracker(varargin)
            % MouseTracker(varargin) - This is an object that loads a video and then detects a mouse in that video
            % letting you get the mouse position in various parts of it.  It does this on an request basis, then 
            % saves the tracking results to minimize memory load.  
            % 
            % Args: 1 - A filename or folder of the movie to load.  If there isn't one given, then a dialog is
            % presented.
            % 2 - frame range - a vector of frame numbers to consider as the whole movie, example 1:100
            % 3 - time range - a beginning and end time to consider as the whole movie, in sec, example [60 120].
            
            % This is all to just make sure that the file is opened correctly, and that it will take a filename,
            % directory or nothing.
            movie_folder = ''; filename = '';
            if (nargin > 0)
                filename = varargin{1};
                if exist(filename, 'dir') % a folder was specified
                    movie_folder = filename;
                    filename = '';
                elseif exist(filename, 'file') % a valid filename is specified
                    this.videoFN = filename;
                end
            end
            if isempty(filename) || ~exist(filename) %a non-complete path was specified, and needs to be chosen
                [filename, movie_folder] = uigetfile([movie_folder '*.*']);
                if filename == 0 % the user has canceled the file selection
                    return;
                end
                this.videoFN = [movie_folder filename];
            else
                this.videoFN = filename;
            end
            % Read just a couple of frames to get an idea of video speeds, etc.
            vid_struct = mmread(this.videoFN, 1); 
            this.frameRate = vid_struct.rate;
            this.width = vid_struct.width;
            this.height = vid_struct.height;
            
            % figure out the range of frames to be considered
            time_range = []; this.frameRange = [];
            if (nargin > 2)
                time_range = varargin{3};
                t_offset = vid_struct.times(1);
                fr = round((time_range-t_offset)*this.frameRate + 1);
                this.frameRange = fr(1):fr(2);
            elseif nargin == 2
                this.frameRange = varargin{2};
            end
            if isempty(this.frameRange) % then specify the whole video's range
                this.frameRange = 1:(abs(vid_struct.nrFramesTotal)-1);
            end
            % read in enough frames to create the average frame
            avgRange = this.frameRange(1):this.avgSubsample:this.frameRange(end);
            disp('MouseTracker: reading movie to make average frame');
            vid_struct = mmread(this.videoFN, avgRange);     
            vid_struct = this.convertToGray(vid_struct);
            this.avgFrame = this.averageFrame(vid_struct, 1:length(vid_struct.frames));
            
            % Populate the fields with empty data
            this.nFrames = length(this.frameRange);
            this.times = ((1:this.nFrames)-1)/this.frameRate; % time vector starts at 0
            %this.times = ((this.frameRange(1):this.frameRange(2))-1)/this.frameRate + t_offset;
            this.COM = NaN*zeros(this.nFrames, 2, this.nMice);
            this.orient = NaN*zeros(this.nFrames, this.nMice);
            this.vel = NaN*zeros(this.nFrames, this.nMice);
            
        end %function MouseTracker
    
        function [wantedCOM, nose] = mousePosition(this, time_range)
        % function [wantedCOM, nose] = mousePosition(this, time_range)    
         % Returns the position of the mouse center of mass (body) and 
         % eventually the nose for the specified time range
            wantedFrames = this.timesToFrames(time_range); 
            wantedCOM = this.COM(wantedFrames,:,:);
            if isnan(wantedCOM)
                nanFrames = wantedFrames(isnan(wantedCOM(:,1,1)));
                this = this.findMouse(nanFrames);
            end 
            % get what they wanted
            wantedCOM = this.COM(wantedFrames,:,:);
            nose = [];
        end
        
        function vel = mouseVelocity(this, time_range)
            % function vel = mouseVelocity(this, time_range)
            % Returns the velocity of the mouse body for the specified frames
            frames = this.timesToFrames(time_range);
            vel = this.vel(frames);
            if isnan(vel)
                this.mousePosition(time_range);
            end
            [this, vel] = this.computeVelocity(frames);
        end
        
        function plotVelocity(this)
            % function plotVelocity(this)
            figure;
            cm = colormap(jet(this.nFrames));
            sorted_vel = sort(this.vel); %sorted vector of speeds for colormapping
            imshow(this.avgFrame); hold on;
            xlim([0 this.width]);
            ylim([0 this.height]);
            % unfortunately, I haven't been able to figure out an easier way to do colormapping of points plotted over
            % a B&W image, without the points and the image sharing the same colormap.  So, here I'm just plotting every
            % point separately, with a color indicative of the velocity of the animal.
            for ii=1:this.nFrames
                ci = find(sorted_vel == this.vel(ii), 1, 'first');
                if ~isnan(ci)
                    line('Xdata', this.COM(ii,1), 'Ydata', this.COM(ii,2), 'Marker', '.', 'MarkerSize', 10, 'Color', cm(ci,:));
                end
            end 
        end
        
        function writeMovie(this, filename, useBinMovie)
            % function writeMovie(this, filename)
            % Writes a movie of the tracked mouse to disk at the given location
            vidWriter = VideoWriter(filename);
            open(vidWriter);
            figure;
            for ii=1:this.nFrames
                this.showFrame(ii, useBinMovie);
                currFrame = getframe; % now to the business of writing the movie
                writeVideo(vidWriter,currFrame);
                hold off;
            end
            close(vidWriter);
        end
       
        function showMovie(this, useBinMovie, frameRange)
            % function showMovie(this, useBinMovie, frameRange)
            fh = figure;
            set(fh, 'WindowKeyPressFcn', @this.exitMovieLoop);
            if exist('frameRange','var') && ~isempty(frameRange)
                lr = frameRange;
            else
                lr = 1:this.nFrames;
            end
            for ii=lr
                if this.exitMovie
                    break
                end
                this.showFrame(ii, useBinMovie);
                hold off;
                pause(1/this.frameRate);
            end
            this.exitMovie = 0;
            set(fh, 'WindowKeyPressFcn', '');
        end
        
        function exitMovieLoop(this, src, event)
            % Function to set a flag internally to exit a movie that is being displayed.
            % It is not used for any other purpose
            if strcmp(event.Key, 'q') || strcmp(event.Key, 'escape')
                this.exitMovie = 1;
            end
        end
    end
    
    methods (Access = private)
        function showFrame(this, ii, useBinMovie)
            if useBinMovie
                on = this.areas(ii).PixelIdxList;
                bf = zeros(this.height, this.width);
                bf(on) = 255;
                imshow(bf); hold on;
                
                % let's try dilating things
                z = zeros(this.height, this.width, 3);
                z(:,:,1) = bf; z(:,:,3) = bf;
                SE = strel('rectangle', [4,3]);
                im2 = imdilate(bf, SE);
                im2 = repmat(im2, [1, 1, 3]);
                im2 = im2 - z;
                imshow(im2);
            else
                f = mmread(this.videoFN, this.frameRange(ii));
                imshow(f.frames.cdata); hold on;
            end
            
            % These are the real operations
            plot(this.COM(ii,1), this.COM(ii,2), 'r+', 'MarkerSize', 12, 'LineWidth',1);
            ellipse(this.areas(ii).MajorAxisLength, this.areas(ii).MinorAxisLength, -this.orient(ii), this.COM(ii,1),this.COM(ii,2),'r');
            line(this.areas(ii).Extrema(:,1), this.areas(ii).Extrema(:,2), 'Marker', '.', 'Color', 'c');
        end
        
        function movieArray = readMovieSection(this, frames, binary)
            vid_struct = mmread(this.videoFN, frames+this.frameRange(1)-1); %this final call is where we compensate for an offset 
            vid_struct = this.convertToGray(vid_struct);
            if binary
                movieArray = this.convertMovieToBinaryArray(vid_struct, 1:length(frames), this.avgFrame);
            else
                movieArray = this.convertMovieToGrayArray(vid_struct, 1:length(frames));
            end
        end
        
        function this = findMouse(this, frames)
            % function this = findMouse(this, frames)
            
            % The list of properties detected in the binary image of each frame
            props = {'BoundingBox', 'Centroid', 'Perimeter', 'Area', 'Orientation', 'MajorAxisLength', ...
                     'MinorAxisLength', 'PixelList', 'PixelIdxList', 'Extrema'};
            nSegs = ceil(length(frames)/this.framesPerSeg);
            for jj = 1:nSegs %divide the computation up into segments so that there is never too much in memory at once
                first = (jj-1)*this.framesPerSeg + 1; %first frame of segment
                if (jj == nSegs) % the last frame
                    last = frames(end);
                else
                    last = (jj)*this.framesPerSeg;
                end
                segFrames = frames(first:last);
                
                disp(['Finding mouse in segment ' num2str(jj)]);
                frameArray = this.readMovieSection(segFrames,1);
                if isempty(this.areas) %initialize areas field if it hasn't been
                    areas = regionprops(frameArray(:,:,1), props); %built-in that gives stats on binary images
                    this.areas = repmat(areas, this.nFrames, this.nMice); % make a struct arraay length of nFrames
                end
                for ii = 1:length(segFrames)  %have to work 1 frame at a time, unfortunately
                    temp_reg = regionprops(frameArray(:,:,ii), props);
                    if ~isempty(temp_reg)
                        this.areas(segFrames(ii)) = regionprops(frameArray(:,:,ii), props);
                    else %this is a kluge - unclear what the best thing to do is if you don't detect a blob
                        subI = max(1, ii-1);
                        this.areas(segFrames(ii)) = this.areas(frames(subI)); %this will error on ii=1
                    end
                end
            end
            positions = reshape([this.areas(frames).Centroid], 2,[])';
            this.COM(frames, :) = positions;
            this.orient(frames, :) = [this.areas(frames).Orientation]./ 180 * pi;
            this = this.computeVelocity(frames);
            
        end
        
        function [this, vel] = computeVelocity(this, frames)
            % function vel = getVelocity(this, frames)
            % Computes the velocity as the frame by frame difference in position
            
            %in order to get a velocity for the first frame (0,0) position is assumed at frame 0 
            diff_com = diff(this.COM, 1, 1); %differences in COM for each x,y position
            dists = [sqrt(sum(this.COM(1,:).^2, 2)); sqrt(sum(diff_com.^2, 2))]; %euclidian distances of each frame transition
            this.vel = dists * this.frameRate; % Velocities in px/sec
            vel = this.vel(frames);
        end
        
        function frames = timesToFrames(this, time_range)
            if isempty(time_range) %all times
                time_range = [this.times(1) this.times(end)];
            end
            frames = find(this.times >= time_range(1) & this.times <= time_range(2));
        end
    end
    
    methods (Static, Access = private)
        function  mov_struct = convertToGray(mov_struct)
            % function that converts the movie, frame by frame into grayscale - if it's not already
            for ii=1:length(mov_struct)
                mov_struct.frames(ii).cdata = rgb2gray(mov_struct.frames(ii).cdata);
            end
        end
        
        function avg_frame = averageFrame(mov_struct, frame_range) 
            % function to that takes the specific movie structure and computes the average frame of the specified frames
            mov = mov_struct.frames(frame_range);
            new_mov = zeros([size(mov(1).cdata,1) size(mov(1).cdata,2) length(mov)], 'uint8');
            for ii=1:length(mov)
                new_mov(:,:,ii) = squeeze(mov(ii).cdata(:,:,1));
            end
            avg_frame = uint8(round(mean(new_mov,3)));
        end
        
        function [bin_mov, avg_frame] = convertMovieToBinaryArray(mov_struct, frame_range, subFrame)
            % returns a binary thresholded movie using the frames specified in the input. Also there is
            % an optional argument 'subFrame' specifying a frame to subtract from each frame in order to
            % improve the thresholding of certain objects.

            mov = mov_struct.frames(frame_range);
            new_mov = zeros([size(mov(1).cdata,1) size(mov(1).cdata,2) length(mov)], 'uint8');
            %new_mov = [mov.cdata];
            for ii=1:length(mov)
                new_mov(:,:,ii) = squeeze(mov(ii).cdata(:,:,1));
            end
            % make a movie from the average frame to subtract
            if ~isempty(subFrame)
                avg_frame = subFrame;
            else
                avg_frame = uint8(round(mean(new_mov,3)));
            end
            avg_mov = repmat(avg_frame, [1 1 length(mov)]);
            new_mov = imabsdiff(new_mov, avg_mov); %this should give a nice moving blob.
            
            bin_mov = zeros(size(new_mov), 'uint8');
            nFrames = size(bin_mov,3);
            thresh = graythresh(new_mov);
            for ii = 1:nFrames
                %thresh = graythresh(new_mov(:,:,ii));
                bin_mov(:,:,ii) = im2bw(new_mov(:,:,ii), thresh);
            end
        end
    end % methods - private
end %classdef