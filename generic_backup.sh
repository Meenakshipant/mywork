#Version 1.0
#basic backup required on every server 
#Version 1.1 -- Changes done for handling ipv4 switch for old servers and also small code fixing for procedure backup -- 20 Jul 2018
#Version 2.0 -- Changes done for invoking the script from a central server and transferring the backup to there -- 08 Apr 2018
#Version 2.1 -- Changes done for running the script through sudo user and getting all possible backup -- 20 Apr 2018
#!/bin/bash
#1st parameter is BU,2nd parameter is operator 3rd parameter is Config file path.
#sshpass required on deployed server and host key entries will be updated as per the unused ports 
echo script started at `date`
bu=$1
operator=$2
config_file_path=$3
config_file_name=${config_file_path}/generic_backup_${bu}_${operator}.conf
echo $config_file_name
date_var=$(date +%Y%m%d)
if [ -z "${bu}" ]
then
echo "BU is missing in parameters Please pass BU"
exit 125
fi

if [ -z "${operator}" ]
then
echo "Operator is missing in parameters Please pass Operator"
exit 125
fi

if [ -z "${config_file_path}" ]
then
echo "config file path is missing in parameters Please pass config file path"
exit 125
fi

if [ ! -f "${config_file_name}" ]; then
echo "config file $config_file_name doesn't exist Please check and re run again"  
exit 125
fi

echo started backup for $bu and $operator with config file ${config_file_name}

source ${config_file_name}

echo displaying and validating config files parameters

echo Backup path in config file is $backup_path

if [ ! -d "${backup_path}" ]; then
echo "backup path doesn't exist assigning temp path to the same "  
backup_path=/tmp/
fi

echo backup_path after validation is $backup_path





echo Backup filename is ${backup_filename}

echo folder names to do backup are ${folder_names}

#if [[ $str == *['!'@#\$%^\&*()_+]* ]]
#then
  #echo "It contains one of those"
#fi

echo database backup required is ${database_backup_req}

if [ -z "${database_backup_req}" ]
then

database_backup_req=N

fi


echo database types in this server are ${type_of_databases}

if [ -z "${type_of_databases}" ]
then
	if [ ${database_backup_req^^} = "Y" ]
	then
		echo "assigning default database as mysql since database types are not defined and database backup is required"
		type_of_databases=mysql
	fi
fi

echo database types in this server after validation are ${type_of_databases}


echo mysql user is ${mysql_user}

echo mysql password is ${mysql_password}

echo mysql databases for which data and structure backup is required with table exclude list is ${mysql_data_database_table_exclude_list}

echo mysql databases for which data and structure backup is required with table include list  is ${mysql_data_database_table_include_list}

echo mysql databases for which structure backup is required with table exclude list ${mysql_structure_database_table_exclude_list}

echo mysql databases for which structure backup is required with table include list ${mysql_structure_database_table_include_list}

echo mysql databases for which procedure backup is required is ${mysql_procedure_database_list}

echo vectorwise user is ${vw_user}

echo vectorwise user password is ${vw_password}

echo vectorwise backup database and master table names ${vw_db_master_table_list}

echo db_config files backup required for ${db_configuration_files}

echo users for which crontab backup is required ${crontab_users}

echo include basic server details parameter is  ${include_basic_server_details}

echo data copy menthod to follow is  ${copy_method}



if [ -z "${include_basic_server_details}" ]
then

echo assigning default value as Y as include_basic_server_details is not defined in config

include_basic_server_details=Y

fi

echo include basic server details parameter after validation is  ${include_basic_server_details}

echo validating the config file is done now starting the backup

echo starting folder backup


if [ -z "${copy_method}" ] || [ "${copy_method}" == "/usr/bin/rsync" ]
then
echo ${copy_method}
echo assigning default value as rsync as copy method is not defined in config
copy_method='/usr/bin/rsync'
var_data_copy='/usr/bin/rsync -avR'
echo ${var_data_copy}
else
var_data_copy='cp --parents -aR'
echo ${var_data_copy}
fi



for i in $(echo ${folder_names}|tr "," "\n")

do

