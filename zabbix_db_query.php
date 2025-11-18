<?php
/**
 * Zabbix용 MySQL 조회 스크립트
 * PHP 5.6+, 7.x, 8.x 호환
 */

require_once dirname(__FILE__) . '/zabbix_db_config.php';

/**
 * 데이터베이스 연결
 */
function connectDB() {
    // 연결 타임아웃 설정
    mysqli_report(MYSQLI_REPORT_OFF); // 에러 리포트 끄기
    
    $conn = @mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, DB_PORT);
    
    if (!$conn) {
        error_log("Zabbix DB Error: " . mysqli_connect_error());
        return null;
    }
    
    // 문자셋 설정
    mysqli_set_charset($conn, 'utf8mb4') or mysqli_set_charset($conn, 'utf8');
    
    // 쿼리 타임아웃 설정 (300초)
    @mysqli_query($conn, "SET SESSION max_execution_time = 300");
    @mysqli_query($conn, "SET SESSION wait_timeout = 300");
    
    return $conn;
}

/**
 * 쿼리 실행 및 결과 반환
 */
function executeQuery($conn, $query) {
    // 쿼리 실행 (에러 억제)
    $result = @mysqli_query($conn, $query);
    
    if (!$result) {
        $error = mysqli_error($conn);
        error_log("Zabbix Query Error: " . $error);
        
        // 타임아웃 에러인 경우 특별 처리
        if (strpos($error, 'timeout') !== false || 
            strpos($error, 'lock wait') !== false) {
            error_log("Query timeout detected");
        }
        
        return null;
    }
    
    $data = array();
    
    // 결과 가져오기 (타임아웃 방지)
    $count = 0;
    $max_rows = 1000; // 최대 1000개까지만
    
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
        $count++;
        if ($count >= $max_rows) {
            error_log("Result limit reached: $max_rows rows");
            break;
        }
    }
    
    mysqli_free_result($result);
    return $data;
}

/**
 * 안전한 WHERE 조건 생성
 */
function buildWhereClause($conn, $conditions) {
    if (empty($conditions)) {
        return "";
    }
    
    $where_parts = array();
    foreach ($conditions as $column => $value) {
        $safe_column = mysqli_real_escape_string($conn, $column);
        $safe_value = mysqli_real_escape_string($conn, $value);
        $where_parts[] = "$safe_column = '$safe_value'";
    }
    
    return " WHERE " . implode(" AND ", $where_parts);
}

/**
 * 결과를 Zabbix 형식으로 출력
 */
