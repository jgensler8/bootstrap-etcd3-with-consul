# pod2consul

## Vagrant Simulation

### Steps

1. Edit `generate-cloud-configs.sh`
2. Run `generate-cloud-configs.sh`
3. Run `vagrant up`

## Docker Compose Simulation (broken)

1. `docker-compose up socat consul consul-agent`
2. Send POST request to consul
  ```
  {
    "ID": "etcd3-0",
    "Name": "etcd3",
    "Service": "etcd-registration",
    "Tags": [
      "_etcd-server._tcp.mycluster"
    ],
    "Address": "192.168.65.2",
    "Port": 2380
  }
  ```
3. `docker-compose up etcd3-0`
