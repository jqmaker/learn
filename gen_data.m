%% 生成测试数据集合

clc,clear,close all
feature jit off%循环加速加速代码运行

%%
%rand('seed', 0 )%把seed固定后，每次用它产生随机数都是一样的
rng('default');
%  任务数集合  与 ECC数  集合
num_task = 50;
num_ECC = 3;

 %%
        
        c =  10^4  ; % 处理1 Mbit数据需要的CPU周期数     !!!!!!!!!!可能需要你重新定义
        bandwidth_constant =  200  ; % 带宽常数      !!!!!!!!!!可能需要你重新定义
         % 任务价值量50*1的矩阵，规定了数值范围
        task_value = round( unifrnd( 5*10^4, 7.5*10^5 ,   num_task , 1))  ;
        % 任务量 50*1的矩阵       !!!!!!!!!!可能需要你重新定义
        task_volume =  round( unifrnd( 10,  1000 ,   num_task , 1))  ;
        %  各ECC 每秒能计算的周期数，这里假设3个ECC，定义每个的计算能力 【1*3】
        ECC_Fj =sort(  randsample(  5*10^4 : 7.5*10^5 ,   num_ECC , false ) ,  'descend'  )'  ;
        
        
        % 各个task 在不同计算机上的耗时，50*3矩阵，每个任务分别在123号ECC上的耗时，【50*1】【1*3】=【50*3】
        task_processing_time = repmat( task_volume * c  ,  1, num_ECC ) ./ repmat(  ECC_Fj' ,  num_task , 1 ) ;
        
        % 各个task的准备时间 （ 你定义的upload 时间）传输时间？跟带宽有关系【50*1】
        task_upload_time =  task_volume /  bandwidth_constant ;
        % 各个ECC的计算功率与等待功率【1*3】
        ECC_p_rate =  sort(   randsample(  50 : 80 , num_ECC  , false )   ,   'descend'   )' ;
        ECC_w_rate =  sort( randsample( 5 : 10  ,   num_ECC , 1 )   ,   'descend'   )'  ;
        
        mean_time = sum( task_processing_time(:)  )/ ( num_ECC^2) ;%平均运行时间
        % release date  ， 每个task生成的时间【50*1】跟平均运行时间有关
        task_release_date = round( unifrnd(  0   ,  1.5*mean_time ,  num_task , 1   ) ) ;
        
        % 每个task的due date=生成时间+取整（对于每个任务运行时间最少的那个ECC的运行时间*【50*1】的一个矩阵）
        task_due_date =   task_release_date   +  ceil( min(  task_processing_time , [],2 ) .* round( unifrnd( 3, 8 ,  num_task , 1  ) ) ) ;
        
                % ECC 容量
        Dmax =  max( task_volume ) ;          %  最大 任务量
        ECC_capacity =  Dmax *  randsample( 3:6,1) ;
%%  存储数据集合
        model.num_task   = num_task   ;  % 任务的数目
        model.num_ECC    = num_ECC ;  % ECC 的数目
        model.c    =  c ; % 处理1 Mbit数据需要的CPU周期数
        model.bandwidth_constant    =  bandwidth_constant  ;  % 带宽常数
        model.task_value     =  task_value  ;  % 任务价值量
        model.task_volume = task_volume  ;  % 任务量
        model.ECC_Fj   = ECC_Fj   ;  %%  各ECC 每秒能计算的周期数
        model.task_processing_time    = task_processing_time  ;   % 加工时间
        model.task_upload_time    =  task_upload_time ;  % 各个task的准备时间 （ 你定义的upload 时间）
        model.ECC_p_rate    =  ECC_p_rate ;  % % 各个ECC的计算功率与等待功率
        model.ECC_w_rate    = ECC_w_rate   ;  % % 各个ECC的计算功率与等待功率
        
        model.task_release_date    =  task_release_date    ;  % 各个task 的release date
        model.task_due_date  = task_due_date  ; % 各个task的 due date
        
        model.ECC_capacity  = ECC_capacity  ;
        %% 编码参数
        model.VarMin = 1 ; % 编码最小值
        model.VarMax =  0.99  + num_ECC ;  % 编码最大值
        model.nVar =  num_task ;  % 编码长度
        filename =  [   'model_' num2str( num_task )  ,  '_' , num2str(num_ECC)  '.mat '  ] ;
        save( ['.\data\',filename] , 'model')