function outputResult($data, $format = 'json') {
    if ($data === null) {
        echo "ERROR";
        return;
    }
    
    if ($format === 'json') {
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    } elseif ($format === 'lld') {
        // Zabbix LLD 형식 출력
        $lld_data = array();
        foreach ($data as $row) {
            $lld_row = array();
            foreach ($row as $key => $value) {
                // 컬럼명을 대문자로 변환하고 {#...} 형식으로 만듦
                $lld_key = '{#' . strtoupper($key) . '}';
                $lld_row[$lld_key] = $value;
            }
            $lld_data[] = $lld_row;
        }
        echo json_encode(array('data' => $lld_data), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    } else {
        // 단일 값 출력
        if (is_array($data) && count($data) > 0) {
            $firstRow = $data[0];
            $firstValue = reset($firstRow);
            echo $firstValue;
        } else {
            echo "0";
        }
    }
}

/**
 * 메인 함수
 */
function main($metric, $params = array()) {
    $conn = connectDB();
    if (!$conn) {
        echo "ERROR";
        exit(1);
    }
    
    $query = "";
    $format = OUTPUT_FORMAT;
    
    // 메트릭별 쿼리 정의
    switch ($metric) {
        // ================================================
        // server_info 테이블
        // ================================================
        case 'server.discovery':
            // 서버 목록 Discovery (LLD)
            $query = "SELECT ServerIndex, ServerIP FROM server_info";
            $format = 'lld';
            break;
            
        case 'server.list':
            // 서버 목록 조회 (JSON)
            $where = buildWhereClause($conn, $params);
            $query = "SELECT ServerIndex, ServerIP FROM server_info" . $where;
            $format = 'json';
            break;
            
        case 'server.status':
            // 특정 서버 상태 확인 (1=존재, 0=없음)
            if (empty($params['ServerIndex'])) {
                echo "ERROR: ServerIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['ServerIndex']);
            $query = "SELECT COUNT(*) as value FROM server_info WHERE ServerIndex = '$index'";
            $format = 'text';
            break;
            
        case 'server.ip':
            // 특정 서버 IP 조회
            if (empty($params['ServerIndex'])) {
                echo "ERROR: ServerIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['ServerIndex']);
            $query = "SELECT ServerIP as value FROM server_info WHERE ServerIndex = '$index'";
            $format = 'text';
            break;
        
        // ================================================
        // path_info 테이블
        // ================================================
        case 'path.discovery':
            // 경로 목록 Discovery (LLD)
            $query = "SELECT PathIndex, PathName, Name, UseSize, QuotaSize FROM path_info";
            $format = 'lld';
            break;
            
        case 'path.list':
            // 경로 목록 조회 (JSON)
            $where = buildWhereClause($conn, $params);
            $query = "SELECT PathIndex, PathName, Name, UseSize, QuotaSize FROM path_info" . $where;
            $format = 'json';
            break;
            
        case 'path.status':
            // 특정 경로 상태 확인
            if (empty($params['PathIndex'])) {
                echo "ERROR: PathIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['PathIndex']);
            $query = "SELECT COUNT(*) as value FROM path_info WHERE PathIndex = '$index'";
            $format = 'text';
            break;
            
        case 'path.usesize':
            // 특정 경로 사용량 조회
            if (empty($params['PathIndex'])) {
                echo "ERROR: PathIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['PathIndex']);
            $query = "SELECT UseSize as value FROM path_info WHERE PathIndex = '$index'";
            $format = 'text';
            break;
            
        case 'path.quotasize':
            // 특정 경로 할당량 조회
            if (empty($params['PathIndex'])) {
                echo "ERROR: PathIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['PathIndex']);
            $query = "SELECT QuotaSize as value FROM path_info WHERE PathIndex = '$index'";
            $format = 'text';
            break;
            
        case 'path.usage_percent':
            // 특정 경로 사용률 (%) 조회
            if (empty($params['PathIndex'])) {
                echo "ERROR: PathIndex required";
                mysqli_close($conn);
                exit(1);
            }
            $index = mysqli_real_escape_string($conn, $params['PathIndex']);
            $query = "SELECT 
                        ROUND((UseSize / NULLIF(QuotaSize, 0)) * 100, 2) as value 
                      FROM path_info 
                      WHERE PathIndex = '$index'";
            $format = 'text';
            break;
            
        // ================================================
        // configure_function 테이블
        // ================================================
        case 'config_function.discovery':
            // 설정 목록 Discovery (LLD)
            $query = "SELECT optionname, optiondata FROM configure_function";
            $format = 'lld';
            break;
            
        case 'config_function.list':
            // 설정 목록 조회 (JSON)
            $where = buildWhereClause($conn, $params);
            $query = "SELECT optionname, optiondata FROM configure_function" . $where;
            $format = 'json';
            break;
            
        case 'config_function.status':
            // 특정 설정 존재 확인
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT COUNT(*) as value FROM configure_function WHERE optionname = '$name'";
            $format = 'text';
            break;
            
        case 'config_function.data':
            // 특정 설정 값 조회
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT optiondata as value FROM configure_function WHERE optionname = '$name'";
            $format = 'text';
            break;
            
        // ================================================
        // configure_server 테이블
        // ================================================
        case 'config_server.discovery':
            // 서버 설정 목록 Discovery (LLD)
            $query = "SELECT optionname, optiondata FROM configure_server";
            $format = 'lld';
            break;
            
        case 'config_server.list':
            // 서버 설정 목록 조회 (JSON)
            $where = buildWhereClause($conn, $params);
            $query = "SELECT optionname, optiondata FROM configure_server" . $where;
            $format = 'json';
            break;
            
        case 'config_server.status':
            // 특정 서버 설정 존재 확인
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT COUNT(*) as value FROM configure_server WHERE optionname = '$name'";
            $format = 'text';
            break;
            
        case 'config_server.data':
            // 특정 서버 설정 값 조회
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT optiondata as value FROM configure_server WHERE optionname = '$name'";
            $format = 'text';
            break;
            
        // ================================================
        // configure_web 테이블
        // ================================================
        case 'config_web.discovery':
            // 웹 설정 목록 Discovery (LLD)
            $query = "SELECT optionname, optiondata FROM configure_web";
            $format = 'lld';
            break;
            
        case 'config_web.list':
            // 웹 설정 목록 조회 (JSON)
            $where = buildWhereClause($conn, $params);
            $query = "SELECT optionname, optiondata FROM configure_web" . $where;
            $format = 'json';
            break;
            
        case 'config_web.status':
            // 특정 웹 설정 존재 확인
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT COUNT(*) as value FROM configure_web WHERE optionname = '$name'";
            $format = 'text';
            break;
            
        case 'config_web.data':
            // 특정 웹 설정 값 조회
            if (empty($params['optionname'])) {
                echo "ERROR: optionname required";
                mysqli_close($conn);
                exit(1);
            }
            $name = mysqli_real_escape_string($conn, $params['optionname']);
            $query = "SELECT optiondata as value FROM configure_web WHERE optionname = '$name'";
            $format = 'text';
            break;
        
        // ================================================
        // 보안: 랜섬웨어 의심 파일 탐지 (file_info 테이블)
        // ================================================
        case 'security.ransomware_count':
            // 최근 30일 내 랜섬웨어 의심 파일 개수
            $query = "SELECT COUNT(*) as value 
                     FROM file_info fi
                     WHERE (
                         fi.Name LIKE '%readme%' 
                         OR fi.Name LIKE '%recover%' 
                         OR fi.Name LIKE '%restore%' 
                         OR fi.Name LIKE '%decrypt%' 
                         OR fi.Name LIKE '%encrypt%'
                     ) 
                     AND fi.State = '1' 
                     AND fi.CreateDateTime BETWEEN NOW() - INTERVAL 30 DAY AND NOW()";
            $format = 'text';
            break;
            
        case 'security.ransomware_list':
            // 랜섬웨어 의심 파일 목록 (최근 30일)
            // user_info, folder_info, folder_pos 테이블과 JOIN하여 전체 정보 구성
            // 서브쿼리를 JOIN으로 최적화
            
            // MySQL 타임아웃 설정 (30초)
            mysqli_query($conn, "SET SESSION wait_timeout = 30");
            mysqli_query($conn, "SET SESSION interactive_timeout = 30");
            
            $query = "SELECT 
                        fi.CreateDateTime AS Create_datetime,
                        IFNULL(ui.Name, '알 수 없음') AS Creator_name,
                        fi.Name AS File_name,
                        COALESCE(
                            GROUP_CONCAT(fo.Name ORDER BY fp.depth DESC SEPARATOR '/'),
                            '루트 폴더'
                        ) AS File_location
                    FROM file_info fi
                    LEFT JOIN user_info ui ON fi.CreateUserIndex = ui.UserIndex
                    LEFT JOIN folder_pos fp ON fi.FolderIndex = fp.ChildFolderIndex
                    LEFT JOIN folder_info fo ON fp.ParentFolderIndex = fo.FolderIndex
                    WHERE (
                        fi.Name LIKE '%readme%' 
                        OR fi.Name LIKE '%recover%' 
                        OR fi.Name LIKE '%restore%' 
                        OR fi.Name LIKE '%decrypt%' 
                        OR fi.Name LIKE '%encrypt%'
                    )
                    AND fi.State = '1'
                    AND fi.CreateDateTime BETWEEN NOW() - INTERVAL 30 DAY AND NOW()
                    GROUP BY fi.FileIndex, fi.CreateDateTime, ui.Name, fi.Name
                    ORDER BY fi.CreateDateTime DESC";
            $format = 'json';
            break;
        
        // ================================================
        // MySQL 시스템 정보
        // ================================================
        case 'mysql.connection_count':
            $query = "SELECT COUNT(*) as value FROM information_schema.PROCESSLIST";
            $format = 'text';
            break;
            
        case 'mysql.version':
            $query = "SELECT VERSION() as value";
            $format = 'text';
            break;
            
        case 'mysql.uptime':
            $query = "SHOW GLOBAL STATUS LIKE 'Uptime'";
            $format = 'text';
            break;
            
        default:
            echo "ERROR: Unknown metric '$metric'";
            mysqli_close($conn);
            exit(1);
    }
    
    $result = executeQuery($conn, $query);
    outputResult($result, $format);
    
    mysqli_close($conn);
}

// CLI에서 실행
if (php_sapi_name() === 'cli') {
    if ($argc < 2) {
        echo "Usage: php " . basename(__FILE__) . " <metric> [param1=value1] [param2=value2] ...\n\n";
        echo "=== server_info 테이블 ===\n";
        echo "  server.discovery              : 서버 목록 (LLD)\n";
        echo "  server.list                   : 서버 목록 (JSON)\n";
        echo "  server.status ServerIndex=N   : 서버 상태\n";
        echo "  server.ip ServerIndex=N       : 서버 IP\n\n";
        
        echo "=== path_info 테이블 ===\n";
        echo "  path.discovery                : 경로 목록 (LLD)\n";
        echo "  path.list                     : 경로 목록 (JSON)\n";
        echo "  path.status PathIndex=N       : 경로 상태\n";
        echo "  path.usesize PathIndex=N      : 사용량\n";
        echo "  path.quotasize PathIndex=N    : 할당량\n";
        echo "  path.usage_percent PathIndex=N: 사용률 (%)\n\n";
        
        echo "=== configure_function 테이블 ===\n";
        echo "  config_function.discovery     : 설정 목록 (LLD)\n";
        echo "  config_function.list          : 설정 목록 (JSON)\n";
        echo "  config_function.status optionname=XXX : 설정 상태\n";
        echo "  config_function.data optionname=XXX   : 설정 값\n\n";
        
        echo "=== configure_server 테이블 ===\n";
        echo "  config_server.discovery       : 서버 설정 목록 (LLD)\n";
        echo "  config_server.list            : 서버 설정 목록 (JSON)\n";
        echo "  config_server.status optionname=XXX : 설정 상태\n";
        echo "  config_server.data optionname=XXX   : 설정 값\n\n";
        
        echo "=== configure_web 테이블 ===\n";
        echo "  config_web.discovery          : 웹 설정 목록 (LLD)\n";
        echo "  config_web.list               : 웹 설정 목록 (JSON)\n";
        echo "  config_web.status optionname=XXX : 설정 상태\n";
        echo "  config_web.data optionname=XXX   : 설정 값\n\n";
        
        echo "=== 보안: 랜섬웨어 탐지 ===\n";
        echo "  security.ransomware_count     : 최근 30일 의심 파일 수\n";
        echo "  security.ransomware_list      : 의심 파일 목록 (생성자명, 파일위치 포함)\n\n";
        
        echo "=== WHERE 조건 예시 ===\n";
        echo "  php " . basename(__FILE__) . " server.list ServerIndex=1\n";
        echo "  php " . basename(__FILE__) . " path.list Name=backup\n";
        echo "  php " . basename(__FILE__) . " config_function.list optionname=port\n\n";
        
        exit(1);
    }
    
    $metric = $argv[1];
    $params = array();
    
    // 파라미터 파싱 (key=value 형식)
    for ($i = 2; $i < $argc; $i++) {
        if (strpos($argv[$i], '=') !== false) {
            list($key, $value) = explode('=', $argv[$i], 2);
            $params[trim($key)] = trim($value);
        }
    }
    
    main($metric, $params);
}
?>
