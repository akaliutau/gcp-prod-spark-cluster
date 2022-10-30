package net.ddp.mapreduce;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import org.apache.spark.api.java.function.MapFunction;
import org.apache.spark.api.java.function.ReduceFunction;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Encoders;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;

import lombok.extern.slf4j.Slf4j;

/**
 * Computes Pi.
 * @author akaliutau
 */
@Slf4j
public class PiComputeApp implements Serializable {
    private static final long serialVersionUID = -1546L;
    private static long counter = 0;

    /**
     * Mapper class, creates the map of dots
     * @author akaliutau
     */
    private static final class SampleMapper implements MapFunction<Row, Integer> {
        private static final long serialVersionUID = 38446L;

        @Override
        public Integer call(Row r) throws Exception {
            double x = Math.random() * 2 - 1;
            double y = Math.random() * 2 - 1;
            counter++;
            if (counter % 100000 == 0) {
                log.info("{} samples generated so far", counter);
            }
            return (x * x + y * y <= 1) ? 1 : 0;
        }
    }

    /**
     * Reducer class, reduces the map of dots
     * @author akaliutau
     */
    private static final class SampleReducer implements ReduceFunction<Integer> {
        private static final long serialVersionUID = 12859L;

        @Override
        public Integer call(Integer x, Integer y) {
            return x + y;
        }
    }

    /**
     * main() is your entry point to the application.
     * @param args
     */
    public static void main(String[] args) {
        PiComputeApp app = new PiComputeApp();
        app.start(10);
    }

    /**
     * The processing code.
     */
    private void start(int slices) {
        int numberOfSamples = 100000 * slices;
        log.info("About to create {} samples", +numberOfSamples);

        long t0 = System.currentTimeMillis();
        SparkSession spark = SparkSession.builder().appName("Spark Pi").master("local[*]").getOrCreate();

        long t1 = System.currentTimeMillis();
        log.info("Session initialized in {} ms", (t1 - t0));

        List<Integer> l = new ArrayList<>(numberOfSamples);
        for (int i = 0; i < numberOfSamples; i++) {
            l.add(i);
        }
        Dataset<Row> incrementalDf = spark.createDataset(l, Encoders.INT()).toDF();

        long t2 = System.currentTimeMillis();
        log.info("Initial dataframe built in {} ms", (t2 - t1));

        Dataset<Integer> dartsDs = incrementalDf.map(new SampleMapper(), Encoders.INT());

        long t3 = System.currentTimeMillis();
        log.info("Sampling done in {} ms", (t3 - t2));

        int hitsInCircle = dartsDs.reduce(new SampleReducer());
        long t4 = System.currentTimeMillis();
        log.info("Analyzing result in {} ms", (t4 - t3));

        log.info("Pi is roughly {}", 4.0 * hitsInCircle / numberOfSamples);

        spark.stop();
    }
}
