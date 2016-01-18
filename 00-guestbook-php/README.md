# Guestbook PHP

From the [kubernetes repository examples](https://github.com/kubernetes/kubernetes/blob/release-1.1/examples/guestbook/README.md)

## Components

### Redis Master Replication Controller / Pod

```bash
kubectl create -f 0-redis-master-controller.yaml
```

Check that it's working

We'll use three commands for that

    kubectl get po           # Gets all pods within the `default` namespace
    kubectl logs <pod_name>  # Gets the container logs for pod <pod_name>
    kubectl get rc           # Gets all replication controllers within the `default` namespace

```bash
$ kubectl get po
NAME                 READY     STATUS    RESTARTS   AGE
redis-master-fn9ss   0/1       Pending   0          19s

$ kubectl logs redis-master-fn9ss
1:C 14 Jan 07:40:48.010 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 3.0.6 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

1:M 14 Jan 07:40:48.015 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
1:M 14 Jan 07:40:48.015 # Server started, Redis version 3.0.6

$ kubectl get rc
CONTROLLER     CONTAINER(S)   IMAGE(S)   SELECTOR            REPLICAS   AGE
redis-master   master         redis      name=redis-master   1          1m
```

If you need more information you can work with the `describe` command. This is useful for knowing in which physical node we are running our pod

```bash
$ kubectl describe po redis-master-fn9ss
Name:				redis-master-fn9ss
Namespace:			default
Image(s):			redis
Node:				104.131.X.Y/104.131.X.Y
Start Time:			Thu, 14 Jan 2016 07:36:49 +0000
Labels:				name=redis-master
Status:				Running
Reason:
Message:
IP:				10.2.3.2
Replication Controllers:	redis-master (1/1 replicas created)
Containers:
  master:
    Container ID:	docker://3962b74f178a138539bd860d4cd9314dde9b73b6788fc57b8899a6017fadf00f
    Image:		redis
    Image ID:		docker://8bccd73928d93c54f3f5e1638a8f45d2cc359f2c3697a5ee6f62e12b4f3049fb
    State:		Running
      Started:		Thu, 14 Jan 2016 07:40:47 +0000
    Ready:		True
    Restart Count:	0
    Environment Variables:
Conditions:
  Type		Status
  Ready 	True
Volumes:
  default-token-lrl9j:
    Type:	Secret (a secret that should populate this volume)
    SecretName:	default-token-lrl9j
Events:
  FirstSeen	LastSeen	Count	From				SubobjectPath				Reason		Message
  ─────────	────────	─────	────				─────────────				──────		───────
  9m		9m		1	{scheduler }								Scheduled	Successfully assigned redis-master-fn9ss to 104.131.X.Y
  9m		6m		2	{kubelet 104.131.X.Y}	implicitly required container POD	Pulling		Pulling image "gcr.io/google_containers/pause:0.8.0"
  6m		6m		1	{kubelet 104.131.X.Y}	implicitly required container POD	Created		Created with docker id a21cd7a196e8
  6m		6m		1	{kubelet 104.131.X.Y}	implicitly required container POD	Pulled		Successfully pulled image "gcr.io/google_containers/pause:0.8.0"
  6m		6m		1	{kubelet 104.131.X.Y}	implicitly required container POD	Started		Started with docker id a21cd7a196e8
  6m		6m		1	{kubelet 104.131.X.Y}	spec.containers{master}			Pulling		Pulling image "redis"
  5m		5m		1	{kubelet 104.131.X.Y}	spec.containers{master}			Pulled		Successfully pulled image "redis"
  5m		5m		1	{kubelet 104.131.X.Y}	spec.containers{master}			Created		Created with docker id 3962b74f178a
  5m		5m		1	{kubelet 104.131.X.Y}	spec.containers{master}			Started		Started with docker id 3962b74f178a
```

### Redis Master Service

```bash
kubectl create -f 1-redis-master-service.yaml
```

And the checks

```bash
$ kubectl get svc
NAME           CLUSTER_IP   EXTERNAL_IP   PORT(S)    SELECTOR            AGE
kubernetes     11.1.2.1     <none>        443/TCP    <none>              24m
redis-master   11.1.2.87    <none>        6379/TCP   name=redis-master   8s
```

For more info on the service

```bash
$ kubectl describe svc redis-master
Name:			redis-master
Namespace:		default
Labels:			name=redis-master
Selector:		name=redis-master
Type:			ClusterIP
IP:			11.1.2.87
Port:			<unnamed>	6379/TCP
Endpoints:		10.2.3.2:6379
Session Affinity:	None
No events.
```

Let's try to talk with redis from one of our worker hosts. First we will get into the host which is running the node.

```bash
$ ssh core@104.131.X.Y
authenticity of host '104.131.X.Y (104.131.X.Y)' can't be established.
ED25519 key fingerprint is 53:5f:3d:81:63:46:b3:42:57:d1:90:64:6e:7e:5a:b7.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '104.131.X.Y' (ED25519) to the list of known hosts.
Last login: Thu Jan 14 07:35:30 2016 from 201.x.x.x
CoreOS stable (835.9.0)

core@k8s-worker-02 ~ $ ncat 11.1.2.87 6379
PING
+PONG
^C

core@k8s-worker-02 ~ $ exit
```

What we just did was connecting to the IP assigned to the service, using the port `6379` (the redis one), and send a `PING` command. We found success.

Let's try the same, this time, from another host.

```bash
$ kubectl get no
NAME          LABELS                               STATUS    AGE
104.131.X.Y   kubernetes.io/hostname=104.131.X.Y   Ready     24m
104.131.Z.S   kubernetes.io/hostname=104.131.Z.S   Ready     24m
104.131.T.U   kubernetes.io/hostname=104.131.T.U   Ready     24m
159.203.V.W   kubernetes.io/hostname=159.203.V.W   Ready     27m

$ ssh core@104.131.Z.S
[...]

core@k8s-worker-02 ~ $ ncat 11.1.2.87 6379
PING
+PONG
^C

core@k8s-worker-02 ~ $ exit
```

So, our service is accesible from all pods.

## Redis Slave Replication Controller / Pods

```bash
kubectl create -f 2-redis-slave-controller.yaml
```

Will set up two pods running slaves. If we get the logs of one of them (previous identifying its names with `kubectl get po`), we get

```bash
$ kubectl logs redis-slave-gytgu
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 3.0.3 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 6
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

6:S 14 Jan 09:35:48.039 # Server started, Redis version 3.0.3
6:S 14 Jan 09:35:48.042 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
6:S 14 Jan 09:35:48.042 * The server is now ready to accept connections on port 6379
6:S 14 Jan 09:35:49.008 * Connecting to MASTER redis-master:6379
6:S 14 Jan 09:35:49.047 * MASTER <-> SLAVE sync started
6:S 14 Jan 09:35:49.048 * Non blocking connect for SYNC fired the event.
6:S 14 Jan 09:35:49.049 * Master replied to PING, replication can continue...
6:S 14 Jan 09:35:49.050 * Partial resynchronization not possible (no cached master)
6:S 14 Jan 09:35:49.052 * Full resync from master: 987ef978d0c92308af7560c3cf0de5b91aef38a3:15
6:S 14 Jan 09:35:49.169 * MASTER <-> SLAVE sync: receiving 18 bytes from master
6:S 14 Jan 09:35:49.170 * MASTER <-> SLAVE sync: Flushing old data
6:S 14 Jan 09:35:49.170 * MASTER <-> SLAVE sync: Loading DB in memory
6:S 14 Jan 09:35:49.170 * MASTER <-> SLAVE sync: Finished with success
```

As we can note above, slaves connect with master using the latter's domain name. we can get curious and run

```bash
$ kubectl exec -ti redis-slave-gytgu ping redis-master
PING redis-master.default.svc.cluster.local (11.1.2.103): 48 data bytes
36 bytes from 162.243.188.229: Destination Net Unreachable

$ kubectl exec redis-slave-gytgu cat /etc/resolv.conf
nameserver 11.1.2.10
nameserver 8.8.8.8
nameserver 8.8.4.4
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

So, the DNS service works in `11.1.2.10`, resolving for the name of service (`redis-master`) to the service special IP.

What about that `Destination Net Unreachable`?

The answer is that the route is assigned using some `iptables` magic. You can check what is being done logging into any of the servers

```bash
$ ssh core@104.131.Z.S
[...]

core@k8s-worker-03 ~ $ sudo iptables-save
# Generated by iptables-save v1.4.21 on Thu Jan 14 09:53:03 2016
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:DOCKER - [0:0]
:FLANNEL - [0:0]
:KUBE-NODEPORTS - [0:0]
:KUBE-SEP-4D7LXDQULJQOKIME - [0:0]
:KUBE-SEP-5TSJG2PSL7JQH5EN - [0:0]
:KUBE-SEP-GRMMPLZHGF4KWEVC - [0:0]
:KUBE-SEP-JKETJUWNZ2DR6FKZ - [0:0]
:KUBE-SERVICES - [0:0]
:KUBE-SVC-6N4SJQIF3IX3FORG - [0:0]
:KUBE-SVC-7GF4BJM3Z6CMNVML - [0:0]
:KUBE-SVC-ERIFXISQEP7F7OF4 - [0:0]
:KUBE-SVC-TCOU7JCQXEZGVUNU - [0:0]
-A PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -s 10.2.0.0/16 -j FLANNEL
-A POSTROUTING ! -s 10.2.0.0/16 -d 10.2.0.0/16 -j MASQUERADE
-A POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4d415351 -j MASQUERADE
-A FLANNEL -d 10.2.0.0/16 -j ACCEPT
-A FLANNEL ! -d 224.0.0.0/4 -j MASQUERADE
-A KUBE-SEP-4D7LXDQULJQOKIME -s 159.203.72.124/32 -m comment --comment "default/kubernetes:" -j MARK --set-xmark 0x4d415351/0xffffffff
-A KUBE-SEP-4D7LXDQULJQOKIME -p tcp -m comment --comment "default/kubernetes:" -m tcp -j DNAT --to-destination 159.203.72.124:443
-A KUBE-SEP-5TSJG2PSL7JQH5EN -s 10.2.6.2/32 -m comment --comment "kube-system/kube-dns:dns" -j MARK --set-xmark 0x4d415351/0xffffffff
-A KUBE-SEP-5TSJG2PSL7JQH5EN -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 10.2.6.2:53
-A KUBE-SEP-GRMMPLZHGF4KWEVC -s 10.2.6.2/32 -m comment --comment "kube-system/kube-dns:dns-tcp" -j MARK --set-xmark 0x4d415351/0xffffffff
-A KUBE-SEP-GRMMPLZHGF4KWEVC -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp" -m tcp -j DNAT --to-destination 10.2.6.2:53
-A KUBE-SEP-JKETJUWNZ2DR6FKZ -s 10.2.3.2/32 -m comment --comment "default/redis-master:" -j MARK --set-xmark 0x4d415351/0xffffffff
-A KUBE-SEP-JKETJUWNZ2DR6FKZ -p tcp -m comment --comment "default/redis-master:" -m tcp -j DNAT --to-destination 10.2.3.2:6379
-A KUBE-SERVICES -d 11.1.2.10/32 -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp cluster IP" -m tcp --dport 53 -j KUBE-SVC-ERIFXISQEP7F7OF4
-A KUBE-SERVICES -d 11.1.2.87/32 -p tcp -m comment --comment "default/redis-master: cluster IP" -m tcp --dport 6379 -j KUBE-SVC-7GF4BJM3Z6CMNVML
-A KUBE-SERVICES -d 11.1.2.1/32 -p tcp -m comment --comment "default/kubernetes: cluster IP" -m tcp --dport 443 -j KUBE-SVC-6N4SJQIF3IX3FORG
-A KUBE-SERVICES -d 11.1.2.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-SVC-TCOU7JCQXEZGVUNU
-A KUBE-SERVICES -m comment --comment "kubernetes service nodeports; NOTE: this must be the last rule in this chain" -m addrtype --dst-type LOCAL -j KUBE-NODEPORTS
-A KUBE-SVC-6N4SJQIF3IX3FORG -m comment --comment "default/kubernetes:" -j KUBE-SEP-4D7LXDQULJQOKIME
-A KUBE-SVC-7GF4BJM3Z6CMNVML -m comment --comment "default/redis-master:" -j KUBE-SEP-JKETJUWNZ2DR6FKZ
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-SEP-GRMMPLZHGF4KWEVC
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns" -j KUBE-SEP-5TSJG2PSL7JQH5EN
COMMIT
# Completed on Thu Jan 14 09:53:03 2016
# Generated by iptables-save v1.4.21 on Thu Jan 14 09:53:03 2016
*filter
:INPUT ACCEPT [42414:358969297]
:FORWARD ACCEPT [3:180]
:OUTPUT ACCEPT [30172:2964248]
:DOCKER - [0:0]
-A FORWARD -o docker0 -j DOCKER
-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i docker0 ! -o docker0 -j ACCEPT
-A FORWARD -i docker0 -o docker0 -j ACCEPT
COMMIT
# Completed on Thu Jan 14 09:53:03 2016
```

There you are, the relevant line is

```bash
-A KUBE-SERVICES -d 11.1.2.87/32 -p tcp -m comment --comment "default/redis-master: cluster IP" -m tcp --dport 6379 -j KUBE-SVC-7GF4BJM3Z6CMNVML
```

If you follow the targets (hint: last element), you will arrive toi

```bash
-A KUBE-SEP-JKETJUWNZ2DR6FKZ -p tcp -m comment --comment "default/redis-master:" -m tcp -j DNAT --to-destination 10.2.3.2:6379
```

Which is the Network address translation.

### Redis Slave Service

```bash
kubectl create -f 3-redis-slave-service.yaml
```

### Frontend Replication Controller

```bash
kubectl create -f 4-frontend-controller.yaml
```

Checking

```bash
$ kubectl describe rc frontend
Name:		frontend
Namespace:	default
Image(s):	gcr.io/google_samples/gb-frontend:v3
Selector:	name=frontend
Labels:		name=frontend
Replicas:	3 current / 3 desired
Pods Status:	3 Running / 0 Waiting / 0 Succeeded / 0 Failed
No volumes.
Events:
  FirstSeen	LastSeen	Count	From				SubobjectPath	Reason			Message
  ─────────	────────	─────	────				─────────────	──────			───────
  2m		2m		1	{replication-controller }			SuccessfulCreate	Created pod: frontend-uweel
  2m		2m		1	{replication-controller }			SuccessfulCreate	Created pod: frontend-mbe2s
  2m		2m		1	{replication-controller }			SuccessfulCreate	Created pod: frontend-9gtfn
```

### Frontend Service

```bash
kubectl create -f 5-frontend-service.yaml
```

Querying the services

```bash
 kubectl get svc
NAME           CLUSTER_IP   EXTERNAL_IP   PORT(S)    SELECTOR            AGE
frontend       11.1.2.62    <none>        80/TCP     name=frontend       48s
kubernetes     11.1.2.1     <none>        443/TCP    <none>              29m
redis-master   11.1.2.87    <none>        6379/TCP   name=redis-master   23m
redis-slave    11.1.2.124   <none>        6379/TCP   name=redis-slave    23m
```

And let's try the application _inside the cluster_

```bash
$ ssh core@104.131.X.Y

core@k8s-master ~ $ curl http://11.1.2.62
<html ng-app="redis">
  <head>
    <title>Guestbook</title>
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.2.12/angular.min.js"></script>
    <script src="controllers.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/angular-ui-bootstrap/0.13.0/ui-bootstrap-tpls.js"></script>
  </head>
  <body ng-controller="RedisCtrl">
    <div style="width: 50%; margin-left: 20px">
      <h2>Guestbook</h2>
    <form>
    <fieldset>
    <input ng-model="msg" placeholder="Messages" class="form-control" type="text" name="input"><br>
    <button type="button" class="btn btn-primary" ng-click="controller.onRedis()">Submit</button>
    </fieldset>
    </form>
    <div>
      <div ng-repeat="msg in messages track by $index">
        {{msg}}
      </div>
    </div>
    </div>
  </body>
</html>
```

## Exposing your application to the world

So far, we learned how to run an application in a Kubernetes cluster, but we want to show the world what we done, i.e. We want to expose the `frontend` service.

There is no a single `right way` to do this. For this tutorial, we'll use the experimental feature `Ingress`. Please see [this link](https://github.com/kubernetes/kubernetes/blob/master/docs/user-guide/ingress.md).

### Nginx Ingress Controller

To understand better controllers, please [read this link](https://github.com/kubernetes/contrib/blob/master/Ingress/controllers/README.md).

Basically, an Ingress Controller will interact with the ApiServer's `/ingresses` endpoint and satisfy those requirements. In other words, once you set up this controller, all you must care about is updating the to the right ingress requirements, for example, "I want to map the route `/foo` to the service `foo_frontend`".

In order to know which IP we will use as our external IP, let's get our nodes

```bash
$ kubectl get no
NAME          LABELS                               STATUS    AGE
104.131.X.Y   kubernetes.io/hostname=104.131.X.Y   Ready     24m
104.131.Z.S   kubernetes.io/hostname=104.131.Z.S   Ready     24m
104.131.T.U   kubernetes.io/hostname=104.131.T.U   Ready     24m
159.203.V.W   kubernetes.io/hostname=159.203.V.W   Ready     27m
```

and label one of them as the `ingress node`

```bash
$ kubecl label no 104.131.Z.S role=ingress-node

$ kubectl get no
NAME          LABELS                                                   STATUS    AGE
104.131.X.Y   kubernetes.io/hostname=104.131.X.Y                       Ready     24m
104.131.Z.S   kubernetes.io/hostname=104.131.Z.S, role=ingress-node    Ready     24m
104.131.T.U   kubernetes.io/hostname=104.131.T.U                       Ready     24m
159.203.V.W   kubernetes.io/hostname=159.203.V.W                       Ready     27m
```

This `role` `label` we added enables us to tell Kubernetes to deploy our container in that node. Check the value in `nodeSelector` in the file `6-nginx-ingress-controller.yaml`.

To deploy

```bash
kubectl create -f 6-nginx-ingress-controller.yaml
```

We can check several things

```bash
$ kubectl get po -o wide
NAME                  READY     STATUS    RESTARTS   AGE       NODE
...
nginx-ingress-d0fk4   0/1       Pending   0          21s       104.131.Z.S
...
```

The pod is running in the specified node.

```bash
$ kubectl exec -ti nginx-ingress-d0fk4 cat nginx.conf

events {
  worker_connections 1024;
}
http {
}
```

As there is not an `Ingress` resource deployed, nginx doesn't have anything in its configuration.

### Ingress Resource

```bash
kubectl create -f 7-ingress.yaml
```

(TODO: Check nginx.conf)

(TODO: Do the curl)

