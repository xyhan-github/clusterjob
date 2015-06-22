package CJ::Matlab;
# This is part of Clusterjob that handles the collection
# of Matlab results
# Copyright 2015 Hatef Monajemi (monajemi@stanford.edu) 

use strict;
use warnings;
use CJ;








sub read_matlab_index_set
{
    my ($forline, $TOP, $verbose) = @_;
    
    chomp($forline);
    $forline = &CJ::Matlab::uncomment_matlab_line($forline);   # uncomment the line so you dont deal with comments. easier parsing;
    
    
    # split at equal sign.
    my @myarray    = split(/\s*=\s*/,$forline);
    my @tag     = split(/\s/,$myarray[0]);
    my $idx_tag = $tag[-1];
    
    
    
    
    my $range;
    # The right of equal sign
    my $right  = $myarray[1];
    
    # see if the forline contains :
    if($right =~ /.*\:.*/){
        
        my @rightarray = split( /\s*:\s*/, $right, 2 );
        
        my $low =$rightarray[0];
        if(! &CJ::isnumeric($low) ){
            &CJ::err("The lower limit of for MUST be numeric for this version of clusterjob\n");
        }
        
        
        
        # exit on unallowed structure
        if ($rightarray[1] =~ /.*:.*/){
            &CJ::err("Sorry!...structure 'for i=1:1:3' is not allowed in clusterjob. Try rewriting your script using 'for i = 1:3' structure\n");
        }
        
        
        
        if($rightarray[1] =~ /\s*length\(\s*(.+?)\s*\)/){
            
            #CASE i = 1:length(var);
            # find the variable;
            my ($var) = $rightarray[1] =~ /\s*length\(\s*(.+?)\s*\)/;
            my $this_line = &CJ::grep_var_line($var,$TOP);
            
            
            #extract the range
            my @this_array    = split(/\s*=\s*/,$this_line);
            
            my $numbers;
            if($this_array[1] =~ /\[\s*(.+?)\s*\]/){
                ($numbers) = $this_array[1] =~ /\[\s*(.+?)\s*\]/;
            }
            
            
            #else{
            #    # FUTURE_REV_ADD
            #    #  c     = linspace(1,100,9)
            #    #  l     = floor(c)
            #    #  for i = 1:length(l)
            #    #
            #    $numbers = &run_matlab_index_interpreter($var, $TOP, $verbose)
            #
            #
            #    #&CJ::err("MATLAB structure '$this_line ' not currently supported for parrun.");
            #}
            my @vals = split(/,|;/,$numbers);
            
            my $high = 1+$#vals;
            my @range = ($low..$high);
            $range = join(',',@range);
            
        }elsif($rightarray[1] =~ /\s*(\D+).*/) {
            print "$rightarray[1]"."\n";
            # CASE i = 1:L
            # find the variable;
            my($var) = $rightarray[1] =~ /\s*(\D+).*/;
            my $this_line = &CJ::grep_var_line($var,$TOP);
            
            #extract the range
            my @this_array    = split(/\s*=\s*/,$this_line);
            my ($high) = $this_array[1] =~ /\[?\s*(\d+)\s*\]?/;
            my @range = ($low..$high);
            $range = join(',',@range);
            
        }elsif($rightarray[1] =~ /.*(\d+).*/){
            # CASE i = 1:10
            my ($high) = $rightarray[1] =~ /\s*(\d+).*/;
            my @range = ($low..$high);
            $range = join(',',@range);
            
        }else{
            
            $range = undef;
            #&CJ::err("strcuture of for loop not recognized by clusterjob. try rewriting your for loop using 'i = 1:10' structure");
            
        }
        
        
    }
    
    return ($idx_tag, $range);
}




