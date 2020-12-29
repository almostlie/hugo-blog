---
title: "clickhouse简介与数据库对比"
date: 2020-12-29T15:59:00+08:00

tags: ["database","bigdata","ClickHouse","Elasticsearch","Hbase","MongoDB","Kudu","TiDB"]
categories: ["database","bigdata"]
---

`ClickHouse`是一个用于联机分析(OLAP)的列式数据库管理系统(DBMS).

![clickhouse在大数据平台中的位置](/img/database/clickhouse/1.png)

我们先来了解一下`OLTP`和`OLAP`的区别.

## OLTP 和 OLAP 
- `OLTP` online transaction processing
- `OLAP` online analytic processing

### OLTP
数据库最早用于商业数据处理,那时写入操作常常对应一个商业交易（commercial transaction)
交易处理要求低延迟的读写,且每次只处理全部记录中的一小部分,通常根据某些键来过滤需要的数据,例如根据用户`id`之类的.
交易系统需要根据用户输入插入、更新记录,因为有 insert/update/read,所以整个系统是交互式的,因此这种访问模式被称为online transaction processing,即 `OLTP`.
虽然后来数据库使用场景越来越广泛,不再局限于金融应用,但`OLTP`的访问模式却与以前非常类似.

### OLAP
随着应用越来越复杂,公司内部会有数据分析的需求,数据分析的访问模式与`OLTP`差别很大,每次需要加载大量记录进内存(且常常仅需要每条记录的少量字段),然后对它们进行统计分析,统计结果将用于公司管理或商业决策（business intelligence).
为了与`OLTP`区别开,该访问模式被称为 online analytic processing,即`OLAP`.
最开始大家直接在`OLTP`数据库上做分析,这样做有几个缺点:
`OLAP`访问模式与`OLTP`差别很大,直接在`OLTP`系统上作分析并不方便,比如数据加载速度很慢；
`OLTP`系统一般是公司的盈利应用,需要保持低延迟、高可靠性,分析操作可能导致数据库访问速度快速下降,影响用户体验；
公司发展壮大后,会有很多`OLTP`系统,分析操作最好能在全部数据上进行,直接在`OLTP`系统上分析,局限性很大；
后来一般用独立的适合`OLAP`的数据库进行分析操作,并通过`ETL`将数据从`OLTP`系统中加载到数据仓库(`datawarehouse`)中.

---
---

## Clickhouse使用场景
- 数据需要以相当大的批次插入.Clickhouse建议最小(>1000)更新,(> 10000)行时并发插入性能最好.
- 查询可以使用从数据库中提取的大量行,但只用一小部分字段.
- 处理宽表,即每个表包含着大量的列
- 查询相对较少(通常每台服务器每秒查询数百次或更少),并发不高
- 对于简单的查询,允许大约50毫秒的延时.
- 列值相当小,通常由数字和短字符串组成(例如每个URL 60个字节)
- 处理单个查询时需要高吞吐量(每台服务器每秒可达数十亿行)
- *不支持事务*
- *默认情况下,在执行聚合时,查询中间状态使用内存必须大于单个服务器上的RAM。否则,ClickHouse将会内存溢出*
- *绝大部分是查询需求而非删除或者更新,缺乏完整的UPDATE/DELETE实现*

---
---
## 与Elasticsearch/Hbase/Kudu/TiDB比较
脱离场景谈技术架构,都是耍流氓

### Elasticsearch
es的底层存储使用lucene,主要包含行存储(storefiled),列存储(docvalues)和倒排索引(invertindex)

因为 Elasticsearch 和 ClickHouse使用场景重叠,会进行详细对比

