#!/bin/bash
# ===================== 配置项 =====================
# 目标MySQL结果库配置
TARGET_MYSQL_HOST="mysql-master.example.com"
TARGET_MYSQL_PORT="3306"
TARGET_MYSQL_USER="root"
TARGET_MYSQL_PWD="your_password"
TARGET_MYSQL_DB="bill_result"
TARGET_MYSQL_TABLE="t_bill_5min"

# Hive配置
HIVE_TABLE="hive_bill_5min_result"
HIVE_WAREHOUSE="/user/hive/warehouse"
EXPORT_DIR="${HIVE_WAREHOUSE}/${HIVE_TABLE}"

# 时间配置（近5分钟数据）
SYNC_INTERVAL=300  # 5分钟=300秒
START_TIME=$(( $(date +%s) - ${SYNC_INTERVAL} ))
END_TIME=$(date +%s)

# 日志目录
LOG_DIR="/var/log/sqoop"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/sqoop_incremental_export_${DATE}.log"

# ===================== 前置检查 =====================
mkdir -p ${LOG_DIR}

# 检查Hive导出目录是否存在
hdfs dfs -test -d ${EXPORT_DIR}
if [ $? -ne 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Hive导出目录${EXPORT_DIR}不存在" >> ${LOG_FILE}
    exit 1
fi

# 检查目标MySQL表是否存在
MYSQL_TABLE_EXIST=$(mysql -h${TARGET_MYSQL_HOST} -P${TARGET_MYSQL_PORT} -u${TARGET_MYSQL_USER} -p${TARGET_MYSQL_PWD} -e "USE ${TARGET_MYSQL_DB}; SHOW TABLES LIKE '${TARGET_MYSQL_TABLE}';" | wc -l)
if [ ${MYSQL_TABLE_EXIST} -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: MySQL表${TARGET_MYSQL_TABLE}不存在" >> ${LOG_FILE}
    exit 1
fi

# ===================== 增量导出 =====================
echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: 开始导出${START_TIME}至${END_TIME}的分析结果" >> ${LOG_FILE}

sqoop export \
    --connect jdbc:mysql://${TARGET_MYSQL_HOST}:${TARGET_MYSQL_PORT}/${TARGET_MYSQL_DB} \
    --username ${TARGET_MYSQL_USER} \
    --password ${TARGET_MYSQL_PWD} \
    --table ${TARGET_MYSQL_TABLE} \
    --export-dir ${EXPORT_DIR} \
    --input-fields-terminated-by "\001" \
    --input-null-string '\\N' \
    --input-null-non-string '\\N' \
    --update-key user_id \  # 按user_id更新，保证幂等性
    --update-mode allowinsert \  # 有则更新，无则插入
    --where "bill_time >= ${START_TIME}" >> ${LOG_FILE} 2>&1

# ===================== 结果校验 =====================
if [ $? -eq 0 ]; then
    # 统计MySQL新增数据量
    MYSQL_CNT=$(mysql -h${TARGET_MYSQL_HOST} -P${TARGET_MYSQL_PORT} -u${TARGET_MYSQL_USER} -p${TARGET_MYSQL_PWD} -e "SELECT COUNT(*) FROM ${TARGET_MYSQL_DB}.${TARGET_MYSQL_TABLE} WHERE bill_time >= ${START_TIME};" | grep -Eo '[0-9]+' | tail -1)
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: 增量导出成功，新增/更新${MYSQL_CNT}条数据" >> ${LOG_FILE}
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: 增量导出失败，请查看日志${LOG_FILE}" >> ${LOG_FILE}
    # 触发钉钉/邮件告警（可选）
    # curl -X POST "https://oapi.dingtalk.com/robot/send?access_token=你的token" -d '{"msgtype":"text","text":{"content":"Sqoop增量导出失败：'${LOG_FILE}'"}}'
    exit 1
fi

exit 0
