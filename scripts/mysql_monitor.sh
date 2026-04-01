#!/bin/bash
# MySQL主从复制状态监控告警脚本

# 告警配置
MAIL_RECEIVER="ops@telecom.com"
DINGDING_WEBHOOK="https://oapi.dingtalk.com/robot/send?access_token=xxx"
MYSQL_USER="root"
MYSQL_PASSWORD="MySQL@Telecom2023"

# 抓取主从同步关键状态
SLAVE_STATUS=$(mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW SLAVE STATUS\G")
IO_RUNNING=$(echo "${SLAVE_STATUS}" | grep "Slave_IO_Running:" | awk '{print $2}')
SQL_RUNNING=$(echo "${SLAVE_STATUS}" | grep "Slave_SQL_Running:" | awk '{print $2}')
BEHIND_MASTER=$(echo "${SLAVE_STATUS}" | grep "Seconds_Behind_Master:" | awk '{print $2}')

# 异常判断
ALERT_CONTENT=""
if [ "${IO_RUNNING}" != "Yes" ] || [ "${SQL_RUNNING}" != "Yes" ]; then
  ALERT_CONTENT="【严重告警】MySQL主从同步中断！IO线程状态：${IO_RUNNING}，SQL线程状态：${SQL_RUNNING}，请立即处理！"
elif [ "${BEHIND_MASTER}" -gt 300 ]; then
  ALERT_CONTENT="【警告】MySQL主从同步延迟超过5分钟！当前延迟：${BEHIND_MASTER}秒，请关注！"
fi

# 发送告警
if [ -n "${ALERT_CONTENT}" ]; then
  # 邮件告警
  echo "${ALERT_CONTENT}" | mail -s "MySQL主从同步告警" ${MAIL_RECEIVER}
  
  # 钉钉机器人告警
  curl -X POST -H "Content-Type: application/json" -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"${ALERT_CONTENT}\"}}" ${DINGDING_WEBHOOK}
  
  # 记录日志
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${ALERT_CONTENT}" >> /var/log/mysql_monitor.log
fi
