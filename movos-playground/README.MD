# сценарии
+переключение при падении мастера
автоматически восстанавливаться после сбоев протестировать удаление ноды и её возвращение
+переезд на другую версию
+корраптинг даты на реплике - после удаления не отрабатывает - не может присоединиться, бесконечно пишет не могу постресу приконнектиться - надо удалить pvc сбойной реплики полностью, тогда создаст новую ноду и с ней восстановит
работоспособность, но после ещё надо нерабочий под удалить
при эвишшне мастера и дальнейшем восстановлении работоспособности он пытается скачать wal файлы с облака, а не восстановиться с реплики

сделать админа постгрес
+сделать разделение на зоны
сделать изменяемый конфиг с пользователями
+сделать пойнт ин тайм рекавери
увеличить размер диска(вообще как диски прописываются?)

# подготовка


# поднимаем кластер с обвязкой
k3d cluster delete cnpg && \
k3d cluster create cnpg \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer"\
  --k3s-arg "--disable=traefik@server:0" --agents 2  \
  --k3s-node-label "oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-2@agent:0" \
  --k3s-node-label "oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-3@agent:1"  \
  --k3s-node-label "oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-1@server:0" && \
      kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.25/releases/cnpg-1.25.1.yaml && \
      sleep 60 && \
          kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml && \
      sleep 120 && \
      kubectl apply -f https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.2.0/manifest.yaml
# запуск кластера
kubectl apply -f cnpg.yaml

$ kubectl get clusters
NAME                AGE   INSTANCES   READY   STATUS                     PRIMARY
cluster-balanced4   54m   2           2       Cluster in healthy state   cluster-balanced4-2

kubectl cnpg status cluster-balanced4 --verbose

свитч мастера

kubectl cnpg promote CLUSTER INSTANCE



$ kubectl cnpg promote cluster-balanced4 cluster-balanced4-3
{"level":"info","ts":"2025-03-13T12:46:04.503915822Z","msg":"Cluster has become unhealthy"}
Node cluster-balanced4-3 in cluster cluster-balanced4 will be promoted

this command will restart a whole cluster in a rollout fashion
kubectl cnpg restart CLUSTER

логи с кластера
kubectl cnpg logs cluster CLUSTERNAME
kubectl cnpg logs cluster CLUSTERNAME | kubectl cnpg logs pretty

бенчмаркинг
kubectl cnpg pgbench CLUSTER -- --time 30 --client 1 --jobs 1

получить бекап
kubectl cnpg backup CLUSTER

получить шелл psql
kubectl cnpg psql cluster-example

поменять ноду под подами можно закордонив ноду и удалив под с репликой cnpg

# обсервабилити:
[ -f /tmp/kubectlproxy.pid ] && kill $(cat /tmp/kubectlproxy.pid); kubectl proxy & echo $! > /tmp/kubectlproxy.pid && docker run -it --rm -e SERVER_PORT=8888 --net=host hjacobs/kub

смотреть через браузер на http://your_ip:8888

в теории есть ещё
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/prometheusrule.yaml


https://github.com/cloudnative-pg/grafana-dashboards/blob/main/charts/cluster/grafana-dashboard.json


# экперименты
k3d node delete k3d-cnpg-agent-1
k delete node k3d-cnpg-agent-1
k3d node create agent-1 --cluster cnpg --role agent

kubectl label node -l kubernetes.io/hostname=k3d-k3d-cnpg-agent-0-0 oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-3 --overwrite
kubectl label node -l kubernetes.io/name=k3d-newnode-0 oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-3 --overwrite

kubectl run t1 --rm -i --tty --image arunvelsriram/utils


for env in `seq 1 1000`
do
echo attempt $env
pg_isready -h cluster-balanced4-rw
sleep 2
done

CREATE TABLE date_logs (
    id SERIAL PRIMARY KEY,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Поле с датой и временем
    description TEXT
);

INSERT INTO date_logs (description)
VALUES ('Тестовая запись');


SELECT * FROM date_logs;

читать данные писать данные




Если версии не обновляются напрямую, то перед установкой новой версии необходимо удалить старую. Это не повлияет на пользовательские данные, а только на сам оператор.
https://cloudnative-pg.io/documentation/current/installation_upgrade/





s3cmd --access_key=b5454811787c78fcf21356521f0b00fc36ac8e4a --secret_key="KEiMSkJuViv3Hzq310tUdjYOjB/5766j/vF1Q+OoK0c=" \
--host=zratzwdrr5mk.compat.objectstorage.eu-zurich-1.oraclecloud.com ls s3://movos-development-backups_postgresql/




настройте enableSuperuserAccess и укажите superuserSecret.












# дополнения
10.0.91.204   Ready    node    77d   v1.31.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=VM.Standard.E4.Flex,beta.kubernetes.io/os=linux,displayName=oke-cch66mvinca-nxmz2vdqgpq-stothse4kpa-2,failure-domain.beta.kubernetes.io/region=eu-zurich-1,failure-domain.beta.kubernetes.io/zone=EU-ZURICH-1-AD-1,hostname=oke-cch66mvinca-nxmz2vdqgpq-stothse4kpa-2,internal_addr=10.0.91.204,kubernetes.io/arch=amd64,kubernetes.io/hostname=10.0.91.204,kubernetes.io/os=linux,last-migration-failure=get_kubesvc_failure,name=update131,node-role.kubernetes.io/node=,node.info.ds_proxymux_client=true,node.info/compartment.name=movos-development,node.info/kubeletVersion=v1.31,node.kubernetes.io/instance-type=VM.Standard.E4.Flex,oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-3,oci.oraclecloud.com/ip-family-ipv4=true,oci.oraclecloud.com/ip-family-preferred=ipv4,oci.oraclecloud.com/node.info.managed=true,oci.oraclecloud.com/vcn-native-ip-cni=true,oke.oraclecloud.com/node.info.private_subnet=true,oke.oraclecloud.com/node.info.private_worker=true,topology.kubernetes.io/region=eu-zurich-1,topology.kubernetes.io/zone=EU-ZURICH-1-AD-1
10.0.92.86    Ready    node    77d   v1.31.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=VM.Standard.E4.Flex,beta.kubernetes.io/os=linux,displayName=oke-cch66mvinca-nxmz2vdqgpq-stothse4kpa-5,failure-domain.beta.kubernetes.io/region=eu-zurich-1,failure-domain.beta.kubernetes.io/zone=EU-ZURICH-1-AD-1,hostname=oke-cch66mvinca-nxmz2vdqgpq-stothse4kpa-5,internal_addr=10.0.92.86,kubernetes.io/arch=amd64,kubernetes.io/hostname=10.0.92.86,kubernetes.io/os=linux,last-migration-failure=get_kubesvc_failure,name=update131,node-role.kubernetes.io/node=,node.info.ds_proxymux_client=true,node.info/compartment.name=movos-development,node.info/kubeletVersion=v1.31,node.kubernetes.io/instance-type=VM.Standard.E4.Flex,oci.oraclecloud.com/fault-domain=FAULT-DOMAIN-3,oci.oraclecloud.com/ip-family-ipv4=true,oci.oraclecloud.com/ip-family-preferred=ipv4,oci.oraclecloud.com/node.info.managed=true,oci.oraclecloud.com/vcn-native-ip-cni=true,oke.oraclecloud.com/node.info.private_subnet=true,oke.oraclecloud.com/node.info.private_worker=true,topology.kubernetes.io/region=eu-zurich-1,topology.kubernetes.io/zone=EU-ZURICH-1-AD-1
