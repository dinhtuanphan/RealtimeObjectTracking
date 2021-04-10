% This program allows you to track the movement of object inside microchannel
% and calculate speed in real-time
% Built by Dinh-Tuan Phan, Ph.D.

clf
clc
clear all

% specify input video
file = '20200810_145743.mp4';
xtimelapse = 32;                        % recording speed
flowraterange = [0 2];                  % flow rate range for the right y axis
skipframe = 1;                          % skip n frames from processing

% set input parameters
bwthreshold = 0.10;                      % threshold to convert color to BW
samplingwindow = 30;                   % sampling window (second)
n = 30;                                 % 1-D median filtering
calibratedslope = 0.9;                  % flowrate slope from calibration equation

framerate = 30;                         % frame rate of phone movie (fps)
totalvolume = 20;                       % total volume dispensed (uL)
totalpixel = 48755;                     % total pixel detected (uL)
profile = [0 10 18 27; 0.1 1 1 0.1];    % set programed profile

% derived parameters
timestep = skipframe*xtimelapse/(framerate*60);   % time inteval between captured images
pixelcal = totalvolume/totalpixel;                % how much volume/pixel

% read file
[filepath,name,ext] = fileparts(file);
obj = VideoReader(file);
frames = obj.NumFrames;

% define dependent outputs
volume = [];
time = [];
flowrate = [];

% set background image is the 1st frame of the movie
ROI = read(obj,1);
[ROI, rect] = imcrop(ROI);

% background = imread('testimage0.jpg');
% background = imcrop(background,[500 225 700 700]);
fid = fopen(strcat(name,'.txt'),'w');

f1 = figure('Name','Real-time sweat rate','NumberTitle','off','units',...
            'normalized','outerposition',[0 0 1 1]);
recordedframe = f1;

for i = 1:frames

    if  i == 1
    background = read(obj,i);
    else
    background = read(obj,i-1);
    end
    
    background = imcrop(background,rect);

    frame = read(obj,i);
    image = imcrop(frame,rect);

    subplot (1,3,1), imshow(image), title('Sensor in operation');  
    

    C = imsubtract(background,image);
    D = im2bw(C,bwthreshold);
    
    if all(D(:) == 0)
        volume(i) = 0;  
    else    
        D = imfill(D,'holes');
        L = bwconncomp(D); 
        regions = regionprops(L,'Area');
        
        
        
        
        
        
      volume(i) = max(arrayfun(@(s) max(s.Area), regions)*pixelcal);
      idx = find(max(arrayfun(@(s) max(s.Area), regions)));
         D = ismember(labelmatrix(L),idx);


% D = edge(D,'Canny');
% lengthOfEdges = sum(D(:));
% [labeledImage numberOfEdges] = bwlabel(D);
% averageEdgeLength = lengthOfEdges  / numberOfEdges;
% volume(i) = averageEdgeLength*pixelcal;

    end   
    
    % predict volume if image is bad
    
%     if 2 < i <= samplingwindow 
%         previousslope = calibratedslope;
%     end
    
%     if i > 2
%         if volume(i) < previousdata
%             volume(i) = previousdata;
%         end
%     end
%     
%     previousdata = volume(i);
   
    
    
    subplot (1,3,2), imshow(D), title('Sweat detection');

    time(i) = i*timestep;
    
    subplot (1,3,3);
    colororder({'k','r'})
    yyaxis left;
    plot(time(i), volume(i),'--go','Color','k');
    title('Real-time sweat rate');
    axis square
%     set(gca,'XLim',[0 30],'YLim',[0 30]);
%     set(gca,'XTick',(0:5:30));
%     set(gca,'YTick',(0:5:30));
    grid on;
    xlabel('Time (min)');
    ylabel('Volume (µL)');
    hold on;
    drawnow
 
    % calculate flow rate in real time
%     
    if i > samplingwindow
%         x = time(i-samplingwindow:i);
%         y = medfilt1(volume(i-samplingwindow:i),n);
        linearCoefficients = mean(medfilt1(volume(i-samplingwindow:i),n));
        flowrate(i) = linearCoefficients(1)/calibratedslope*25;
 
        yyaxis right;
        plot(time(i),flowrate(i),'--go','Color','r');
        set(gca,'YLim',flowraterange);
        set(gca,'YTick',(0:0.5:1.5));
        ylabel('Flow rate (µL min^-^1)','Color',[1 0 0]);
        hold on;
        drawnow
     else
         flowrate(i) = 0;
   end
    
    caption = sprintf('Time = %.1f mins \r\n Flow rate = %.1f µL min^-^1 \r\n Volume = %.1f µL \r\n', ...
        time(i), flowrate(i), volume(i));
    sgtitle(caption, 'FontSize',20,'Color','k');
    %sgtitle(strcat(name,'.mp4'),'Interpreter','none');
    
    
    % write data to text file
    fprintf(fid,'%4f,%4f,%4f\r\n',time(i),volume(i),flowrate(i));
    
    % store recorded frames in movieVector
    movieVector(i) = getframe(recordedframe);
    
end

fclose(fid);

% plot final data: time versus volume and flowrate

f2 = figure('Name','Real-time sweat rate','NumberTitle','off');
colororder({'k','r'});

yyaxis left;
plot(time, volume,'--go','Color','k');
grid on;
xlabel('Time (min)');
ylabel('Volume (µL)');
hold on;

yyaxis right;
plot(time,flowrate,'--go','Color','r');
ylabel('Flow rate (µL min^-^1)','Color',[1 0 0]);

% write out the movie to file

movieVector( all( cell2mat( arrayfun( @(x) structfun( @isempty, x ),...
             movieVector, 'UniformOutput', false ) ), 1 ) ) = [];
myWriter = VideoWriter(strcat(name,'_output'));
myWriter.FrameRate = 30;
open(myWriter);
writeVideo(myWriter, movieVector);
close(myWriter);


