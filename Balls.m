%Class used to handle all interactions with balls
classdef Balls < handle    
    properties %all properties of the balls
        cueBall; %Boolean variable checking if ball is cueball
        startPos;
        position;
        vel;
        mass;
        ballsInteracting = Balls.empty; %empty object for checking current ball interactions
    end
    
    methods
        function obj = Balls(cueBall, position)
            %Constructor Method
            obj.cueBall = cueBall;
            if cueBall ~= true %Sets mass depending on type of ball
                obj.mass = Constants.mNum;
            else
                obj.mass = Constants.mCue;
            end
            obj.startPos = position; 
            obj.position = position;
            obj.vel = [0,0]; %Array containing x/y velocities, initial is 0
        end
        
        function ballMove(obj,timePeriod)
            %ballMove Function for moving ball
            startingVel = obj.vel; %Sets velocity for comparing
            velMag = norm(startingVel); %Magnitude of velocity
            velAngle = atan2(obj.vel(2), obj.vel(1));
            updatedVel = velMag - (Constants.g * Constants.muTable) * timePeriod; %Calculates updated velocity magnitude due to friction
            
            if updatedVel < 0 %ensures friction does not make ball travel in opposite direction
                updatedVel = 0;
            end
            %updates velocity of ball using angle
            obj.vel(1) = updatedVel * cos(velAngle);
            obj.vel(2) = updatedVel * sin(velAngle);
            
            %calculates updated position using velocity (converts to
            %imperial for consistency
            obj.position = obj.position + convvel(obj.vel, 'm/s', 'in/s')*timePeriod;

        end
        
        function ballCollision (obj, otherBall)
            %ballCollision Function for checking collision between 2 balls
            
            if norm(obj.position-otherBall.position) < 2 * Constants.rad %Checks if collision occurs
                if(isempty(obj.colliding_balls) == 0) %Ensures collision is not calculated for balls already colliding
                    for i = 1:length(obj.colliding_balls)
                        if obj.colliding_balls(i) == otherBall
                            return;
                        end
                    end
                end
                obj.colliding_balls(end+1) = otherBall; %Adds to the array containing balls currently colliding
                
                if obj.cueBall == true || otherBall.cueBall == true %Sets coefficient of restitution based on ball type
                    e = Constants.eCueNum;
                else
                    e = Constants.eNumNum;
                end
               
                %Calculate impact angle and define rotation matrix
                impactAngle = atan2(otherBall.position(2)-obj.position(2), otherBall.position(1) - obj.position(1)); 
                R = [cos(impactAngle), -sin(impactAngle); sin(impactAngle), cos(impactAngle)];
                
                ntVelA = obj.vel * R;         %determine normal/tangential velocities of both balls using rotation matrix
                ntVelB = otherBall.vel * R;
                startingntVelA = ntVelA;
                startingntVelB = ntVelB;
                
                %Use system of equations with momentum and CoR equations to
                %solve for normal velocities of A and B
                syms normVelA normVelB;
                momentum = obj.mass * startingntVelA(1) + otherBall.mass * startingntVelB(1) == obj.mass * normVelA + otherBall.mass * normVelB;
                restitution = e == (normVelA - normVelB)/(startingntVelB(1)-startingntVelA(1));
                [A,B] = equationsToMatrix ([momentum, restitution], [normVelA, normVelB]);
                soln = linsolve(A,B);
                
                ntVelA(1) = soln(1);
                ntVelB(1) = soln(2);
                %Use system of equations with impulse equations to
                %solve for tangent velocities of A and B
                syms tanVelA tanVelB;
                impulsesA = tanVelA == startingntVelA(2) + Constants.muBalls * (ntVelA(1)-startingntVelA(1));
                impulsesB = tanVelB == startingntVelB(2) + Constants.muBalls * ntVelB(1);
                [C,D] = equationsToMatrix ([impulsesA, impulsesB],[tanVelA, tanVelB]);
                soln2 = linsolve(C,D);
                
                ntVelA(2) = soln2(1);
                ntVelB(2) = soln2(2);
                
                %Ensures tangential velocities dont switch directions
                if sign(ntVelA(2))~= 0 && (sign(ntVelA(2)) ~= sign(startingntVelA(2)))
                    ntVelA(2) = 0;
                end
                if sign(ntVelB(2))~= 0 && (sign(ntVelB(2)) ~= sign(startingntVelB(2)))
                    ntVelB(2) = 0;
                end
                %converts velocities to cartesian coordinates using
                %rotation matrix
                obj.vel = ntVelA * inv(R);
                otherBall.vel = ntVelB * inv(R);
                
            %if balls are no longer colliding, removes them from the array
            %holding currently colliding balls.
            elseif (~isempty(obj.colliding_balls))
                for i =1:length(obj.colliding_balls)
                    if obj.colliding_balls(i) == otherBall
                        obj.colliding_balls(i) = [];
                    end
                end
            end
            
        end
        
        function wallCollision (obj)
            %wallCollision Function for checking collision between a ball
            %and a wall
            startingVel = obj.vel;
            if (obj.position(1) - Constants.rad) < 0 || (obj.position(1) + Constants.rad) > Constants.length %%Collision with left and right walls
                normVel = -(Constants.eBallWall*obj.vel(1)); %reduces normal velocity using Coefficient of Restitution
                obj.vel(1) = normVel;
                
                tanVel = obj.vel(2) + Constants.muWall * (obj.vel(1) - startingVel(1)); %reduces tangent velocity due to friction
                obj.vel(2) = tanVel;
                
                %sets positions to ensure ball doesn't glitch out of bounds
                if (obj.position(1) - Constants.rad) < 0
                    obj.position(1) = Constants.rad;
                elseif (obj.position(1) + Constants.rad) > Constants.length
                    obj.position(1) = Constants.length-Constants.rad;
                end
                
                %ensures tangent velocity doesn't change
                if sign(obj.vel(2)) ~= sign(startingVel(2))
                    obj.vel(2) = 0;                
                end
            end
            
            
            %same as above but for top and bottom
            if (obj.position(2) - Constants.rad) < 0 || (obj.position(2) + Constants.rad) > Constants.width
                normVel = -(Constants.eBallWall*obj.vel(2));
                obj.vel(2) = normVel;
                
                tanVel = obj.vel(1) + Constants.muWall * (obj.vel(2) - startingVel(2));
                obj.vel(1) = tanVel;
                
                if (obj.position(2) - Constants.rad) < 0
                    obj.position(2) = Constants.rad;
                elseif (obj.position(2) + Constants.rad) > Constants.width
                    obj.position(2) = Constants.width-Constants.rad;
                end                
                
                if sign(obj.vel(1)) ~= sign(startingVel(1))
                    obj.vel(1) = 0;                
                end       
            end
        end
    end
end

