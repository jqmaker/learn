% Project Title: Multi-Objective Particle Swarm Optimization (MOPSO)
% function  [  rep ] = mopso(  model ,    param_mopso )
clc; clear; close all;
feature jit off
tic
%%  获取算例参数
% 添加目录，改变程序当前执行目录
currentDepth = 1; % get the supper path of the current path
currPath = fileparts(mfilename('fullpath'));% get current path
fsep = filesep;%返回分隔符，文件分隔符是分隔路径中各个文件夹和文件名的字符。
pos_v = strfind(currPath,fsep);
p = currPath(1:pos_v(length(pos_v)-currentDepth+1)-1); % -1: delete the last character  
path(path,   [ p , '\data']) ;


num_task = 50 ; % 任务的数目
num_ECC =  3 ; % ECC 的数目

eval(    [  'load '      'model_'   num2str( num_task )  ,  '_' , num2str(num_ECC)  '.mat  '   ]   )
%% 定义目标函数
CostFunction=@(x) mycost(x, model );%自定义函数mycost
nVar= model.nVar ;             % Number of Decision Variables
VarSize=[1 nVar  ] ;   % Decision Variables Matrix Size

VarMin= model.VarMin;           % Decision Variables Lower Bound
VarMax=model.VarMax;           % Decision Variables Upper Bound

%% MOPSO Parameters
MaxIt=  600;           % Maximum Number of Iterations迭代次数
nPop=30  ;            % Population Size 种群规模
nRep= 30  ;            % Repository Size存储
w=  0.95 ;              % Inertia Weight惯性权重
wdamp=0.99 ;         % Intertia Weight Damping Rate
c1= 1;               % Personal Learning Coefficient
c2= 2 ;               % Global Learning Coefficient
nGrid= 7 ;            % Number of Grids per Dimension每个粒子维数

alpha=0.1;          % Inflation Rate通货膨胀率
beta=2;             % Leader Selection Pressure
gamma=2;            % Deletion Selection Pressure
mu=0.1;             % Mutation Rate突变概率

%% Initialization

empty_particle.Position=[];
empty_particle.Velocity=[];
empty_particle.Cost=[];
empty_particle.sol=[];
empty_particle.Best.Position=[];
empty_particle.Best.Cost=[];
empty_particle.Best.sol=[];

empty_particle.IsDominated=[];%Dominated被支配
empty_particle.GridIndex=[];%网格索引
empty_particle.GridSubIndex=[];


pop=repmat(empty_particle,nPop,1);%扩展为30*1的矩阵

for i=1:nPop
    
    pop(i).Position=unifrnd(VarMin,VarMax,VarSize);%维数由varsize决定的矩阵
    
    pop(i).Velocity=zeros(VarSize);%0矩阵
    
    [ pop(i).Cost , pop(i).sol ] =CostFunction(pop(i).Position);
    
    
    % Update Personal Best
    pop(i).Best.Position=pop(i).Position;
    pop(i).Best.Cost=pop(i).Cost;
    pop(i).Best.sol=pop(i).sol;
end

% Determine Domination
pop=DetermineDomination(pop);

rep=pop(~[pop.IsDominated]);

Grid=CreateGrid(rep,nGrid,alpha);

for i=1:numel(rep)
    rep(i)=FindGridIndex(rep(i),Grid);
end


%% MOPSO Main Loop

for it=1:MaxIt
    
    for i=1:nPop
        
        leader=SelectLeader(rep,beta);
        
        pop(i).Velocity = w*pop(i).Velocity ...
            +c1*rand(VarSize).*(pop(i).Best.Position-pop(i).Position) ...
            +c2*rand(VarSize).*(leader.Position-pop(i).Position);
        
        pop(i).Position = pop(i).Position + pop(i).Velocity;
        
        pop(i).Position = max(pop(i).Position, VarMin);
        pop(i).Position = min(pop(i).Position, VarMax);
        
        [  pop(i).Cost , pop(i).sol ] = CostFunction(pop(i).Position);
        
        % Apply Mutation
        pm=(1-(it-1)/(MaxIt-1))^(1/mu);
        if rand<pm
            NewSol.Position=Mutate(pop(i).Position,pm,VarMin,VarMax);
            [ NewSol.Cost , NewSol.sol ]=CostFunction(NewSol.Position);
            if Dominates(NewSol,pop(i))
                pop(i).Position=NewSol.Position;
                pop(i).Cost  =NewSol.Cost;
                pop(i).sol =NewSol.sol ;
                
            elseif Dominates(pop(i),NewSol)
                % Do Nothing
                
            else
                if rand<0.5
                    pop(i).Position=NewSol.Position;
                    pop(i).Cost  =NewSol.Cost;
                    pop(i).sol =NewSol.sol ;
                    
                end
            end
        end
        
        if Dominates(pop(i),pop(i).Best)
            pop(i).Best.Position=pop(i).Position;
            pop(i).Best.Cost=pop(i).Cost;
            pop(i).Best.sol=pop(i).sol;
            
        elseif Dominates(pop(i).Best,pop(i))
            % Do Nothing
            
        else
            if rand<0.5
                pop(i).Best.Position=pop(i).Position;
                pop(i).Best.Cost=pop(i).Cost;
                pop(i).Best.sol=pop(i).sol;
            end
        end
        
    end
    
    % Add Non-Dominated Particles to REPOSITORY
    rep=[rep
        pop(~[pop.IsDominated])]; %#ok
    
    %  删除重复解
    [  ~, ia ] = unique(   [      rep.Cost ]'  , 'rows' ) ;
    rep =         rep(ia );
    
    
    
    % Determine Domination of New Resository Members
    rep=DetermineDomination(rep);
    
    % Keep only Non-Dminated Memebrs in the Repository
    rep=rep(~[rep.IsDominated]);
    
    % Update Grid
    Grid=CreateGrid(rep,nGrid,alpha);
    
    % Update Grid Indices
    for i=1:numel(rep)
        rep(i)=FindGridIndex(rep(i),Grid);
    end
    
    % Check if Repository is Full
    if numel(rep)>nRep
        
        Extra=numel(rep)-nRep;
        for e=1:Extra
            rep=DeleteOneRepMemebr(rep,gamma);
        end
        
    end
    
    if  it==MaxIt   ||  ~mod( it , 20 )
        % Plot Costs
        figure(1);
        PlotCosts(rep);
        pause(0.01);
        
    end
    
    % Show Iteration Information
    disp(['Iteration ' num2str(it) ': Number of Rep Members = ' num2str(numel(rep))]);
    %     disp(  rep.Cost  )
    % Damping Inertia Weight
    w=w*wdamp;
    
    
    if toc>120
        break ;
    end
    
end

%% Resluts
% 绘制各个非劣解的  甘特图
for ind  =  1: numel(rep )
% for ind  =  1: 3  % 绘制前三个非劣解的甘特图
    figure(ind+1)
    set(gcf, 'NumberTitle', 'off', 'Name', [ '第'  num2str(ind ) '非劣解的甘特图' ]  );
    
    BestSol =  rep( ind )  ;
    PlotSolution( BestSol  , model)
    
end







