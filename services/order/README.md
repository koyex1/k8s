# apis libraries and frameworks for python
django, flask, fastapi, tornado, falcon, bottle.


# for rabbitmq 
-- 1. created exchange in the ui and gave it a name order.exchange, type direct, durabilitly of transient, auto delete No, internal No, advanced arguments [alternate exchange - chatgpt seems to think it can also do the advanced argumetns in queues]

--- 2. created queue in the ui and gave it a virtual host/namespace, type of classic[quorum, streams], name of email.order.created.queue, durability of transient, advanced options include(auto expire, message ttl, overflow behavior, single active consumer, dl ex, dl routing key, max length, max length bytes, leader locator)
---  3 now created. you enter the exchange created and configure the binding
--- binding, you will set from exchange = orders, routing key = orders.created and then click bind to bind them to the queue.


-- so i created a deadletter xchange (dlx) and a deadleatter queue(dlq) for my failed notificaiton consumption. so to set this up. you do first of all have to realize that notification owns the dl xchange and queues to naming convention takes notification as a prefix.
-- to setup exchange do what is in 1 above but give name notification.dlx, 
-- to setup queue do what is in 2 aboe but give name notification.orders.created.dlq
-- to setup binding do what is in 3 above. bind exchange created to queue created.
-- then now 2 above can  now specify the dl exchange and dl routing key in the advanced options above.

# for kafka
-- 1. created the topic and named it order.created. and i set the partiton to be 3. meaning 3 partitions replicated across my brokers(kafka1 and kafka2). cleanup policy set to delete which removes old logs after its retention period expires. setting it to compact keeps latest value per key. then i set the min in sync replicas(ISR) to 2 because it can not be less than my replica. meaning my publisher will get a ack and not bother publishing again since data has sync across all 2 brokers. i set replication factor to 2 because i have 2 brokers and i want data replication on the 2 brokers. i set time to reetian to 1day. and i leave max size on disk to no set(meanign i want kafka to manage that themselves)then i set max message size to 1mb. then there is the custom parameters. which are advanced arguments. these are (cleanup.policy, retention.ms, retention.bytes, segment.bytes, segment.ms, segment.jitter.ms, segment.index.bytes, flush.messages, flush.ms, compression.type, delete.retention.ms, file.delete.delay.ms, max.message.bytes, message.timestamp.type, message.timestamp.difference.max.ms, min.cleanable.dirty.ratio, min.compaction.lag.ms, max.compaction.lag.ms, min.insync.replicas, preallocate, index.interval.bytes, unclean.leader.election.enable, leader.replication.throttled.replicas, follower.replication.throttled.replicas, message.downconversion.enable, local.retention.ms, local.retention.bytes, remote.storage.enable)