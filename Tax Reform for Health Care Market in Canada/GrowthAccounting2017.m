% GrowthAccounting.m
%----------------------------------------------------------------------
% This file takes in data series:
%   -RealGDP
%   -Population
%   -Employment
%   -Wage Bill
%   -Payments to capital
%   -Gross Capital Formation
%   -Fixed capital consumption
%Output: 
%   -Graphs of Kaldor Facts
%   -Calibrate Growth accounting
%   -Perform Growth accounting
%______________________________________________________________

clear all

%Computing Parameters
    Maxiter = 500;
    tol = 0.001;
    
%******************************************************************
%Import Data: Adjust to number of years you actually have.
%******************************************************************


Year = xlsread('Data.xlsx','Sheet1','A2:A66');
RGDP = xlsread('Data.xlsx','Sheet1','B2:B636'); %Real GDP
N =xlsread('Data.xlsx','Sheet1','C2:C66') ; %Population
L =xlsread('Data.xlsx','Sheet1','D2:D66') ; %Employment
H =xlsread('Data.xlsx','Sheet1','E2:E66') ; %Average hours/cap
hc =xlsread('Data.xlsx','Sheet1','F2:F66') ; %Human Capital
cy = xlsread('Data.xlsx','Sheet1','G2:G66'); %C/Y
iy = xlsread('Data.xlsx','Sheet1','H2:H66'); %I/Y
gy = xlsread('Data.xlsx','Sheet1','I2:I66'); %G/Y
exy = xlsread('Data.xlsx','Sheet1','J2:J66'); %EX/Y
impyy = xlsread('Data.xlsx','Sheet1','K2:K66'); %Imp/Y
Lshare = xlsread('Data.xlsx','Sheet1','M2:M66');%Labor Share
dseries = xlsread('Data.xlsx','Sheet1','N2:N66');%Labor Share
delta= mean(dseries,1)  %Depreciation
%************
%Adjust Data:
%************
nRGDP = (RGDP./N)./(RGDP(1)/N(1)); %Real GDP per capita, normalize first year to 1
qRGDP = (RGDP)./(RGDP(1));         %Real GDP, normalize first year to 1
nRGDPL = (RGDP./L)./(RGDP(1)/L(1)); %Real GDP per worker, normalize first year to 1
nL = L./L(1);                      %Labor, normalize first year to 1
nN = N./N(1);                      %Potential Labor, normalize first year to 1
nI = nRGDP.*iy;                    %Investment Value
T = size(Year,1);                  %Number of years of data that I have

%******************************
%Calculate alpha, capital share
alpha = 1-mean(Lshare);

%---------------------------------------------------------------------------
%Calculate capital series by using perpetual inventory method.
%---------------------------------------------------------------------------
%I need to solve for K_0, the initial capital stock such that
%K_0/Y_0 =  average capital to output ratio across years.
%Method: Bisection
%   -Guess K0
%   -Calculate K1 =(1-delta)K0+I0, K2=(1-delta)K1+I1, and so on
%   -Check if K0 = average(K/Y)
%   -If not, choose new guess by bisection and start again!
%---------------------------------------------------------------------------

KK = ones(T+1,1);
Ka = 0.001 ; %Initial guess, lower bound
Kb = 10;     %Initial guess, upper bound
j = 1;

NN=N;
NN(T+1,1)=NN(T,1);
%Bisection Method
while j<= Maxiter
 KK(1) = 0.5*(Ka+Kb);       %Test the midpoint between our bounds
 %Iterate on LOM K to get K series
 AvKY(1,1) = 0;             
 for it=2:T+1
     KK(it,1) = KK(it-1,1)*(1-delta)+nI(it-1);   %Calculate Kt+1 using LOM for capital, delta, and investment series 
     AvKY(1,1) = AvKY(1,1) + KK(it,1)/nRGDP(it-1,1);                 %Sum up K/Y as we go
 end    
 AvKY(1,1) = AvKY(1,1)/(T-1);   %Divide summed K/Y to get average
 diff = AvKY-KK(1)              %How close are we to satisfying K0/Y0 =  average sum Kt/Yt?
 
 %Update
    %If we are close enough, stop. 
    if (abs(diff) < tol);
       j=Maxiter+1000;
    %O/w, adjust area to search in  
    elseif (diff<0);
       Kb = KK(1);
    else
       Ka = KK(1);
    end
    %Repeat, keep track of iteration.
    j=j+1
end

%Throw out K_0 to get same time length as other variables.
K = KK(2:T+1);
%------------------------------------------------------------------------
%Create Plots
%____________
YperL = nRGDPL;
KperL = K./nL; 
KperY = K./nRGDP;
Lpay = nRGDP.*Lshare;

