clc; clear; close all;
feature jit off
tic
%%  获取算例参数
% 添加目录，改变程序当前执行目录
currentDepth = 1; % get the supper path of the current path
currPath = fileparts(mfilename('fullpath'));% get current path

path(path,   [ currPath , '\data']) ;
eval(    [  'load '      'model_'   num2str( '50' )  ,  '_' , num2str('3')  '.mat  '   ]   );
%% 定义目标函数
VarMin=1;
VarMax=3.99;
VarSize= [1 3  ] ;
CostFunction=@(x) mycost(x, model );%自定义函数mycost
for i=1:30
    
    pop(i).Position=unifrnd(VarMin,VarMax,VarSize);%维数由varsize决定的矩阵
   
    pop(i).Velocity=zeros(VarSize);%0矩阵
    
    [ pop(i).Cost , pop(i).sol ] =CostFunction(pop(i).Position);
       
    % Update Personal Best
    pop(i).Best.Position=pop(i).Position;
    pop(i).Best.Cost=pop(i).Cost;
    pop(i).Best.sol=pop(i).sol;
end
machine_index =  floor(pop(1).Position ) ;
fractional_part  =  pop(1).Position   - floor(pop(1).Position ) ;%微小差额
JobSeq =  cell(   3 , 1) ; % 作业加工序列,生成元胞数组【3*1】
for ind =  1 : 3
    temp =     find( machine_index ==  ind )  ;%返回 machine_index中值为1，2，3的索引
    
    if isempty( temp )
        continue ;
    end
    
    [ ~, ix  ]  = sort(  fractional_part( temp ) )   ;%ix保存索引
    
    JobSeq{ind  , 1  } =  temp( ix ) ;%第一行保存对于第一个ECC接近元素
end