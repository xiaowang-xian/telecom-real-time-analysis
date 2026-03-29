#!/bin/sh
sqlplus -S 'send/send@orcl' << EOF
@create_test.sql;
EOF
sqlldr userid=send/send control='toll.ctl' log='toll.log'
