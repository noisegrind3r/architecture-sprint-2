#!/bin/bash

echo "Starting initialize"
until mongosh --host configSrv --port 27017 --eval "print(\"waited for connection\")"
do
    sleep 2
done
echo "Connection finished"
echo "Creating replica set"
mongosh --host configSrv --port 27017 <<EOF
  rs.initiate(
    {
      _id : "config_server",
        configsvr: true,
      members: [
        { _id : 0, host : "configSrv:27017" }
      ]
    }
  );
  exit();
EOF

until mongosh --host shard1_1 --port 27017 --eval "print(\"waited for connection\")"
do
    sleep 2
done
echo "Connection finished"
echo "Creating replica set"
mongosh --host shard1_1 --port 27017 <<EOF
  rs.initiate(
      {
        _id : "shard1",
        members: [
          { _id : 0, host : "shard1_1:27017" },
          { _id : 1, host : "shard1_2:27017" },
          { _id : 2, host : "shard1_3:27017" }
        ]
      }
  );
  exit();
EOF

until mongosh --host shard2_1 --port 27017 --eval "print(\"waited for connection\")"
do
    sleep 2
done
echo "Connection finished"
echo "Creating replica set"
mongosh --host shard2_1 --port 27017 <<EOF
  rs.initiate(
      {
        _id : "shard2",
        members: [
          { _id : 0, host : "shard2_1:27017" },
          { _id : 1, host : "shard2_2:27017" },
          { _id : 2, host : "shard2_3:27017" }
        ]
      }
  );
  exit();
EOF

until mongosh --host mongos_router --port 27017 --eval "print(\"waited for connection\")"
do
    sleep 2
done
echo "Connection finished"
echo "Creating replica set"
mongosh --host mongos_router --port 27017 <<EOF
  sh.addShard( "shard1/shard1_1:27017");
  sh.addShard( "shard2/shard2_1:27017");

  sh.enableSharding("somedb");
  sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

  use somedb

  for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

  db.helloDoc.countDocuments() 
  exit(); 
EOF


echo "cluster created"