for dataset_type_flag = 0:1 % 0 for train, 1 for test
    %% area number
    dir_idx_max = 5;
    numData_ineachArea = 6; %(每個area總共有幾筆資料)
    %% setting your dataset folder for DL, and set dir_num_max(每個area用幾筆資料)
    if dataset_type_flag == 0
        dataset_type = 'train';
        save_folder = "train_dataset/";
        if ~exist(save_folder, 'dir')
            mkdir(save_folder)
        end
        cov_filepath = save_folder + "train_Covariance.mat";
        label_filepath = save_folder + "train_Label.mat";
        dir_num_max = numData_ineachArea-1; %set dir_num_max(給test，每個area只有numData_ineachArea-1筆資料)
    else
        dataset_type = 'test';
        save_folder = "test_dataset/";
        if ~exist(save_folder, 'dir')
            mkdir(save_folder)
        end
        cov_filepath = save_folder + "test_Covariance.mat";
        label_filepath = save_folder + "test_Label.mat";
        dir_num_max = 1; %set dir_num_max(給test，每個area只有1筆資料)
    end

    %% 決定你要用幾個chirp
    if dataset_type_flag == 0
        num_chirp = 2;
    else
        num_chirp = 1;
    end
    %% 參數設定
    train_size_per_dir = 256*num_chirp;
    total_train_size = dir_idx_max * dir_num_max * train_size_per_dir;
    rx_size = 8; % 可調，決定你要幾個rx的資料
    tx_size = 1; % 可調，決定你要幾個tx的資料
    cov_size = rx_size*tx_size; % covariance的大小為(tx*rx, tx*rx, 2)
    Covariance = zeros(total_train_size,cov_size,cov_size,2);
    Label = zeros(total_train_size,dir_idx_max);
    %% load your train & test index
    idxfolder = "student_train_test_idx/";
    idxfilename = idxfolder + 'YOUR ID'; %%%%%%% idxfolder + 'YOUR ID'
    idxfilename_train = idxfilename + '_trainIdx';
    idxfilename_test = idxfilename + '_testIdx';
    load(idxfilename_train); %% train_numberList
    load(idxfilename_test); %% test_numberList
    %%
    for dir_idx = 1:dir_idx_max
        for dir_num = 1:dir_num_max
            %% cal Covariance idx
            cov_idx = (dir_idx-1)*dir_num_max*train_size_per_dir + (dir_num-1)*train_size_per_dir;
            
            %% load
            inputFolder = "adcData_folder/";
            if dataset_type_flag == 0
                adcData_filename = inputFolder + "adcData_area" + dir_idx + "_" + train_numberList(dir_idx,dir_num) + ".mat"; %%取用做train_dataset的adcData
            else
                adcData_filename = inputFolder + "adcData_area" + dir_idx + "_" + test_numberList(dir_idx,1) + ".mat"; %%取用做test_dataset的adcData
            end
%             inputFolder = "20230112_adc_MATfile/";
%             adcData_filename = inputFolder + "adcData_" + dataset_type + "_20230112_area" + dir_idx + "_" + dir_num + ".mat";
            load(adcData_filename);
            
            %% 取想要的資料
            % data_dim = zeros(1,4);
            data_dim = size(adcData);
            data_chirp = adcData(:,2:2+num_chirp-1,:,:); %%從第二個chirp開始，如果想要更改train,test取不同chirp可以自己改
    %         data_chirp = squeeze(data_chirp);
            data_reshape = reshape(data_chirp,[],16,12); % [256,256,...]*64 [16,12]
            data_tx_rx = data_reshape(:,1:rx_size,1:tx_size);
            data_tx_rx_reshape = reshape(data_tx_rx,[],cov_size);
            %% cal Covariance
            temp_y = transpose(data_tx_rx_reshape);
            for idx = 1:train_size_per_dir
                temp_R = temp_y(:,idx) * (temp_y(:,idx)');
                Covariance(cov_idx + idx,:,:,1) = real(temp_R);
                Covariance(cov_idx + idx,:,:,2) = imag(temp_R);
            end
            %% cal Label
            Label(cov_idx+1:cov_idx+train_size_per_dir,dir_idx) = 1;
        end
    end
    %% shuffle
    random_idx = randperm(total_train_size);
    Covariance = Covariance(random_idx,:,:,:);
    Label = Label(random_idx,:,:,:);
    %% save file
    save(cov_filepath,"Covariance");
    save(label_filepath,"Label");
    %%
    disp([dataset_type,'. Dim of cov is: ',num2str(size(Covariance)),', done.'])
end
