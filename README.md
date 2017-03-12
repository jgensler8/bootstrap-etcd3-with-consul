# bootstrap-etcd3-with-consul

Don't forget to read the blog article [located here](https://medium.com/@jeffzzq/bootstrapping-etcd3-with-consul-ded64d1bda93#.oxi2pfwdn)!

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