%figure
%subplot(2,2,1,'align'); %Upper left plot
%plot(Year,YperL)

%subplot(2,2,2,'align'); %Upper right plot
%plot(Year,KperL)

%subplot(2,2,3,'align'); %Lower left plot
%plot(Year,KperY)

%subplot(2,2,4,'align'); %Lower right plot
%plot(Year,Lpay)

%Kaldorplots(Year, YperL, KperL, KperY, Lpay)

%------------------------------------------------------------------------
%Growth Accounting
%____________
%Calculate measure of labor input:
LperN = L./(N*0.55);  %SHOULD BE SOME MEASURE OF LABOR INPUT/POTENTIAL LABOR INPUT
%First calculate the Solow Residual
for it =1:T
A(it) = (nRGDP(it)/((K(it)^(alpha))*(LperN(it)^(1-alpha))))^(1/(1-alpha)); 
end
%Normalize everything to equal one in the first year to make a nice time-series graph
nKperY = (KperY).^(alpha/(1-alpha))./KperY(1,1).^(alpha/(1-alpha));
nA = A./A(1,1);
nLperN = LperN/(LperN(1,1));
%plot(Year,nRGDP,Year,nA,Year,nKperY,Year,nLperN)
plotmat(1,:) = nRGDP;
plotmat(2,:) = nA;
plotmat(3,:) = nKperY;
plotmat(4,:) = nLperN;
%SolowTime(Year,plotmat)

%Next, decompose changes in output by decade:
%Calculate year-to-year changes
for it=2:T
changeY(it,1) = log(nRGDP(it,1)) - log(nRGDP(it-1,1));
changeA(it,1) = (log(A(1,it)) - log(A(1,it-1,1)));
changeKY(it,1) = alpha/(1-alpha)*(log(KperY(it)) - log(KperY(it-1)));
changeL(it,1) = log(LperN(it)) - log(LperN(it-1));
end
%Calculate average change in each decade
D= floor(T/10); %Number of decades
Dmat = zeros(D,4); %Need to put all data into one matrix, each index 1:4 will be a different time series. See next loop

for id = 1:D 
    for it =1:10
        %Add up the growth rates in each year divided by total number of
        %years in a decade to get the average
        Dmat(id,1) = Dmat(id,1)+changeY((id-1)*10+it,1)/10;
        Dmat(id,2) = Dmat(id,2)+changeA((id-1)*10+it,1)/10;
        Dmat(id,3) = Dmat(id,3)+changeKY((id-1)*10+it,1)/10;
        Dmat(id,4) = Dmat(id,4)+changeL((id-1)*10+it,1)/10;
    end
end

%Define a Decade Vector
Decade = (1950:10:2010);
%bar(Decade(1,2:7),Dmat)
%GrowthBar(Decade(1,2:7),Dmat)


%************************************************************************************************
%Create Targets for Calibration (PS6)
%-------------------------------------
%Calculate growth rates where necessary
for it=2:T
    gN(it) = log(N(it))-log(N(it-1));
    gY(it) = log(RGDP(it))-log(RGDP(it-1));
end
%Inputs for function to calculate BGP steady state: SScalc(target,FP)
%Target vector
target =ones(1,6);
target(1,1) = AvKY;         % f1:Average Capital to Output Ratio
target(1,2) = mean(iy);     % f2:Average Investment to Output Ratio
target(1,3) = mean(gN);     % f3:Average Population Growth Rate
target(1,4) = mean(gY);     % f4:Average RGDP/N growth Rate
target(1,5) = alpha;        % Capital Share
target(1,6) = mean(LperN);  % f6:Average Labor in Production


%Use function
Param = ones(1,4);   % A vector to write the parameters into
BGP_SS = ones(1,8);  % A vector to write the equilibrium objects into
%[Param,BGP_SS] = SScalibrate_student2017(target)
[Param,BGP_SS] = SScalibrate_student2017(target)

%CHECK: do these make sense?
disp(['------------PARAMETERS--------'])
disp(['alpha =' num2str(alpha)])
disp(['gamma =' num2str(Param(1,1))])
disp(['delta =' num2str(Param(1,2))])
disp(['theta =' num2str(Param(1,3))])
disp(['beta =' num2str(Param(1,4))])
disp(['----------EQUILIBRIUM--------'])
disp(['i =' num2str(BGP_SS(1,1))])
disp(['c =' num2str(BGP_SS(1,2))])
disp(['a =' num2str(BGP_SS(1,3))])
disp(['x =' num2str(BGP_SS(1,4))])
disp(['k =' num2str(BGP_SS(1,5))])
disp(['ell =' num2str(BGP_SS(1,6))])
disp(['r =' num2str(BGP_SS(1,7))])
disp(['w =' num2str(BGP_SS(1,8))])



