clc;
clear;

%% basic parameters
waterTankVolume = 100; % L  for fish
growBedVolume = 500; % L  for plants

fishNum = 4;
normalFishGrowthRate = 0.0001;
fishGrowthRate = normalFishGrowthRate; % num/min
plantNum = 10;
normalPlantGrowthRate = 0.00001;
plantGrowthRate = normalPlantGrowthRate; % num/min

pHInfluenceGrowthRateFactor = 3;
pHInfluenceReactionFactor = 3;

% 15 on, 45 off
waterFlowRate = 5; % L/min

maxAmmoniaProduceRate = 0.03;
minAmmoniaProduceRate = 0.01;
ammoniaProduceRatePerFish = minAmmoniaProduceRate + ... 
    rand(fishNum, 1) * (maxAmmoniaProduceRate - minAmmoniaProduceRate);
initAmmoniaConsumeRateByMicrobe = -0.01;
ammoniaConsumeRateByMicrobe = initAmmoniaConsumeRateByMicrobe;
nitrateConsumeRatePerPlant = -0.01;

initNitrateAmountInGrowBed = 0.01; % mol
initAmmoniaAmountInWaterTank = 2; % mol
initAmmoniaAmountInGrowBed = 2; % mol

ammoniaToNitrateRate = 0.7;

temperature = 298; %K

% 6.4 ~ 7.6
minpH = 6.4;
maxpH = 7.6;
normalpH = 7;
pHInWaterTank = 7;
pHInGrowBed = 7;

timeLimit = 30;  % day

ammoniaConcentrationInWaterTank = zeros(1, timeLimit);
ammoniaConcentrationInGrowBed = zeros(1, timeLimit);
nitrateConcentrationInGrowBed = zeros(1, timeLimit);

ammoniaConcentrationInWaterTank(1) = initAmmoniaAmountInWaterTank / waterTankVolume;
ammoniaConcentrationInGrowBed(1) = initAmmoniaAmountInGrowBed / growBedVolume;
nitrateConcentrationInGrowBed(1) = initNitrateAmountInGrowBed / growBedVolume;


%% simulation logic

for t = 2 : timeLimit  
    deltaAmmoniaInWaterTank = 0;
    if mod(t, 60) < 15 % on for 15 min
        % first we calculate the ammonia exchanged by flowing water
        deltaAmmoniaInGrowBed = (ammoniaConcentrationInWaterTank(t-1) - ammoniaConcentrationInGrowBed(t-1)) * waterFlowRate;
        deltaAmmoniaInWaterTank = -deltaAmmoniaInGrowBed;
    end
    % when water flow is off, ammonia amount in the container is only
    % changed by fish and plants
    for i = 1 : fishNum
        deltaAmmoniaInWaterTank = deltaAmmoniaInWaterTank + ammoniaProduceRatePerFish(i);
    end
    deltaAmmoniaInGrowBed = deltaAmmoniaInWaterTank + ammoniaConsumeRateByMicrobe;
    
    % update the water volume
    growBedVolume = growBedVolume - temperature * 0.001;
    waterTankVolume = waterTankVolume - temperature * 0.001;
    
    % update the growth rate of fish and plant
    fishGrowthRate = normalFishGrowthRate * (1 - 0.01 * abs(pHInWaterTank - normalpH) * pHInfluenceGrowthRateFactor);
    plantGrowthRate = normalPlantGrowthRate * (1 - 0.01 * abs(pHInGrowBed - normalpH) * pHInfluenceGrowthRateFactor);
    
    % update the ammonia consume rate by microbe
    ammoniaConsumeRateByMicrobe = initAmmoniaConsumeRateByMicrobe * ...
        (1 - 0.01 * abs(pHInGrowBed - normalpH) * pHInfluenceReactionFactor);
    
    % update the ammonia concentration
    ammoniaConcentrationInWaterTank(t) = (ammoniaConcentrationInWaterTank(t-1) + deltaAmmoniaInWaterTank) / waterTankVolume;
    ammoniaConcentrationInGrowBed(t) = (ammoniaConcentrationInGrowBed(t-1) + deltaAmmoniaInGrowBed) / growBedVolume;
    
    % update the nitrate concentration
    nitrateConcentrationInGrowBed(t) = nitrateConcentrationInGrowBed(t-1) + deltaAmmoniaInGrowBed * ammoniaToNitrateRate + ...
        plantNum * nitrateConsumeRatePerPlant;
    
    % update the num of fish and plants
    fishNum = fishNum * (1 + fishGrowthRate);
    plantNum = plantNum * (1 + plantGrowthRate);

    % update the pH value, may reset concentration of ammonia and nitrate 
    % in water tank and growbed
    pHInGrowBed = ammoniaConcentrationInGrowBed(t);
    if pHInGrowBed < minpH || pHInGrowBed > maxpH
        pHInGrowBed = 7;
        ammoniaConcentrationInGrowBed(t) = initAmmoniaAmountInGrowBed / growBedVolume;
        nitrateConcentrationInGrowBed(t) = initNitrateAmountInGrowBed / growBedVolume;
    end
    if pHInWaterTank < minpH || pHInWaterTank > maxpH
        pHInWaterTank = 7;
        ammoniaConcentrationInWaterTank(t) = initAmmoniaAmountInWaterTank / waterTankVolume;
    end
end

%% plot results

time = 1 : timeLimit;
subplot(1,3,1);
plot(time, ammoniaConcentrationInGrowBed);
title('Ammonia Concentration in GrowBed');
xlabel('time(min)');
ylabel('ammonia concentration(mol/L)');
grid on;
subplot(1,3,2);
plot(time, ammoniaConcentrationInWaterTank);
title('Ammonia Concentration in WaterTank');
xlabel('time(min)');
ylabel('ammonia concentration(mol/L)');
grid on;
subplot(1,3,3);
plot(time, nitrateConcentrationInGrowBed);
title('Nitrate Concentration in GrowBed');
xlabel('time(min)');
ylabel('nitrate concentration(mol/L)');
grid on;