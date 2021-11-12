%function  [Cost , sol ] = MyCost( x,  model)


clc,clear,close all


base_path = 'D:\zjw\源代码资料';
path(path,   [ base_path  , '\data']) ;

num_task =  50 ; % 任务的数目
num_ECC =  3 ; % ECC 的数目

eval(    [  'load '      'model_'   num2str( num_task )  ,  '_' , num2str(num_ECC)  '.mat  '   ]   )

rand('seed' , 0)
x =  unifrnd( model.VarMin , model.VarMax , 1, model.nVar ) ;

%% 解码
machine_index =  floor(  x ) ;%将 X 的每个元素四舍五入到小于或等于该元素的最接近整数。
fractional_part  =  x   - floor(x ) ;
JobSeq =  cell(   model.num_ECC , 1) ; % 作业加工序列
for ind =  1 : model.num_ECC
    temp =     find( machine_index ==  ind )  ;
    
    if isempty( temp )
        continue ;
    end
    
    [ ~, ix  ]  = sort(  fractional_part( temp ) )   ;%ix保存索引
    
    JobSeq{ind  , 1  } =  temp( ix ) ;%第一行保存对于第一个ECC接近元素
end



%% 核算具体调度时间
empty_schedule.job_index  = [] ;  %  各个任务的  job index
empty_schedule.machine_index  = [] ;  %  各个任务的  machine index
empty_schedule.release_date  = [] ;  %  各个任务的 release date
empty_schedule.auxiliary_start_time  = [] ;  %  各个任务的  辅助start time

empty_schedule.upload_time = [] ;  %  各个任务的 upload time
empty_schedule.start_time = [] ;  %  各个任务的   开始时间
empty_schedule.processing_time = [] ;  %  各个任务的    计算时间
empty_schedule.end_time = [] ;  %  各个任务的   结束时间
empty_schedule.due_date = [] ;  %  各个任务的   duedate
empty_schedule.due_date_value = [] ;  %  各个任务的   实际延误时长

% 调度方案具体情形
ScheduleInfo =  repmat( empty_schedule ,  model.num_task  ,1 ) ;

% 各个ECC当前可用时间值
machine_availableTime =  zeros( model.num_ECC ,1 ) ;

