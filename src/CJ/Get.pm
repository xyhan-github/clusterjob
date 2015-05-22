package CJ::Get;
# This is part of Clusterjob that handles GET option
# Copyright 2015 Hatef Monajemi (monajemi@stanford.edu)

use strict;
use warnings;
use CJ;
use CJ::CJVars;






sub reduce_results{
    my ($package,$res_filename,$verbose) = @_;
    
    my $machine;
    my $account;
    my $remote_path;
    my $local_path;
    my $job_id;
    my $bqs;
    my $runflag;
    my $program;

    
    my $info;
    if(&CJ::is_valid_package_name($package) ){
        
        
        my $cmd= "grep -q '$package' '$run_history_file'";
        my $pattern_exists = system($cmd);chomp($pattern_exists);
        
        
        
        if ($pattern_exists==0){
            
            $info  = &CJ::retrieve_package_info($package);
            $machine = $info->{'machine'};
            $account    = $info->{'account'};
            $remote_path = $info->{'remote_path'};
            $runflag    = $info->{'runflag'};
            $bqs        = $info->{'bqs'};
            $job_id     = $info->{'job_id'};
            $program    = $info->{'program'};
            
            
            
        }else{
            &CJ::err("No such job found in CJ database");
        }
        
    }else{
        
        $info  = &CJ::retrieve_package_info();   # retrieves the last instance info;
        $machine    = $info->{'machine'};
        $package    = $info->{'package'};
        $account    = $info->{'account'};
        $remote_path = $info->{'remote_path'};
        $runflag    = $info->{'runflag'};
        $bqs        = $info->{'bqs'};
        $job_id     = $info->{'job_id'};
        $program    = $info->{'program'};
        
    }

# REDUCE IS ONLY FOR PARRUN
  if(! $runflag =~ m/^par*/){
      CJ::err("REDUCE must be called for a 'parrun' package. Please use GET instead.");
  }
    
    
    
    
    # Get current remote directory from .ssh_config
    # user might wanna rename, copy to anothet place,
    # etc. We consider the latest one , and if the
    # save remote is different, we issue a warning
    # for the user.
    print "$machine\n";
    my $ssh             = &CJ::host($machine);
    my $remotePrefix    = $ssh->{remote_repo};
    
    my @program_name    = split /\./,$program;
    my  $lastone = pop @program_name;
    my $program_name   =   join "\_",@program_name;
    my $current_remote_path = "$remotePrefix/$program_name/$package";
    
    #print("$remote_path");
    if($current_remote_path ne $remote_path){
        &CJ::warning("the .ssh_config remote directory and the history remote are not the same. CJ is choosing:\n     $account:${current_remote_path}.");
        $remote_path = $current_remote_path;
    }
    
    
    
    
    
    if (!defined($res_filename)){
        &CJ::err("The result filename must be provided for GET with parrun packages, eg, 'clusterjob get Results.mat' ");
    }
    
    
    my $check_runs = &CJ::Get::make_parrun_check_script($info,$res_filename);
    my $check_name = "check_complete.sh";
    my $check_path = "/tmp/$check_name";
    &CJ::writeFile($check_path,$check_runs);
    my $cmd = "scp $check_path $account:$remote_path/ ;ssh $account 'source ~/.bashrc;cd $remote_path; bash $check_name'";
    &CJ::my_system($cmd,$verbose);
    
    # Run a script to gather all *.mat files of the same name.
    my $done_filename = "done_list.txt";
    
    my $ext = lc(getExtension($res_filename));
    
    
    my $collect_bash_script;
    if( $ext =~ m/mat/){
        $collect_bash_script = &CJ::Matlab::make_MAT_collect_script($res_filename, $done_filename,$bqs);
    }elsif ($ext =~ m/txt|csv/){
        $collect_bash_script = &CJ::Get::make_TEXT_collect_script($res_filename, $done_filename,$bqs);
    }else{
        &CJ::err("File extension not recognized");
    }
    
    
    #print "$collect_bash_script";
    
    
    my $CJ_reduce = "$install_dir/CJ/CJ_reduce.m";
    my $collect_name = "cj_collect.sh";
    my $collect_bash_path = "/tmp/$collect_name";
    &CJ::writeFile($collect_bash_path,$collect_bash_script);
    $cmd = "scp $collect_bash_path $CJ_reduce $account:$remote_path/";
    &CJ::my_system($cmd,$verbose);
    
    
    $cmd = "ssh $account 'cd $remote_path; srun bash -l $collect_name'";
    &CJ::my_system($cmd,$verbose);

}



#==========================================================
#            CLUSTERJOB GET
#       ex.  clusterjob get Results.txt
#       ex.  clusterjob get 2015JAN07_213759  Results.mat
#==========================================================





