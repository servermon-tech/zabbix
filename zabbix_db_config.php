<?php
/**
 * Zabbix용 데이터베이스 설정
 * PHP 5.6+, 7.x, 8.x 호환
 * 
 * =============================================================================
 * DB 사용자 생성 방법 (MySQL/MariaDB)
 * =============================================================================
 * 
 * 1. MySQL/MariaDB 접속:
 *    mysql -u root -p
 * 
 * 2. 데이터베이스 생성 (없는 경우):
 *    CREATE DATABASE IF NOT EXISTS estsoft CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
 * 
 * 3. 사용자 생성 및 권한 부여:
 *    -- 로컬 접속만 허용 (권장)
 *    CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'strong_password_here';
 *    GRANT SELECT ON estsoft.* TO 'zabbix'@'localhost';
 * 
 *    -- 원격 접속 허용 (필요시)
 *    CREATE USER 'zabbix'@'%' IDENTIFIED BY 'strong_password_here';
 *    GRANT SELECT ON estsoft.* TO 'zabbix'@'%';
 * 
 * 4. 특정 테이블만 권한 부여 (보안 강화):
 *    GRANT SELECT ON estsoft.server_info TO 'zabbix'@'localhost';
 *    GRANT SELECT ON estsoft.path_info TO 'zabbix'@'localhost';
 *    GRANT SELECT ON estsoft.configure_function TO 'zabbix'@'localhost';
 *    GRANT SELECT ON estsoft.configure_server TO 'zabbix'@'localhost';
 *    GRANT SELECT ON estsoft.file_info TO 'zabbix'@'localhost';
 * 
 * 5. 권한 적용:
 *    FLUSH PRIVILEGES;
 * 
 * 6. 사용자 확인:
 *    SELECT user, host FROM mysql.user WHERE user = 'zabbix';
 *    SHOW GRANTS FOR 'zabbix'@'localhost';
 * 
 * 7. 접속 테스트:
 *    mysql -u zabbix -p estsoft
 *    SELECT * FROM server_info LIMIT 1;
 * 
 * =============================================================================
 * 자동 생성 스크립트:
 *    mysql -u root -p < create_db_user.sql
 * 
 * 보안 권장사항:
 * - SELECT 권한만 부여 (INSERT, UPDATE, DELETE 권한 불필요)
 * - 가능하면 localhost 접속만 허용
 * - 강력한 패스워드 사용 (최소 16자 이상, 특수문자 포함)
 * - 이 파일의 권한을 600으로 설정: chmod 600 zabbix_db_config.php
 * =============================================================================
 */

// 데이터베이스 접속 정보
define('DB_HOST', 'localhost');           // DB 서버 주소
define('DB_PORT', '3306');                // DB 포트
define('DB_NAME', 'estsoft');             // 데이터베이스명
define('DB_USER', 'zabbix');              // DB 사용자명
define('DB_PASSWORD', 'zabbix');    // DB 패스워드

// Zabbix 출력 형식 (기본값)
define('OUTPUT_FORMAT', 'json');

/**
 * 패스워드 변경 방법:
 * 
 * ALTER USER 'zabbix_user'@'localhost' IDENTIFIED BY 'new_strong_password';
 * FLUSH PRIVILEGES;
 */