waiting_set =  cell(   model.num_ECC , 1  ) ; % ECC 加载集合
for  machine_index  = 1:  model.num_ECC
    
    temp =    JobSeq{ machine_index }  ;
    
    if isempty( temp  )
        continue ;
    end
    
    
    
    for  i  =  1: numel(  temp )
        
        % job index
        job_index =  temp( i ) ;
        ScheduleInfo( job_index).job_index =  job_index ;
        
        % machine index
        ScheduleInfo( job_index ).machine_index =  machine_index ;
        
        % job's release date
        ScheduleInfo( job_index ).release_date =  model.task_release_date( job_index );
        
        
        
        % 辅助开始时间
        ScheduleInfo( job_index).auxiliary_start_time =  max(  ScheduleInfo( job_index ).release_date  , ...
            machine_availableTime( machine_index)  ) ;
        
        
        
        % 加载  时间
        ScheduleInfo( job_index ).upload_time =  model.task_upload_time( job_index ) ;
        
        
        if i==1
            % 第1 项作业必须先加载，再处理
            % 开始时间
            ScheduleInfo( job_index ).start_time =  ScheduleInfo( job_index).auxiliary_start_time  + ...
                ScheduleInfo( job_index ).upload_time ;
            
        else
            % 第2~n项任务，先查看是否在在加载集合内，如果在，直接开始加工不用加载；否则需要加载
            if ismember( job_index ,    waiting_set{  machine_index }  )
                % 直接加工，不用加载
                ScheduleInfo( job_index ).start_time =  ScheduleInfo( job_index).auxiliary_start_time ;
                %同时删除其中的第1个加载项，（因为直接用去加工了）
                tempp =                 waiting_set{  machine_index } ;
                tempp(1)=[];
                waiting_set{  machine_index }   =  tempp ;
                
            else
                % 否在需要加载
                ScheduleInfo( job_index ).start_time =  ScheduleInfo( job_index).auxiliary_start_time  + ...
                    ScheduleInfo( job_index ).upload_time ;
            end
            
        end
        
        
        % 处理时间
        ScheduleInfo( job_index ).processing_time =  model.task_processing_time( job_index , machine_index ) ;
        
        % 结束时间
        ScheduleInfo( job_index ).end_time =  ScheduleInfo( job_index ).start_time   + ...
            ScheduleInfo( job_index ).processing_time  ;
        
        %% 每个任务结束以后，按当前任务的加工时间和当前ECC加载队列剩余容量更新加载队列中的任务
        unprocessing_temp =  temp(i+1 : end)   ; % 当前任务队列 中尚未加工的任务集合
        unupload_temp =  setdiff( unprocessing_temp ,    waiting_set{  machine_index } , 'stable'  ); %  当前任务队列 中尚未加载的任务
        
        remain_capacity =  model.ECC_capacity -  sum(   model.task_volume(   waiting_set{  machine_index }   )    ) ; % 当前ECC剩余加载容量
        
        %  按  加载时间  和 加载容量，选最小者
        ix1 =   find(  cumsum( model.task_upload_time(  unupload_temp  )  )   <=      ScheduleInfo( job_index ).processing_time ,  1 , 'last') ;
        ix2 = find(      cumsum(  model.task_volume( unupload_temp  )  )  <=    remain_capacity       ,  1 , 'last') ;
        
        ix =  min( [ix1,ix2]);
        
        waiting_set{  machine_index } =   [ waiting_set{  machine_index }  ,    unupload_temp(1:ix ) ] ;
        
        
        
        
        
        % 更新machine的结束时间
        machine_availableTime( machine_index ) =  ScheduleInfo( job_index ).end_time  ;
        
        % 各个task 的due date
        ScheduleInfo( job_index).due_date  =  model.task_due_date( job_index ) ;
        % 各个task 的 延误时间总和
        ScheduleInfo( job_index ).due_date_value =  max( 0 ,  ...
            ScheduleInfo( job_index ).end_time -  ScheduleInfo( job_index).due_date   )  ;
        
    end
    
    
    
    
end

%%   目标函数计算
% 目标函数1 计算，确定所有job的 flow time sum
F1  =  sum( [ScheduleInfo.end_time ] ) ;

% 目标函数2计算，确定能耗
% 确定每个机器总工作时间
machine_start_time = zeros( model.num_ECC , 1 ) ;  % 机器最开始的时间
for  machine_index  = 1:  model.num_ECC
    temp =    JobSeq{ machine_index }  ;
    
    if isempty( temp  )
        continue ;
    end
    
    first_job_index =  temp( 1 ) ;
    machine_start_time( machine_index) =   ScheduleInfo( first_job_index ).start_time ;
    
end
% 机器运行总时间
machine_total_run_time =  machine_availableTime -  machine_start_time ;
% 确定各个机器的计算时间
computing_time =  zeros( model.num_ECC ,1 ) ;
pt =   [ScheduleInfo.processing_time ] ;
for  machine_index  = 1:  model.num_ECC
    temp =    JobSeq{ machine_index }  ;
    
    if isempty( temp  )
        continue ;
    end
    computing_time( machine_index ) =  sum(  pt( temp ) ) ;
end
% 确定各个机器的wait时间
waiting_time =  machine_total_run_time -  computing_time ;
% 计算能耗与等待能耗成本总和
F2 =  sum( model.ECC_p_rate .*  computing_time ) + sum(  model.ECC_w_rate  .* waiting_time ) ;


% 目标3 各个任务的延误时长总和

F3 =  sum(  [ ScheduleInfo.due_date_value ] ) ;



Cost  = [  F1 ; F2 ; F3 ] ;
%%
sol.Cost  =  Cost  ;  % 评价函数
sol.F1  =  F1  ;  %目标1数值
sol.F2  =  F2  ;  %目标2数值
sol.F3  = F3  ;  %目标3数值
sol.ScheduleInfo  = ScheduleInfo  ;  %调度方案具体情形
sol.machine_total_run_time  = machine_total_run_time  ;  %各台ECC 的总运行时长
sol.computing_time  = computing_time  ;  %各台ECC的计算时长
sol.waiting_time = waiting_time ; %各台 ECC的等待时长



