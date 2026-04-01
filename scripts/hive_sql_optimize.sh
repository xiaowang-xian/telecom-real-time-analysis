#!/bin/bash
# Hive高频查询性能优化脚本

HIVE_HOME="/app/hadoop/apache-hive-2.0.0-bin"

# 开启Tez执行引擎
${HIVE_HOME}/bin/hive -e "set hive.execution.engine=tez;"

# 开启数据倾斜优化
${HIVE_HOME}/bin/hive -e "set hive.groupby.skewindata=true;"

# 开启动态分区
${HIVE_HOME}/bin/hive -e "set hive.exec.dynamic.partition=true;"
${HIVE_HOME}/bin/hive -e "set hive.exec.dynamic.partition.mode=nonstrict;"

# 开启并行执行
${HIVE_HOME}/bin/hive -e "set hive.exec.parallel=true;"
${HIVE_HOME}/bin/hive -e "set hive.exec.parallel.thread.number=8;"

# 开启JVM重用
${HIVE_HOME}/bin/hive -e "set mapred.job.reuse.jvm.num.tasks=5;"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Hive性能优化参数已配置" >> /var/log/hive_optimize.log
