
export TERM=dumb

mysql -u root --password={{.Values.mariadb.root_password}} <<- EOSQL
	CREATE DATABASE {{.Values.poolmanager.db_name}} CHARACTER SET utf8 COLLATE utf8_general_ci;
	CREATE DATABASE {{.Values.db_name}} CHARACTER SET utf8 COLLATE utf8_general_ci;
EOSQL
