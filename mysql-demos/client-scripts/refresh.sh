#!/bin/sh

source $HOME/setenv

[ ! -d $MYSQL_HOME ] && echo "Could not find MySQL dir" && exit
[ ! -f $MYSQL_HOME/mysql/bin/mysql ] && echo "Could not find mysql binaries ($MYSQL_HOME/mysql/bin/mysql)" && exit
[ ! -f $MYSQL_HOME/my.cnf ] && echo "Could not find my.cnf" && exit

# Clean-up
mysqladmin -uroot shutdown
rm -fr $MYSQL_HOME/mysqldata

mkdir $MYSQL_HOME/mysqldata
mysqld --initialize-insecure --datadir=$MYSQL_HOME/mysqldata --basedir=$MYSQL_HOME/mysql
mysqld_safe --defaults-file=$MYSQL_HOME/my.cnf --ledir=$MYSQL_HOME/mysql/bin &

while [ ! -S /tmp/mysql.sock ]
do
  echo "Waiting for MySQL to start..."
  sleep 2 
done

mysql -uroot -e"SET SQL_LOG_BIN=0; CREATE USER 'ted'@'%' IDENTIFIED BY 'ted'; GRANT ALL ON *.* TO 'ted'@'%' WITH GRANT OPTION";
pgrep mysql
mysql -uted -pted -e"status"
mysql -uted -pted -e "select @@hostname, @@global.gtid_executed"

