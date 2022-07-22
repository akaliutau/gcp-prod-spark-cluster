## About
This module contains code written to demonstrate rudimentary functionality of Spark framework.

Usually it does not require extra functionality to run, such as external databases, etc

As a result the jar file for worker is light, self-contained and can be used to perform fast test of ideas, infrastructure, etc

## Building and Running the code

1. Clone this project

2. Package application using maven command

```
mvn clean package
```

3. Run Spark/Scala application using spark-submit command as shown below:

```
spark-submit --class net.ddp.mapreduce.PiComputeApp ./spark-core/target/spark-core-1.0-SNAPSHOT.jar
```
(choose appropriate class name as entry point)

Some apps needed the 3rd party libs for correct work, they can be added on classpath in the following manner:

```
spark-submit --jars <relative path to lib> --class net.ddp.mapreduce.PiComputeApp ./spark-core/target/spark-core-1.0-SNAPSHOT.jar
```

Note, that all libraries are being copied to temporary spark directory along with jar-archive containing classes with worker code