sub run_matlab_index_interpreter{
    my (@tag_list, @for_lines , $TOP, $verbose) = @_;
    
    # Check that the local machine has MATLAB (we currently build package locally!)
    
    my $check_matlab_installed = `source ~/.bashrc ; source ~/.profile; command -v matlab`;
    if($check_matlab_installed eq ""){
    &CJ::err("I require matlab but it's not installed");
    }else{
    &CJ::message("Test passed, Matlab is installed on your machine.");
    }
    

# build a script from top to output the range of index
    
    
# Add top
my $matlab_interpreter_script = $TOP;

# Add for lines
foreach my $line (@for_lines){
  $matlab_interpreter_script .= $line;
}
    
    
foreach my $tag (@tag_list){
my $tag_file = "/tmp/$tag\.tmp";
$matlab_interpreter_script .=<<MATLAB
% add script to output values of desired variables
$tag_fid = open($tag_file,'w+');
fprintf($tag_fid,\'%i\', $tag);
close($tag_fid);
MATLAB
}
  
    
# Add end lines
foreach my $line (@for_lines){
   $matlab_interpreter_script .= "end";
}
    
    
    
    
#print $matlab_interpreter_script;
    my $name = "CJ_matlab_interpreter_script.m";
    my $path = "/tmp";
    &CJ::writeFile("$path/$name",$matlab_interpreter_script);
    &CJ::message("$name is built in $path");

    
    
my $matlab_interpreter_bash = <<BASH;
#!/bin/bash -l
source ~/.profile
source ~/.bashrc
    matlab -nodisplay -nodesktop -nosplash  <'$path/$name' &>/tmp/matlab.output    # dump matlab output
BASH

    #my $bash_name = "CJ_matlab_interpreter_bash.sh";
    #my $bash_path = "/tmp";
    #&CJ::writeFile("$bash_path/$bash_name",$matlab_interpreter_bash);
    #&CJ::message("$bash_name is built in $bash_path");

&CJ::message("Invoking matlab to find range of indecies. Please be patient...");
&CJ::my_system("echo $matlab_interpreter_bash", $verbose);
&CJ::message("Closing Matlab session!");
    
# Read the files, and put it into $numbers
# open a hashref
my $numbers={};
foreach $var (@var_list){
    my $var_file = "/tmp/$var\.tmp";
    $numbers->{'$var'} = &CJ::readFile("$var_file");
    print $numbers->{'$var'} . "\n";
}
die;
    return $numbers;
}

























sub uncomment_matlab_line{
    my ($line) = @_;
    $line =~ s/^(?:(?!\').)*\K\%(.*)//;
    return $line;
}









sub make_MAT_collect_script
{
my ($res_filename, $remaining_filename, $bqs) = @_;
    
my $collect_filename = "collect_list.txt";
    
my $matlab_collect_script=<<MATLAB;
\% READ remaining_list.txt and FIND The counters that need
\% to be read
remaining_list = load('$remaining_filename');

if(~isempty(remaining_list))


\%determine the structre of the output
if(exist('$res_filename', 'file'))
    \% CJ has been called before
    res = load('$res_filename');
    start = 1;
else
    \% Fisrt time CJ is being called
    res = load([num2str(remaining_list(1)),'/$res_filename']);
    start = 2;
    
    
    \% delete the line from remaining_filename and add it to collected.
    \%fid = fopen('$remaining_filename', 'r') ;               \% Open source file.
    \%fgetl(fid) ;                                            \% Read/discard line.
    \%buffer = fread(fid, Inf) ;                              \% Read rest of the file.
    \%fclose(fid);
    \%delete('$remaining_filename');                         \% delete the file
    \%fid = fopen('$remaining_filename', 'w')  ;             \% Open destination file.
    \%fwrite(fid, buffer) ;                                  \% Save to file.
    \%fclose(fid) ;
    
    if(~exist('$collect_filename','file'));
    fid = fopen('$collect_filename', 'a+');
    fprintf ( fid, '%d\\n', remaining_list(1) );
    fclose(fid);
    end
    
    percent_done = 1/length(remaining_list) * 100;
    fprintf('\\n SubPackage %d Collected (%3.2f%%)', remaining_list(1), percent_done );

    
end

flds = fields(res);


for idx = start:length(remaining_list)
    count  = remaining_list(idx);
    newres = load([num2str(count),'/$res_filename']);
    
    for i = 1:length(flds)  \% for all variables
        res.(flds{i}) =  CJ_reduce( res.(flds{i}) ,  newres.(flds{i}) );
    end

\% save after each packgae
save('$res_filename','-struct', 'res');
percent_done = idx/length(remaining_list) * 100;
    
\% delete the line from remaining_filename and add it to collected.
\%fid = fopen('$remaining_filename', 'r') ;              \% Open source file.
\%fgetl(fid) ;                                      \% Read/discard line.
\%buffer = fread(fid, Inf) ;                        \% Read rest of the file.
\%fclose(fid);
\%delete('$remaining_filename');                         \% delete the file
\%fid = fopen('$remaining_filename', 'w')  ;             \% Open destination file.
\%fwrite(fid, buffer) ;                             \% Save to file.
\%fclose(fid) ;

if(~exist('$collect_filename','file'));
    error('   CJerr::File $collect_filename is missing. CJ stands in AWE!');
end

fid = fopen('$collect_filename', 'a+');
fprintf ( fid, '%d\\n', count );
fclose(fid);
    
fprintf('\\n SubPackage %d Collected (%3.2f%%)', count, percent_done );
end

   

end

MATLAB




my $HEADER= &CJ::bash_header($bqs);

my $script;
if($bqs eq "SGE"){
$script=<<BASH;
$HEADER
echo starting collection
echo FILE_NAME $res_filename


module load MATLAB-R2014a;
matlab -nosplash -nodisplay <<HERE

$matlab_collect_script

quit;
HERE

echo ending colection;
echo "done"
BASH
}elsif($bqs eq "SLURM"){
$script= <<BASH;
$HEADER
echo starting collection
echo FILE_NAME $res_filename

module load matlab;
matlab -nosplash -nodisplay <<HERE

$matlab_collect_script

quit;
HERE

echo ending colection;
echo "done"
BASH

}

    
    return $script;
}




1;