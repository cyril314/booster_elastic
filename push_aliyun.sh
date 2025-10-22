#!/bin/bash
TAG=$1
PWD=$2
echo "正在使用标签: $TAG"

docker images

docker login --username=imocence --password=$PWD registry.cn-hongkong.aliyuncs.com

if [ $? -ne 0 ]; then
  echo "登录失败，请检查用户名或密码。"
  exit 1
fi

ELK="docker.elastic.co"
ALIYUN_REGISTRY="registry.cn-hongkong.aliyuncs.com/booster/elastic"

IMAGES=("elasticsearch" "kibana" "logstash" "elastic-agent" "filebeat" "heartbeat" "metricbeat" "enterprise-search")

for IMAGE in "${IMAGES[@]}"; do
    LOCAL_IMAGE="$ELK/$IMAGE/$IMAGE:$TAG"  # 本地镜像名称
    case $IMAGE in
        "elasticsearch")
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:e_$TAG"
            ;;
        "kibana")
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:k_$TAG"
            ;;
        "logstash")
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:l_$TAG"
            ;;
        "elastic-agent")
            LOCAL_IMAGE="$ELK/beats/$IMAGE:$TAG"
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:ea_$TAG"
            ;;
        "filebeat")
            LOCAL_IMAGE="$ELK/beats/$IMAGE:$TAG"
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:fb_$TAG"
            ;;
        "heartbeat")
            LOCAL_IMAGE="$ELK/beats/$IMAGE:$TAG"
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:hb_$TAG"
            ;;
        "metricbeat")
            LOCAL_IMAGE="$ELK/beats/$IMAGE:$TAG"
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:mb_$TAG"
            ;;
        "enterprise-search")
            LOCAL_IMAGE="$ELK/$IMAGE/$IMAGE:$TAG"
            ALIYUN_IMAGE="$ALIYUN_REGISTRY:es_$TAG"
            ;;
        *)
            echo "未知镜像: $IMAGE"
            continue
            ;;
    esac
    docker pull $LOCAL_IMAGE
    # 检查镜像是否存在
    if docker image inspect $LOCAL_IMAGE > /dev/null 2>&1; then
        echo "镜像 $LOCAL_IMAGE 存在，正在重新标记..."
        # 给镜像打上新的标签
        docker tag $LOCAL_IMAGE $ALIYUN_IMAGE

        # 推送镜像到阿里云
        echo "正在推送镜像 $ALIYUN_IMAGE 到阿里云..."
        docker push $ALIYUN_IMAGE
        echo "镜像 $LOCAL_IMAGE 已成功上传到 $ALIYUN_IMAGE"
    else
        echo "错误：镜像 $LOCAL_IMAGE 不存在！"
    fi
done
