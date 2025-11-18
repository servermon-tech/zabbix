#!/bin/bash
#
# Zabbix UserParameter용 ECM 모니터링 스크립트
# DB 정보를 조회하여 Zabbix에 전달
#

# 스크립트 디렉토리
SCRIPT_DIR="/etc/zabbix/zabbix_agent2.d"
PHP_SCRIPT="${SCRIPT_DIR}/zabbix_db_query.php"

# PHP 경로 (시스템에 맞게 수정)
PHP_BIN="/usr/bin/php"

# PHP 실행 가능 확인
if [ ! -x "$PHP_BIN" ]; then
    # 대체 PHP 경로 시도
    PHP_BIN=$(which php 2>/dev/null)
    if [ -z "$PHP_BIN" ]; then
        echo "ERROR: PHP not found"
        exit 1
    fi
fi

# PHP 스크립트 존재 확인
if [ ! -f "$PHP_SCRIPT" ]; then
    echo "ERROR: PHP script not found at $PHP_SCRIPT"
    exit 1
fi

# 메트릭 파라미터
METRIC=$1
shift  # 첫 번째 인자 제거

# 파라미터 체크
if [ -z "$METRIC" ]; then
    echo "Usage: $0 <metric> [param1=value1] [param2=value2] ..."
    echo ""
    echo "=== server_info 테이블 ==="
    echo "  server.discovery              : 서버 목록 (LLD)"
    echo "  server.list                   : 서버 목록 (JSON)"
    echo "  server.status <ServerIndex>   : 서버 상태"
    echo "  server.ip <ServerIndex>       : 서버 IP"
    echo ""
    echo "=== path_info 테이블 ==="
    echo "  path.discovery                : 경로 목록 (LLD)"
    echo "  path.list                     : 경로 목록 (JSON)"
    echo "  path.status <PathIndex>       : 경로 상태"
    echo "  path.usesize <PathIndex>      : 사용량"
    echo "  path.quotasize <PathIndex>    : 할당량"
    echo "  path.usage_percent <PathIndex>: 사용률 (%)"
    echo ""
    echo "=== configure_function 테이블 ==="
    echo "  config_function.discovery     : 설정 목록 (LLD)"
    echo "  config_function.list          : 설정 목록 (JSON)"
    echo "  config_function.status <optionname> : 설정 상태"
    echo "  config_function.data <optionname>   : 설정 값"
    echo ""
    echo "=== configure_server 테이블 ==="
    echo "  config_server.discovery       : 서버 설정 목록 (LLD)"
    echo "  config_server.list            : 서버 설정 목록 (JSON)"
    echo "  config_server.status <optionname>   : 설정 상태"
    echo "  config_server.data <optionname>     : 설정 값"
    echo ""
    echo "=== configure_web 테이블 ==="
    echo "  config_web.discovery          : 웹 설정 목록 (LLD)"
    echo "  config_web.list               : 웹 설정 목록 (JSON)"
    echo "  config_web.status <optionname>      : 설정 상태"
    echo "  config_web.data <optionname>        : 설정 값"
    echo ""
    echo "=== 보안: 랜섬웨어 탐지 ==="
    echo "  security.ransomware_count     : 최근 30일 의심 파일 수"
    echo "  security.ransomware_list      : 의심 파일 목록 (생성자명, 파일위치 포함)"
    exit 1
fi

# PHP 스크립트 실행 (나머지 모든 인자 전달)
$PHP_BIN "$PHP_SCRIPT" "$METRIC" "$@" 2>/dev/null

# 종료 코드 반환
exit $?