sub get_results{
    my ($package,$res_filename,$verbose) = @_;
   

    my $machine;
    my $account;
    my $remote_path;
    my $local_path;
    my $job_id;
    my $bqs;
    my $runflag;
    my $program;
    
    my $info;
    if(&CJ::is_valid_package_name($package) ){
        
        
        my $cmd= "grep -q '$package' '$run_history_file'";
        my $pattern_exists = system($cmd);chomp($pattern_exists);
        
        
        
        if ($pattern_exists==0){
            
            $info  = &CJ::retrieve_package_info($package);
            $machine = $info->{'machine'};
            $account    = $info->{'account'};
            $remote_path = $info->{'remote_path'};
            $runflag    = $info->{'runflag'};
            $bqs        = $info->{'bqs'};
            $job_id     = $info->{'job_id'};
            $program    = $info->{'program'};
            
            
            
        }else{
            &CJ::err("No such job found in CJ database");
        }
        
    }else{
        
        $info  = &CJ::retrieve_package_info();   # retrieves the last instance info;
        $machine    = $info->{'machine'};
        $package    = $info->{'package'};
        $account    = $info->{'account'};
        $remote_path = $info->{'remote_path'};
        $runflag    = $info->{'runflag'};
        $bqs        = $info->{'bqs'};
        $job_id     = $info->{'job_id'};
        $program    = $info->{'program'};
        
    }
    
    

    
    # Get current remote directory from .ssh_config
    # user might wanna rename, copy to anothet place,
    # etc. We consider the latest one , and if the
    # save remote is different, we issue a warning
    # for the user.
    print "$machine\n";
    my $ssh             = &CJ::host($machine);
    my $remotePrefix    = $ssh->{remote_repo};
    
    my @program_name    = split /\./,$program;
    my  $lastone = pop @program_name;
    my $program_name   =   join "\_",@program_name;
    my $current_remote_path = "$remotePrefix/$program_name/$package";
    
    #print("$remote_path");
    if($current_remote_path ne $remote_path){
        &CJ::warning("the .ssh_config remote directory and the history remote are not the same. CJ is choosing:\n     $account:${current_remote_path}.");
        $remote_path = $current_remote_path;
    }
    
    
    
    
    # Give a message that REDUCE must be called before
    # Get for parrun. Sometimes, people wont want to reduce
    # in which case a GET does the job. For instance, each
    # parrallel folder might contain a *.vtu file for a certain
    # time, and you certainly dont want to reduce that
    
    if($runflag =~ m/^par*/){
        &CJ::message("Run REDUCE before GET for reducing parrun packages");
    }
    
    mkdir "$get_tmp_dir" unless (-d "$get_tmp_dir");
    mkdir "$get_tmp_dir/$package" unless (-d "$get_tmp_dir/$package");
    
    my $cmd = "rsync -arvz  $account:${remote_path}/* $get_tmp_dir/$package";
    &CJ::my_system($cmd,$verbose);
    &CJ::message("Please see your last results in $get_tmp_dir/$package");
    
    
    exit 0;
}











sub getExtension{
    my ($filename) = @_;
    print "$filename\n";
    
    my ($ext) = $filename =~ /\.([^.]+)$/;
    return $ext;
}














sub make_parrun_check_script{
    
my ($info,$res_filename) = @_;
my $machine    = $info->{'machine'};
my $package    = $info->{'package'};
my $account    = $info->{'account'};
my $remote_path = $info->{'remote_path'};
my $runflag    = $info->{'runflag'};
my $bqs        = $info->{'bqs'};
my $job_id     = $info->{'job_id'};
my $program    = $info->{'program'};





#find the number of folders with results in it
my @job_ids = split(',', $job_id);
my $num_res = 1+$#job_ids;

# header for bqs's
my $HEADER = &CJ::bash_header($bqs);
# check which jobs are done.
my $bash_remote_path  = $remote_path;
$bash_remote_path =~ s/~/\$HOME/;
my $check_runs=<<TEXT;
$HEADER

if [ ! -f "$bash_remote_path/run_list.txt" ];then
touch $bash_remote_path/done_list.txt
touch $bash_remote_path/run_list.txt

for COUNTER in `seq $num_res`;do
    if [ -f "$bash_remote_path/\$COUNTER/$res_filename" ];then
echo -e "\$COUNTER\\t" >> "$bash_remote_path/done_list.txt"
    else
        echo -e "\$COUNTER\\t" >> "$bash_remote_path/run_list.txt"
        fi
        done
        else
            
            for line in \$(cat $bash_remote_path/run_list.txt);do
                COUNTER=`grep -o "[0-9]*" <<< \$line`
                if [ -f "$bash_remote_path/\$COUNTER/$res_filename" ];then
echo -e "\$COUNTER\\t" >> "$bash_remote_path/done_list.txt"
sed  '/\^\$COUNTER\$/d' "$bash_remote_path/run_list.txt" > "$bash_remote_path/run_list.txt"
fi
done
fi

TEXT

    
    return  $check_runs;
    
    
}




1;