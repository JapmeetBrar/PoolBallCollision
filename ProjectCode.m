myVideo = VideoWriter("video_output",'Motion JPEG AVI'); %Settup video file, set framerate, quality
myVideo.FrameRate = 60; 
myVideo.Quality = 95;
open(myVideo);

a = readtable('T.xlsx'); bp = table2array(a(:,2:3)); %Read positions from excel file called 'T' and put in array
balls = [Balls(false, bp(1,:)), ...
         Balls(false, bp(2,:)), ...
         Balls(false, bp(3,:)), ...
         Balls(false, bp(4,:)), ...
         Balls(false, bp(5,:)), ...  %Create array containing Objects of type Class "Balls" each inputting the positions
         Balls(false, bp(6,:)), ...  %gotten from the excel file
         Balls(false, bp(7,:)), ...
         Balls(false, bp(8,:)), ...
         Balls(false, bp(9,:)), ...
         Balls(false, bp(10,:)), ...
         Balls(true, bp(11,:)), ...
         ];
timePeriod = .01; %Calculating everything every hundredth of a millisecond

figure;
cd=axes;
cd.Color = [58 181 3]/255;
set(gcf, 'Position',  [100, 100, 800, 400]);   %Draw pool table and set all parameters
box on;
xlim([0, 88]);
ylim([0 44]);  

for i = 1:length(balls) % Draw all the pool balls onto table at starting positions
    hold on
    scatter(bp(i,1),bp(i,2),550,'filled','MarkerEdgeColor','k','LineWidth',0.5)
    if i == 8
        text(bp(i,1),bp(i,2),num2str(i),'HorizontalAlignment','center','Color',[1 1 1]);
    elseif i == 11
        text(bp(i,1),bp(i,2),'C','HorizontalAlignment','center');
    else
        text(bp(i,1),bp(i,2),num2str(i),'HorizontalAlignment','center','Color',[1 1 1]);
    end
    colororder([0.9290 0.6940 0.1250; 0 0.4470 0.7410;1 0 0;0.4940 0.1840 0.5560;0.8500 0.3250 0.0980;0.4660 0.6740 0.1880;0.6350 0.0780 0.1840;0 0 0;0.3010 0.7450 0.9330;0.5 0.5 0.5;1 1 1])
end

minDist = 100; %Set minimum distance, bigger than max distance on table

%Loop through each ball to find closes ball
for i=1:(length(balls)-1) 
    if (norm(balls(11).position-balls(i).position)) < minDist
        minDist = norm(balls(11).position-balls(i).position);
        %Calculate angle using arctan of distance
        minBallAngle = atan2(balls(i).position(2)-balls(11).position(2), balls(i).position(1)-balls(11).position(1));
    end
end
%Four different scenarios for part 2

%balls(11).vel = [-4,0];

%balls(11).vel = [-2.5*cos(deg2rad(15)),2.5*sin(deg2rad(15))];

%balls(11).vel = [-1.5*cos(deg2rad(30)),1.5*sin(deg2rad(30))];

balls(11).vel = [1.5*cos(minBallAngle),1.5*sin(minBallAngle)];

moving = true; %Set condition for while loop
while moving==true
    for i = 1:length(balls) %Loops through each ball to see if all are still
        if norm(balls(i).vel) ~= 0
            moving = true;
            break
        else
            moving = false; 
        end 
    end

    for i = 1:length(balls) %Calls the ballMove function on each ball
        balls(i).ballMove(timePeriod);
    end

    %Calls the wallCollision function on each ball to check if any of them
    %are currently colliding with a wall
    for i = 1:length(balls) 
        balls(i).wallCollision();
    end

    %Checks each ball to see if it is colliding with any of the following
    %balls
    for i = 1:length(balls) 
        if i < length(balls)
            for j = i+1:length(balls)
                balls(i).ballCollision(balls(j));
            end
        
        end
    end              
    
    %Same as code from above, redraws the figure each loop iteration with
    %updated ball positions
    frame = getframe(gcf);
    writeVideo(myVideo, frame);
    clf;
    figure('visible', 'off');
    cd=axes;
    cd.Color = [58 181 3]/255;
    set(gcf, 'Position',  [100, 100, 800, 400]);
    box on;
    xlim([0, 88]);
    ylim([0 44]);
    for i = 1:length(balls)
        hold on
        scatter(balls(i).position(1),balls(i).position(2),550,'filled','MarkerEdgeColor','k','LineWidth',0.5)
        if i == 8
            text(balls(i).position(1),balls(i).position(2),num2str(i),'HorizontalAlignment','center','Color',[1 1 1]);
        elseif i == 11
            text(balls(i).position(1),balls(i).position(2),'C','HorizontalAlignment','center');
        else
            text(balls(i).position(1),balls(i).position(2),num2str(i),'HorizontalAlignment','center','Color',[1 1 1]);
        end
        colororder([0.9290 0.6940 0.1250; 0 0.4470 0.7410;1 0 0;0.4940 0.1840 0.5560;0.8500 0.3250 0.0980;0.4660 0.6740 0.1880;0.6350 0.0780 0.1840;0 0 0;0.3010 0.7450 0.9330;0.5 0.5 0.5;1 1 1])
    end
    
end
close(myVideo); %closes video file writing

for i = 1:length(balls) %%Print final x and y positions of each ball
    if i == 11
        disp("Cue Ball: " + balls(i).position);
    else
        disp("Ball " + i + ": "+ balls(i).position);
    end
end