folder_for_backup=$(echo ${i}|cut -d\` -f1)

echo foldername for which backup is started is $folder_for_backup

extensions=$(echo ${i}|cut -d\` -f2)

if [ ${folder_for_backup} == ${extensions} ]
then 

extensions=

fi

echo extensions are $extensions
       
       
if [ -z "${extensions}" ]
then

echo extensions are not mentioned for backup

bkp_file_name=$(echo ${folder_for_backup:1} | tr '/' '_')

echo backup file name is ${bkp_file_name}

echo starting backup for ${folder_for_backup} without extensions

mkdir -p ${backup_path}/${bkp_file_name}${date_var}

echo "find ${folder_for_backup} -type f -print0 | xargs -0 -I '{}'  ${var_data_copy} {} ${backup_path}/${bkp_file_name}${date_var}"

find ${folder_for_backup} -type f -print0 | xargs -0 -I '{}'  ${var_data_copy} {} ${backup_path}/${bkp_file_name}${date_var}

echo ended backup for ${folder_for_backup} without extensions

else

echo extensions are mentioned for backup

for j in $(echo ${extensions} | tr "~" "\n")
do

bkp_file_name=$(echo ${folder_for_backup:1} | tr '/' '_')

echo backup file name is ${bkp_file_name}

echo starting backup for ${folder_for_backup} and extension ${j}
mkdir -p ${backup_path}/${bkp_file_name}${date_var}

echo "find ${folder_for_backup} -iname '*${j}' -type f -print0 | xargs -0 -I '{}'"

echo "find ${folder_for_backup} -iname '*${j}' -type f -print0 | xargs -0 -I '{}' ${var_data_copy}  {} ${backup_path}/${bkp_file_name}${date_var}"

find ${folder_for_backup} -iname "*${j}" -type f -print0 | xargs -0 -I '{}' ${var_data_copy}  "{}" ${backup_path}/${bkp_file_name}${date_var}/

#echo "find ${folder_for_backup} -iname "*${j}" -type f -print0 | xargs -0 -I '{}' cp --parents -aR "{}" $backup_path/${bkp_file_name}${date_var}"

echo ended backup for ${folder_for_backup} and extension ${j}

done


fi

done

echo folder backup done 

if [ ${database_backup_req^^} == 'Y' ]
	then

	echo types of databases for which backup is being started ${type_of_databases}

for i in $(echo ${type_of_databases} | tr "," "\n")
do

echo starting backup for ${i}

if [ ${i^^} == 'MYSQL' ]
then
echo mysql user is $mysql_user

echo mysql password is ${mysql_password}


if [ -z "${mysql_socket}" ]
then

##normal case 

echo starting data backup for given databases

if [ -z ${mysql_password} ]
then

mysql_str="mysqldump -u$mysql_user"

else

mysql_str="mysqldump -u$mysql_user -p${mysql_password}"

fi

echo mysql connection string is $mysql_str

echo starting backup for data table exclude list ${mysql_data_database_table_exclude_list}

for j in $(echo ${mysql_data_database_table_exclude_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

exclude_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${exclude_table_list} ]
then

exclude_table_list=

fi

echo table exclude are $exclude_table_list
#final=$b.$(echo ${a}|sed 's/~/,'$b'./g')

exclude_table_list="--ignore-table=$backup_database.$(echo ${exclude_table_list}| sed 's/~/ '--ignore-table=${backup_database}'./g')"
echo $exclude_table_list is after replace

echo "$mysql_str ${backup_database} $exclude_table_list > $backup_path/${backup_database}_data_exclude_${date_var}.sql"

$mysql_str ${backup_database} $exclude_table_list > $backup_path/${backup_database}_data_exclude_${date_var}.sql

done

echo ended backup for data table exclude list ${mysql_data_database_table_exclude_list}

echo starting backup for data table include list ${mysql_data_database_table_include_list}

for j in $(echo ${mysql_data_database_table_include_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

include_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${include_table_list} ]
then

include_table_list=

fi

echo table include are $include_table_list

include_table_list=$(echo ${include_table_list} | tr '~' ' ')


echo "$mysql_str ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_data_include_${date_var}.sql"

$mysql_str ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_data_include_${date_var}.sql

done

echo ended backup for data table include list ${mysql_data_database_table_include_list}

#############################structural backup


echo starting backup for structure table exclude list ${mysql_structure_database_table_exclude_list}

for j in $(echo ${mysql_structure_database_table_exclude_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

exclude_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${exclude_table_list} ]
then

exclude_table_list=

fi

echo table exclude are $exclude_table_list

#exclude_table_list=$backup_database.$(echo ${exclude_table_list//~/,${backup_database}.})
exclude_table_list="--ignore-table=$backup_database.$(echo ${exclude_table_list}| sed 's/~/ '--ignore-table=${backup_database}'./g')"
echo "$mysql_str -d ${backup_database} $exclude_table_list > $backup_path/${backup_database}_structure_exclude_${date_var}.sql"

$mysql_str -d ${backup_database} $exclude_table_list > $backup_path/${backup_database}_structure_exclude_${date_var}.sql

done

echo ended backup for structure  table exclude list ${mysql_structure_database_table_exclude_list}

echo starting backup for structure table include list ${mysql_structure_database_table_include_list}

for j in $(echo ${mysql_structure_database_table_include_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

include_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${include_table_list} ]
then

include_table_list=

fi

echo table include are $include_table_list

include_table_list=$(echo ${include_table_list} | tr '~' ' ')


echo "$mysql_str -d ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_structure_include_${date_var}.sql"

$mysql_str -d ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_structure_include_${date_var}.sql

done

echo ended backup for structure table include list ${mysql_structure_database_table_include_list}


#####procedure backup starts

echo starting backup for procedure list ${mysql_procedure_database_list}

for j in $(echo ${mysql_procedure_database_list} | tr "," "\n")
do

echo database for which backup is started is $j


echo "$mysql_str --routines --no-create-info --no-data --no-create-db ${j}  > $backup_path/${j}_procedure_${date_var}.sql"

$mysql_str --routines --no-create-info --no-data --no-create-db ${j}  > $backup_path/${j}_procedure_${date_var}.sql

done

echo ended backup for procedure list ${mysql_procedure_database_list}



else


##explicit case------------------------------------------------------------------------------------------------------------------------


echo starting data backup for given databases

if [ -z ${mysql_password} ]
then

mysql_str="mysqldump -u$mysql_user -S${mysql_socket} "

else

mysql_str="mysqldump -u$mysql_user -p${mysql_password} -S${mysql_socket} "

fi

echo mysql connection string is $mysql_str

echo starting backup for data table exclude list ${mysql_data_database_table_exclude_list}

for j in $(echo ${mysql_data_database_table_exclude_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

exclude_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${exclude_table_list} ]
then

exclude_table_list=

fi

echo table exclude are $exclude_table_list
#final=$b.$(echo ${a}|sed 's/~/,'$b'./g')

exclude_table_list="--ignore-table=$backup_database.$(echo ${exclude_table_list}| sed 's/~/ '--ignore-table=${backup_database}'./g')"
echo $exclude_table_list is after replace

echo "$mysql_str ${backup_database} $exclude_table_list > $backup_path/${backup_database}_data_exclude_${date_var}.sql"

$mysql_str ${backup_database} $exclude_table_list > $backup_path/${backup_database}_data_exclude_${date_var}.sql

done

echo ended backup for data table exclude list ${mysql_data_database_table_exclude_list}

echo starting backup for data table include list ${mysql_data_database_table_include_list}

for j in $(echo ${mysql_data_database_table_include_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

include_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${include_table_list} ]
then

include_table_list=

fi

echo table include are $include_table_list

include_table_list=$(echo ${include_table_list} | tr '~' ' ')


echo "$mysql_str ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_data_include_${date_var}.sql"

$mysql_str ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_data_include_${date_var}.sql

done

echo ended backup for data table include list ${mysql_data_database_table_include_list}

#############################structural backup


echo starting backup for structure table exclude list ${mysql_structure_database_table_exclude_list}

for j in $(echo ${mysql_structure_database_table_exclude_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

exclude_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${exclude_table_list} ]
then

exclude_table_list=

fi

echo table exclude are $exclude_table_list

#exclude_table_list=$backup_database.$(echo ${exclude_table_list//~/,${backup_database}.})
exclude_table_list="--ignore-table=$backup_database.$(echo ${exclude_table_list}| sed 's/~/ '--ignore-table=${backup_database}'./g')"
echo "$mysql_str -d ${backup_database} $exclude_table_list > $backup_path/${backup_database}_structure_exclude_${date_var}.sql"

$mysql_str -d ${backup_database} $exclude_table_list > $backup_path/${backup_database}_structure_exclude_${date_var}.sql

done

echo ended backup for structure  table exclude list ${mysql_structure_database_table_exclude_list}

echo starting backup for structure table include list ${mysql_structure_database_table_include_list}

for j in $(echo ${mysql_structure_database_table_include_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

include_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${include_table_list} ]
then

include_table_list=

fi

echo table include are $include_table_list

include_table_list=$(echo ${include_table_list} | tr '~' ' ')


echo "$mysql_str -d ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_structure_include_${date_var}.sql"

$mysql_str -d ${backup_database} ${include_table_list}  > $backup_path/${backup_database}_structure_include_${date_var}.sql

done

echo ended backup for structure table include list ${mysql_structure_database_table_include_list}


#####procedure backup starts

echo starting backup for procedure list ${mysql_procedure_database_list}

for j in $(echo ${mysql_procedure_database_list} | tr "," "\n")
do

echo database for which backup is started is $j


echo "$mysql_str --routines --no-create-info --no-data --no-create-db ${j}  > $backup_path/${j}_procedure_${date_var}.sql"

$mysql_str --routines --no-create-info --no-data --no-create-db ${j}  > $backup_path/${j}_procedure_${date_var}.sql

done

echo ended backup for procedure list ${mysql_procedure_database_list}


fi

elif [ ${i^^} == 'VECTORWISE' ]
then
###vectorwise case


echo starting backup for vectorwise master tables

echo vectorwise user is $vw_user

echo vectorwise password is $vw_password

echo vectorwise databasea and master table list $vw_db_master_table_list

echo starting backup for vectorwise master table list $vw_db_master_table_list

for j in $(echo ${vw_db_master_table_list} | tr "," "\n")
do
backup_database=$(echo ${j}|cut -d\` -f1)

echo database for which backup is started is $backup_database

include_table_list=$(echo ${j}|cut -d\` -f2)

if [ ${backup_database} == ${include_table_list} ]
then

echo table list is not mentioned please check config file


else



include_table_list=$(echo ${include_table_list} | tr '~' ' ')

echo table include are $include_table_list

cd $backup_path

mkdir -p vw_master_backup_${backup_database}_${date_var}


cd vw_master_backup_${backup_database}_${date_var}

echo working path is `pwd`

echo "copydb -u$vw_user ${backup_database} $include_table_list"

copydb -u$vw_user ${backup_database} $include_table_list


echo "sql -u$vw_user ${backup_database} < copy.out"


sql -u$vw_user ${backup_database} < copy.out

fi




done

echo ended backup for vectorwise master tables




else

echo given database not yet configured please coordinate with administrator for more queries

fi

done
	
else

echo database backup not required for this server
	
fi

#####################Data base backup ends

###DB configuration files backup starts ######

echo configuration files backup starts 

echo files needed to be backed up are $db_configuration_files

for j in $(echo ${db_configuration_files} | tr "," "\n")
do

echo taking the backup of $j

bkp_file_name=$(echo ${j:1} | tr '/' '_')

echo ${sudo_user_pwd} | sudo -S cat $j > ${backup_path}/${bkp_file_name}_${date_var}.txt


done

echo configuration files backup ends 

###DB configuration files backup ends ######

###backup for crontab users start #####

echo backup for crontabs of $crontab_users users start

for j in $(echo ${crontab_users} | tr "," "\n")
do

echo backup started for crontab user $j



echo "echo '${sudo_user_pwd}'|sudo -S crontab -u $j -l >> ${backup_path}/cron_${j}_${date_var}.txt"
echo ${sudo_user_pwd} | sudo -S crontab -u $j -l >> ${backup_path}/cron_${j}_${date_var}.txt



done

echo backup for crontabs of $crontab_users users end

###backup for crontab users start #####


if [ ${include_basic_server_details^^} == 'Y' ] 
then 

ip=`echo ${sudo_user_pwd}| sudo -S ifconfig | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1`

echo "echo '${sudo_user_pwd}'|sudo -S ifconfig | grep -oE \b([0-9]{1,3}\.){3}[0-9]{1,3}\b | head -1"


echo ip address of the server is ${ip}

#Script to capture basic OS config
echo "Capture basic information of the server" > ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- IP Address --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd}| sudo -S ifconfig >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- Hostname --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S hostname >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- OS Version --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S cat /etc/redhat-release >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- Kernal version --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S uname -a >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- Memory Info --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
free -m >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "-------------- Processor Info --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S cat /proc/cpuinfo |grep processor >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo " --------------Processor Info. --------------" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S lscpu >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "--------------Disk Info-------------- " >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S df -PTH >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "Java Version" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo $JAVA_HOME >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "/etc/profile" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S cat /etc/profile >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo "/etc/profile.d/java.sh" >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ${sudo_user_pwd} | sudo -S cat /etc/profile.d/java.sh >> ${backup_path}/${ip}_basic_details_${date_var}.txt
echo ""

fi

mkdir -p ${backup_path}/final_backup_path/

cd ${backup_path}/final_backup_path/

echo working directory is `pwd`

echo zipping final backup at final path

zip -r ${backup_filename}_${bu}_${operator}_${date_var}.zip ${backup_path}/*${date_var}*

echo zipping done at final backup path

echo removing parts backup created for the day 

cd ${backup_path}

echo working directory is `pwd`

if [ -z ${date_var} ]
then

echo skipping the purging as date variable is null

else


rm -rf ${backup_path}/*${date_var}*

echo removed parts backup created for the day
fi


echo purging of old backup started

if [ -z ${backup_purge_days} ]
then

echo assigning default parameter for purge days as same is not defined in config

backup_purge_days=10

fi

echo purging $backup_purge_days old data from ${backup_path}/final_backup_path/

find  ${backup_path}/final_backup_path/ -iname "${backup_filename}_${bu}_${operator}*.zip" -type f -mtime +$backup_purge_days -exec /bin/rm -f '{}' \;

echo purged $backup_purge_days old data from ${backup_path}/final_backup_path/

echo script completed at `date`
