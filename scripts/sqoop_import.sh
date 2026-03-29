#!/bin/bash
sqoop import --append \
--connect jdbc:oracle:thin:@92.16.19.1:1521:orcl \
--username send --password send \
--table TEST \
--hbase-table FK:S0 \
--column-family CF \
-m 1