%************************************************************************************************
%Conduct Fiscal Policy Analyses 
%-------------------------------------
%Parameter values
Paras = ones(1,6);
 Paras(1,1:3) = Param(1,2:4); %delta, theta, beta
 Paras(1,4) = alpha; %capital share
 Paras(1,5) = 1; %Population N
 Paras(1,6) = 1; %TFP z
%Fiscal polices
FP =ones(1,6);
 FP(1,1) = 0;        % t1:Household Investment tax/credit
 FP(1,2) = 0;        % t2:Labor Income Tax
 FP(1,3) = 0;        % t3:Consumption Tax (VAT)
 FP(1,4) = 0;        % t4:Lumpsum Tax/Transfer
 FP(1,5) = 0;        % t5:Banks' capital income tax
 FP(1,6) = 0;        % t6:Government expenditures

%*************************************
%Part 1: Calculate the SS w/out any taxes
NoTaxSS = ones(1,10);
 NoTaxSS = SSEduc2(Paras,FP);
 
%*************************************
%Part 2: See how taxes change the allocation- particularly Y and Tax Rev
tax = (0:0.05:0.5);     %Test taxes from 0% to 50%
LTaxSS = ones(size(tax,1),10);  %Labor tax
CTaxSS = ones(size(tax,1),10);  %Consumption tax
KTaxSS = ones(size(tax,1),10);  %Banks' capital income tax
for it = 1:size(tax,2)
    %Labor tax
    FP(1,2) = tax(1,it);  %Set tax to policy we want to try
    LTaxSS(it,:) = SSEduc2(Paras,FP);    %calc SS
    Lutil(1,it) = log(LTaxSS(it,2))+Param(1,3)*log(1-LTaxSS(it,6)); %calc SS utility 
    FP(1,2) = 0;    %Set back to zero
    %Consumption tax
    FP(1,3) = tax(1,it);  %Set tax to policy we want to try
    CTaxSS(it,:) = SSEduc2(Paras,FP);    %calc SS
    Cutil(1,it) = log(CTaxSS(it,2))+Param(1,3)*log(1-CTaxSS(it,6)); %calc SS utility 
    FP(1,3) = 0;    %Set back to zero    
    %Banks' capital income tax
    FP(1,5) = tax(1,it);  %Set tax to policy we want to try
    KTaxSS(it,:) = SSEduc2(Paras,FP);    %calc SS
    Kutil(1,it) = log(KTaxSS(it,2))+Param(1,3)*log(1-KTaxSS(it,6)); %calc SS utility 
    FP(1,5) = 0;    %Set back to zero    
end

