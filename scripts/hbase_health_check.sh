#!/bin/bash
# HBase集群健康巡检脚本

# 配置变量
HBASE_HOME="/app/hadoop/hbase-1.2.1"
ZK_QUORUM="hadoop1,hadoop2,hadoop3"
MAIL_RECEIVER="ops@telecom.com"

# 检查HBase Master状态
MASTER_STATUS=$(${HBASE_HOME}/bin/hbase hbck 2>&1 | grep "Number of live region servers" | awk '{print $NF}')

# 检查RegionServer数量
REGION_SERVERS=$(${HBASE_HOME}/bin/hbase hbck 2>&1 | grep "Number of dead region servers" | awk '{print $NF}')

# 检查HBase表一致性
TABLE_STATUS=$(${HBASE_HOME}/bin/hbase hbck 2>&1 | grep "Number of inconsistent tables" | awk '{print $NF}')

ALERT_CONTENT=""
if [ "${MASTER_STATUS}" -eq 0 ]; then
  ALERT_CONTENT="【严重告警】HBase集群无可用Master节点！"
elif [ "${REGION_SERVERS}" -gt 0 ]; then
  ALERT_CONTENT="【警告】HBase集群有${REGION_SERVERS}个RegionServer节点宕机！"
elif [ "${TABLE_STATUS}" -gt 0 ]; then
  ALERT_CONTENT="【警告】HBase集群有${TABLE_STATUS}个表存在一致性问题！"
fi

if [ -n "${ALERT_CONTENT}" ]; then
  echo "${ALERT_CONTENT}" | mail -s "HBase集群告警" ${MAIL_RECEIVER}
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${ALERT_CONTENT}" >> /var/log/hbase_health_check.log
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - HBase集群运行正常" >> /var/log/hbase_health_check.log
fi
