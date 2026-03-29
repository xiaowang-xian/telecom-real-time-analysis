#!/bin/sh
cat test.csv | while read line
do
    sqlplus -S 'send/send@orcl' << EOF
    insert into test values(${line});
    commit;
EOF
    sleep 5
done
rm -f tmp.data tmp.tmp
