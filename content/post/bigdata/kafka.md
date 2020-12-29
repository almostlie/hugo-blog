---
title: "kafka"
date: 2020-11-12T17:27:00+08:00

tags: ["kafka","bigdata"]
categories: ["bigdata"]
---

## kafka简介

### 基本概念
- Producer:消息和数据的生产者,向kafka的一个topic发布消息的进程/代码/服务.
- Consumer:消息和数据的消费者,订阅数据(Topic)并且处理其发布的消息的进程/代码/服务.
- Consumer Group(逻辑概念):逻辑概念,对于同一个topic,会广播给不同的group,一个group中.只有一个consumer可以消费该消息.消费者的数目必须少于或等于Partition的数目,一个消费者只能同时消费一个Partition
- Broker(物理概念):kafka集群中的每个kafka节点.
- Broker Group(逻辑概念):Broker Group中每一个Broker保存Topic的一个或多个Partition.
- Topic(逻辑概念):kafka消息的类别,对数据进行区分/隔离.
- Partition(物理概念):kafka下数据存储的基本单元.一个Topic数据,会被分散存储到多个Partition,每一个Partition是有序的.
- Replication(物理概念) :同一个Partition可能会有多个Replication,多个Replication之间数据是一样的.
- Replication Leader(物理概念):一个Partition的多个Replication上,需要一个Leader负责该Partition上与Producer与Consumer交互.
- ReplicaManager(逻辑概念):负责管理当前broker所有分区和副本的信息,处理KafkaController发起的一些请求,副本状态的切换,添加/读取消息等.


### Replication特点
- Replication的基本单位是Topic的Partition
- 所有的读和写都是从Leader进,Follower只是做为备份
- Follower必须能够及时复制Leader的数据
- 具有容错性和可扩展性


## kafka结构

### 基本结构
![kafka基本结构](/img/bigdata/kafka/1.png)

kafka强依赖与zookeeper,下面数据都会存储在zookeeper里 
1. broker信息
2. topic和partition的分布

### 消息结构
![kafka消息结构](/img/bigdata/kafka/2.png)

1. Offset 偏移量
2. Length 长度
3. CRC32 校验字段 
4. Magic kafka判定是不是kafka消息
5. attributes 消息属性
6. Timestamp 消息时间戳
7. key Length
8. key
9. Value Length
10. Value

## kafka特点
### 分布式
- 多分区
- 多副本
- 多订阅者 
- 基于zookeeper调度

### 高性能
- 高吞吐量
- 低延迟
- 高并发
- 时间复杂度O(1)

### 持久性和扩展性
- 数据可持久化
- 容错性
- 支持在线水平扩展
- 消息自动平衡(1,服务端分片平衡 2.客户端访问平衡)

## kafka应用场景
- 消息队列
- 行为跟踪
- 元信息监控
- 日志收集 
- 流处理
- 事件源
- 持久性日志(commit log)

## kafka消息事物
### 数据传输的事物定义
- 最多一次: 消息不会被重复发送,最多被传输一次,但也有有可能一次不传书
- 最少一次:消息不会被漏发送,最少别传输一次,但也有可能被重复传输
- 精确一次

### 事物保证
- 内部重试问题:Procedure幂等处理
- 多分区原子写入(深入)
- 避免僵尸实例
1. 每次事物Producer分配一个transactional.id,在进程重新启动时能够识别相同的Producer实例.
2. kafka增加了一个与transactional.id的epoch,存储每个transactional.id的内部元数据.
3. 一旦epoch被触发,任何具有相同的transactional.id和更旧的epoch的producer被视为僵尸,kafka会拒绝来自这些procedure的后续事物性写入.

### kafka零拷贝
- 网络传输持久性日志块
- 使用 java nio channel.transforTo()方法 ,底层使用linux sendfile 方法

### 文件传输到网络的公共数据路径
- 操作系统将数据从磁盘读入到内核空间的页缓存.
- 应用程序将数据从内核空间读入到用户空间缓存中.
- 应用程序将数据写回到内核空间到socket缓存里.
- 操作系统将数据从socket缓存区复制到网卡缓冲区,以便将数据经网络发出.

### 零拷贝
- 操作系统将数据从磁盘读入到内核空间的页缓存.
- 将数据的位置和长度的信息的描述符增加至内核空间(socket缓冲区)
- 操作系统将数据从内核拷贝到网卡缓冲区,以便将数据经网络发出