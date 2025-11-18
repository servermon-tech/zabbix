#!/bin/bash
#
# 랜섬웨어 쿼리 직접 테스트 스크립트
#

echo "=========================================="
echo "랜섬웨어 쿼리 직접 테스트"
echo "=========================================="
echo ""

# DB 접속 정보 (zabbix_db_config.php에서 가져오기)
DB_HOST="localhost"
DB_USER="root"
DB_NAME="estsoft"

echo "DB 접속 정보:"
echo "  Host: $DB_HOST"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo ""

# 1. 간단한 카운트 테스트
echo "=========================================="
echo "1. 의심 파일 개수 (간단한 쿼리)"
echo "=========================================="
mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_NAME" <<'EOF'
SELECT COUNT(*) as count
FROM file_info fi
WHERE (
    fi.Name LIKE '%readme%' 
    OR fi.Name LIKE '%recover%' 
    OR fi.Name LIKE '%restore%' 
    OR fi.Name LIKE '%decrypt%' 
    OR fi.Name LIKE '%encrypt%'
)
AND fi.State = '1'
AND fi.CreateDateTime BETWEEN NOW() - INTERVAL 30 DAY AND NOW();
EOF
echo ""

# 2. JOIN 없이 파일 목록만
echo "=========================================="
echo "2. 파일 목록 (JOIN 없음)"
echo "=========================================="
mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_NAME" <<'EOF'
SELECT 
    fi.CreateDateTime,
    fi.Name,
    fi.CreateUserIndex,
    fi.FolderIndex
FROM file_info fi
WHERE (
    fi.Name LIKE '%readme%' 
    OR fi.Name LIKE '%recover%' 
    OR fi.Name LIKE '%restore%' 
    OR fi.Name LIKE '%decrypt%' 
    OR fi.Name LIKE '%encrypt%'
)
AND fi.State = '1'
AND fi.CreateDateTime BETWEEN NOW() - INTERVAL 30 DAY AND NOW()
ORDER BY fi.CreateDateTime DESC
LIMIT 10;
EOF
echo ""

# 3. user_info JOIN만
echo "=========================================="
echo "3. 사용자 정보 JOIN"
echo "=========================================="
mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_NAME" <<'EOF'
SELECT 
    fi.CreateDateTime,
    IFNULL(ui.Name, '알 수 없음') AS Creator_name,
    fi.Name AS File_name
FROM file_info fi
LEFT JOIN user_info ui ON fi.CreateUserIndex = ui.UserIndex
WHERE (
    fi.Name LIKE '%readme%' 
    OR fi.Name LIKE '%recover%' 
    OR fi.Name LIKE '%restore%' 
    OR fi.Name LIKE '%decrypt%' 
    OR fi.Name LIKE '%encrypt%'
)
AND fi.State = '1'
AND fi.CreateDateTime BETWEEN NOW() - INTERVAL 30 DAY AND NOW()
ORDER BY fi.CreateDateTime DESC
LIMIT 10;
EOF
echo ""

# 4. 최적화된 전체 쿼리 (GROUP BY 사용)
echo "=========================================="
echo "4. 최적화된 전체 쿼리"
echo "=========================================="
echo "실행 시간 측정 중..."
time mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_NAME" <<'EOF'
SELECT 
    fi.CreateDateTime AS Create_datetime,
    IFNULL(ui.Name, '알 수 없음') AS Creator_name,
    fi.Name AS File_name,
    IFNULL(
        GROUP_CONCAT(DISTINCT fo.Name ORDER BY fp.id SEPARATOR '/'),
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
ORDER BY fi.CreateDateTime DESC
LIMIT 10;
EOF
echo ""

# 5. PHP 스크립트 테스트
echo "=========================================="
echo "5. PHP 스크립트 테스트"
echo "=========================================="
echo "$ php zabbix_db_query.php security.ransomware_list"
php zabbix_db_query.php security.ransomware_list
echo ""

# 6. ecm.sh 스크립트 테스트
echo "=========================================="
echo "6. ecm.sh 스크립트 테스트"
echo "=========================================="
echo "$ ./ecm.sh security.ransomware_count"
./ecm.sh security.ransomware_count
echo ""

echo "$ ./ecm.sh security.ransomware_list"
./ecm.sh security.ransomware_list | head -20
echo ""

echo "=========================================="
echo "테스트 완료"
echo "=========================================="

