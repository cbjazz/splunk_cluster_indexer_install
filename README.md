Splunk Indexer Cluster 자동 인스톨 스크립트

사전 요구 사항: 
    리눅스 (레드햇) 계열에서만 설치 테스트 함 .
    expect 가 설치되어 있어야 함 : $ yum install expect -y
    마스터가 설치되는 호스트의 설치 계정 ssh pub키가 공유되어 있어야 함. 
    Splunk license server 는 미리 설치 되어 있어야 함.
    호스트의 시스템 limit 설정은 미리 되어 있어야 함.
    설치해야 하는 폴더에 설치 계정에 접근 권한이 있어야 함.

설치 방법: 
    인스톨 파일의 ./resources 폴더에 설치할 버전의 splunk 압축파일을 넣어준다. (splunk-xxxxx.tar.gz)
    ./conf/hosts.conf 에 설치할 마스터/인덱서 호스트 명을 입력한다. 
    ./conf/splunk_install.conf 에 설치에 필요한 옵션을 넣어준다. 
    ./bin/splunk_install.sh [admin_password] [설치 옵션] 을 실행한다. 
        - 설치 옵션 : ALL (마스터/인덱서 모두 설치) 
                    : MASTER (마스터만 설치)
                    : INDEXER (인덱서만 설치한다. 단 master는 미리 설치되어 있어야 한다)
        - 설치 후에는 admin:[admin_password] 로 관리자 계정이 생성된다. 
    설치되는 인덱서의 갯수는 [hosts.conf에 INDEXER 에 설정되 호스트 갯수] * [splunk_install.conf 에 indexer_dir 갯수] 이다. 
        - 모든 indexer 호스트에는 같은 갯수의 indexer instance 들이 설치 된다. 

그 외: 
    ./bin/splunk_setup_util 을 통해 클러스터에 등록하기 위한 도움 파일을 얻을 수 있다.
        - ./bin/splunk_setup_util output : Cluster 에 데이터를 전달하기 위한 outputs.conf 입력 설정을 가져온다. 
        - ./bin/splunk_setup_util register : Search Head 가 Cluster에 등록하기 위한 명령 구문을 가져온다. 