- `ClickHouse` 写入吞吐量大,单服务器日志写入量在 50MB 到 200MB/s,每秒写入超过 60w 记录数,是`Elasticsearch`的5倍以上.
- 官方宣称数据在`pagecache`中,单服务器查询速率大约在2-30GB/s;没在`pagecache`的情况下,查询速度取决于磁盘的读取速率和数据的压缩率.经测试`ClickHouse`的查询速度比`Elasticsearch`快 5-30 倍以上.
- `Elasticsearch` 中一个大查询可能导致`OOM`的问题;`ClickHouse`通过预设的查询限制,会查询失败,不影响整体的稳定性.
- 数据压缩比比`Elasticsearch`高,相同数据占用的磁盘空间只有`Elasticsearch`的 1/3 到 1/30,节省了磁盘空间的同时,也能有效的减少磁盘IO.
- `ClickHouse` 比 `Elasticsearch`占用更少的内存,消耗更少的CPU资源.
- `Elasticsearch` 中不同的`Group`负载不均衡,有的`Group`负载高,会导致写`Rejected`等问题,需要人工迁移索引;在`ClickHouse`中通过集群和`Shard`策略,采用轮询写的方法,可以让数据比较均衡的分布到所有节点.
- `Elasticsearch`在计算去重总量(eg:计算`UV`),数据需要做精确去重的场景下,它的耗时比较大.
- `ClickHouse`采用`SQL`语法,比`Elasticsearch`官方的`DSL`学习更简单,学习成本也低于社区提供的`Elasticsearch SQL`.
- `ClickHouse`可以做多表`JOIN`,`Elasticsearch`不可以.
- 
- `ClickHouse`虽然查询速度快,但无法承受高并发;相反,`Elasticsearch`cpu消耗到60%对查询性能不会有太大的影响,适合在线服务.
- `Elasticsearch`支持全文索引,更适合关键字搜索, 
- `ELK Stack`入门门槛够低,太方便了…

---
### HBASE 
`HBase`是运行在`HDFS`之上的列簇数据库(column-family database),但是不属于列式数据库(column-oriented database).

假设我们有一张`HBase`表
![HBase](/img/database/clickhouse/2.png)

那么,`HBase`底层的KV存储大概如下所示的:
![HBase底层存储](/img/database/clickhouse/3.png)

从上图可以看出
- 不同的列簇存在不同的文件中
- 整个数据是按照`Rowkey`进行字典排序的
- 每一列数据在底层`HFile`中是以 KV 形式存储的
- `HBase`以列式存储的格式在磁盘上存储数据,但是在相同的一行数据中,如果列族一样,这些数据是顺序放在一起的,也不等同于传统列式数据库

- 访问HBase数据只能基于`Rowkey`，`Rowkey`设计的好坏直接决定了HBase使用优劣.
- 本身不支持二级索引,若要实现,则需要引入第三方.
- 
- 因为`HBase`列的可以动态增加,并且列为空就不存储数据,节省存储空间.

---
### Kudu
`Kudu`是由Cloudera带头开发出存储系统,整体应用模式与`HBase`很相似,也就是能够支持行级别的随机读写,对于批量顺序检索功能也能支持.

- `Kudu`的适用场景非常苛刻，必须走主键，否则，scan非主键列带来的是高CPU,`ClickHouse`影响会小很多.
- `Kudu`是牺牲了写性能而提高读性能，主要体现在主键，所以在批量更新的时候会有大量的读.
- 
- 优化后能够接近于`ClickHouse`的查询速度.
- 可以支持`update`和`upsert`操作.
- 可与`spark`系统集成

---
### TiDB
`TiDB` 是一个分布式 NewSQL 数据库。它支持水平弹性扩展、ACID 事务、标准 SQL、MySQL 语法和 MySQL 协议,具有数据强一致的高可用特性,是一个不仅适合`OLTP`场景还适`OLAP`场景的混合数据库。

- TiDB发挥官方推荐居然要高IOPS(NVME SSD 盘最合适)做存储节点,成本太高...
- TiDB设计应用需要跑在物理机里
- mysql部分函数不兼容
- 
- 优秀的横向扩展能力
- 高可用
- 强一致性
- 支持ACID事务,支持二级索引,没有Java GC的痛点（TiKV是由Rust开发,Rust可以完全手动控制内存,无GC）
- 实时和离线数据导入
- 解决分库分表痛点