%------------------------------------
%Plot Your results
%figure
%Top row = revenues
subplot(2,3,1,'align'); %Upper left plot
plot(tax(1,:)',LTaxSS(:,10))

subplot(2,3,2,'align'); %Upper mid plot
plot(tax(1,:)',CTaxSS(:,10))

subplot(2,3,3,'align'); %Upper right plot
plot(tax(1,:)',KTaxSS(:,10))

%Bottom row = Utility
subplot(2,3,4,'align'); %Upper left plot
plot(tax(1,:)',Lutil(1,:))
subplot(2,3,5,'align'); %Upper mid plot
plot(tax(1,:)',Cutil(1,:))

subplot(2,3,6,'align'); %Upper right plot
plot(tax(1,:)',Kutil(1,:))

%Laffer(tax(1,:)', LTaxSS(:,10), CTaxSS(:,10), KTaxSS(:,10), Lutil(1,:), Cutil(1,:), Kutil(1,:))

%************************************************************************************************
%Conduct Policy Experiment
%-------------------------------------
%Parameter values
Paras = ones(1,6);
 Paras(1,1:3) = Param(1,2:4); %delta, theta, beta
 Paras(1,2) = 0.4;
 Paras(1,4) = alpha; %capital share
 Paras(1,5) = 1; %Population N
 Paras(1,6) = 1; %TFP z
 %-------------------------------------
%Fiscal polices
%-------------------------------------
FP =ones(1,6);
 FP_calib(1,1) = 0.0;        % t1:Household Investment tax/credit
 FP_calib(1,2) = 0.33;       % t2:Labor Income (Tax income over $202,800)
 FP_calib(1,3) = 0.05;        % t3:Consumption Tax (VAT)
 FP_calib(1,4) = 0;        % t4:Lumpsum Tax/Transfer
 FP_calib(1,5) = 0.215;        % t5:Banks' capital income tax
 FP_calib(1,6) = 0.0;        % t6:Government expenditures

 FP = FP_calib;
%*************************************
%Part 1: Calculate the SS w/out any taxes
 NoTaxSS_exp  = SSEduc2(Paras,FP);
 
%*************************************
%Part 2: See how taxes change the allocation- particularly Y and Tax Rev
tax = (0.5:0.05:1.5);     %Test taxes from 50% to 150% change
for it = 1:size(tax,2)
    %Labor tax
    FP(1,2) = FP_calib(1,2)*tax(1,it);  %Set tax to policy we want to try
    LTaxSS_exp(it,:) = SSEduc2(Paras,FP);    %calc SS
    Lutil_exp(1,it) = log(LTaxSS_exp(it,2))+Param(1,3)*log(1-LTaxSS_exp(it,6)); %calc SS utility 
     FP = FP_calib;    %Set back to calibrated value
    %Consumption tax
    FP(1,3) = FP_calib(1,3)*tax(1,it);  %Set tax to policy we want to try
    CTaxSS_exp(it,:) = SSEduc2(Paras,FP);    %calc SS
    Cutil_exp(1,it) = log(CTaxSS_exp(it,2))+Param(1,3)*log(1-CTaxSS_exp(it,6)); %calc SS utility 
     FP = FP_calib;    %Set back to calibrated value   
    %Banks' capital income tax
    FP(1,5) = FP_calib(1,5)*tax(1,it);  %Set tax to policy we want to try
    KTaxSS_exp(it,:) = SSEduc2(Paras,FP);    %calc SS
    Kutil_exp(1,it) = log(KTaxSS_exp(it,2))+Param(1,3)*log(1-KTaxSS_exp(it,6)); %calc SS utility 
     FP = FP_calib;    %Set back to calibrated value   
end

%------------------------------------
%Plot Your results- 
figure
%Top row = revenues
subplot(2,3,1,'align'); %Upper left plot
plot(tax(1,:)',LTaxSS_exp(:,10))

subplot(2,3,2,'align'); %Upper mid plot
plot(tax(1,:)',CTaxSS_exp(:,10))

subplot(2,3,3,'align'); %Upper right plot
plot(tax(1,:)',KTaxSS_exp(:,10))

%Bottom row = Utility
subplot(2,3,4,'align'); %Upper left plot
plot(tax(1,:)',Lutil_exp(1,:))

subplot(2,3,5,'align'); %Upper mid plot
plot(tax(1,:)',Cutil_exp(1,:))

subplot(2,3,6,'align'); %Upper right plot
plot(tax(1,:)',Kutil_exp(1,:))

%************************************************************************************************
%You can solve for the equilibrium for a more complex policy %scheme (indeed you should probably do that!)
% I need to try to raise 11% of GDP (gov expenditure in US)
%-------------------------------------
 FP(1,1) = 0.0;        % t1:Household Investment tax/credit
 FP(1,2) = 0.36;       % t2:Labor Income Tax
 FP(1,3) = 0.04;        % t3:Consumption Tax (VAT)
 FP(1,4) = 0;        % t4:Lumpsum Tax/Transfer
 FP(1,5) = 0;        % t5:Banks' capital income tax
 FP(1,6) = 0.0;        % t6:Government expenditures
 
 SSout = SSEduc2(Paras,FP);
 SSutil = log(SSout(1,2))+Param(1,3)*log(1-SSout(1,6)); %calc SS utility  

 
%Output
disp(['------------PRICES--------'])
disp(['Interest Rate =' num2str(SSout(1,1))])
disp(['Rental Rate =' num2str(SSout(1,7))])
disp(['Wage Rate =' num2str(SSout(1,8))])
disp(['----------Quantities--------'])
disp(['HH Consumption =' num2str(SSout(1,2)/SSout(1,9))])
disp(['HH Savings =' num2str(SSout(1,3)/SSout(1,9))])
disp(['Investment =' num2str(SSout(1,4)/SSout(1,9))])
disp(['Capital Stock =' num2str(SSout(1,5)/SSout(1,9))])
disp(['HH Labor =' num2str(SSout(1,6))])
disp(['GDP =' num2str(SSout(1,9))])
disp(['Net Government Revenue =' num2str(SSout(1,10)/SSout(1,9))])
disp(['----------Utility--------'])
%disp(num2str(SSout(1,10)/SSout(1,9))/num2str(SSout(1,9)))
disp([num2str(SSutil)])
