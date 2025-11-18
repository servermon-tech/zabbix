#!/bin/bash
#
# ECM 모니터링 스크립트 테스트
#

echo "=========================================="
echo "ECM Zabbix 모니터링 테스트"
echo "=========================================="
echo ""

SCRIPT="./ecm.sh"

# ================================================
# server_info 테이블 테스트
# ================================================
echo "=========================================="
echo "1. server_info 테이블"
echo "=========================================="
echo ""

echo "[1-1] Discovery (LLD)"
echo "$ $SCRIPT server.discovery"
$SCRIPT server.discovery
echo -e "\n"

echo "[1-2] 서버 목록 (JSON)"
echo "$ $SCRIPT server.list"
$SCRIPT server.list
echo -e "\n"

echo "[1-3] 서버 상태 (ServerIndex=1)"
echo "$ $SCRIPT server.status ServerIndex=1"
$SCRIPT server.status ServerIndex=1
echo -e "\n"

echo "[1-4] 서버 IP (ServerIndex=1)"
echo "$ $SCRIPT server.ip ServerIndex=1"
$SCRIPT server.ip ServerIndex=1
echo -e "\n"

# ================================================
# path_info 테이블 테스트
# ================================================
echo "=========================================="
echo "2. path_info 테이블"
echo "=========================================="
echo ""

echo "[2-1] Discovery (LLD)"
echo "$ $SCRIPT path.discovery"
$SCRIPT path.discovery
echo -e "\n"

echo "[2-2] 경로 목록 (JSON)"
echo "$ $SCRIPT path.list"
$SCRIPT path.list
echo -e "\n"

echo "[2-3] 경로 상태 (PathIndex=1)"
echo "$ $SCRIPT path.status PathIndex=1"
$SCRIPT path.status PathIndex=1
echo -e "\n"

echo "[2-4] 사용량 (PathIndex=1)"
echo "$ $SCRIPT path.usesize PathIndex=1"
$SCRIPT path.usesize PathIndex=1
echo -e "\n"

echo "[2-5] 할당량 (PathIndex=1)"
echo "$ $SCRIPT path.quotasize PathIndex=1"
$SCRIPT path.quotasize PathIndex=1
echo -e "\n"

echo "[2-6] 사용률 (PathIndex=1)"
echo "$ $SCRIPT path.usage_percent PathIndex=1"
$SCRIPT path.usage_percent PathIndex=1
echo "%\n"

# ================================================
# configure_function 테이블 테스트
# ================================================
echo "=========================================="
echo "3. configure_function 테이블"
echo "=========================================="
echo ""

echo "[3-1] Discovery (LLD)"
echo "$ $SCRIPT config_function.discovery"
$SCRIPT config_function.discovery
echo -e "\n"

echo "[3-2] 설정 목록 (JSON)"
echo "$ $SCRIPT config_function.list"
$SCRIPT config_function.list
echo -e "\n"

echo "[3-3] 설정 상태 (optionname=log_level)"
echo "$ $SCRIPT config_function.status optionname=log_level"
$SCRIPT config_function.status optionname=log_level
echo -e "\n"

echo "[3-4] 설정 값 (optionname=log_level)"
echo "$ $SCRIPT config_function.data optionname=log_level"
$SCRIPT config_function.data optionname=log_level
echo -e "\n"

# ================================================
# configure_server 테이블 테스트
# ================================================
echo "=========================================="
echo "4. configure_server 테이블"
echo "=========================================="
echo ""

echo "[4-1] Discovery (LLD)"
echo "$ $SCRIPT config_server.discovery"
$SCRIPT config_server.discovery
echo -e "\n"

echo "[4-2] 서버 설정 목록 (JSON)"
echo "$ $SCRIPT config_server.list"
$SCRIPT config_server.list
echo -e "\n"

echo "[4-3] 설정 상태 (optionname=server_port)"
echo "$ $SCRIPT config_server.status optionname=server_port"
$SCRIPT config_server.status optionname=server_port
echo -e "\n"

echo "[4-4] 설정 값 (optionname=server_port)"
echo "$ $SCRIPT config_server.data optionname=server_port"
$SCRIPT config_server.data optionname=server_port
echo -e "\n"

# ================================================
# configure_web 테이블 테스트
# ================================================
echo "=========================================="
echo "5. configure_web 테이블"
echo "=========================================="
echo ""

echo "[5-1] Discovery (LLD)"
echo "$ $SCRIPT config_web.discovery"
$SCRIPT config_web.discovery 2>/dev/null || echo "{\"data\":[]}"
echo -e "\n"

echo "[5-2] 웹 설정 목록 (JSON)"
echo "$ $SCRIPT config_web.list"
$SCRIPT config_web.list 2>/dev/null || echo "[]"
echo -e "\n"

echo "[5-3] 설정 상태 (optionname=port)"
echo "$ $SCRIPT config_web.status optionname=port"
$SCRIPT config_web.status optionname=port 2>/dev/null || echo "0"
echo -e "\n"

echo "[5-4] 설정 값 (optionname=port)"
echo "$ $SCRIPT config_web.data optionname=port"
$SCRIPT config_web.data optionname=port 2>/dev/null || echo "N/A"
echo -e "\n"

# ================================================
# MySQL 시스템 정보
# ================================================
echo "=========================================="
echo "6. MySQL 시스템 정보"
echo "=========================================="
echo ""

echo "[6-1] 연결 수"
echo "$ $SCRIPT mysql.connection_count"
$SCRIPT mysql.connection_count
echo -e "\n"

echo "[6-2] MySQL 버전"
echo "$ $SCRIPT mysql.version"
$SCRIPT mysql.version
echo -e "\n"

echo "=========================================="
echo "테스트 완료"
echo "=========================================="

# ================================================
# 보안: 랜섬웨어 탐지
# ================================================
echo ""
echo "=========================================="
echo "7. 보안: 랜섬웨어 탐지"
echo "=========================================="
echo ""

echo "[7-1] 최근 30일 의심 파일 수"
echo "$ $SCRIPT security.ransomware_count"
$SCRIPT security.ransomware_count 2>/dev/null || echo "0 (file_info 테이블 없음)"
echo -e "\n"

echo "[7-2] 의심 파일 목록 (생성자명, 파일위치 포함)"
echo "$ $SCRIPT security.ransomware_list"
result=$($SCRIPT security.ransomware_list 2>/dev/null)
if [ -n "$result" ] && [ "$result" != "ERROR" ]; then
    echo "$result" | head -20
else
    echo "[] (file_info 테이블 없음)"
fi
echo -e "\n"

