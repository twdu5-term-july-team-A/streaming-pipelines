import java.net.URI

import org.scalatest._
import org.apache.curator.framework.CuratorFrameworkFactory
import org.apache.curator.retry.ExponentialBackoffRetry
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.sql.SparkSession

class E2ETest extends FeatureSpec with Matchers with GivenWhenThen {

      feature("Apply station status transformations to data frame") {
            val spark = SparkSession.builder.appName("Test App").master("local").getOrCreate()

            val zookeeperConnectionString = "localhost:2181"

            val retryPolicy = new ExponentialBackoffRetry(1000, 3)

            val zkClient = CuratorFrameworkFactory.newClient(zookeeperConnectionString, retryPolicy)

            zkClient.start()

            val outputLocation = new String(
              zkClient.getData.forPath("/tw/output/dataLocation"))

            scenario("Transform nyc station data frame") {


//              val hdfs = FileSystem.get(new URI("hdfs://127.0.0.1:8020/"), new Configuration())
//              val path = new Path("/tw/stationMart/data/part-00000-779aae2a-4df4-48af-a1b1-c6bd1b66f40c-c000.csv")
//              val stream = hdfs.open(path)
//              def readLines = Stream.cons(stream.readLine, Stream.continually( stream.readLine))
//              println(readLines)
              var df = spark.read
                      .format("csv")
                      .option("header", "true")
                      .load("hdfs://hadoop:9003/tw/stationMart/data/")
//              var df = spark.read.csv("hdfs://localhost:9003/tw/stationMart/data")
              print(df.head(10))



//                  val testStationData =
//                        """{
//          "station_id":"83",
//          "bikes_available":19,
//          "docks_available":41,
//          "is_renting":true,
//          "is_returning":true,
//          "last_updated":1536242527,
//          "name":"Atlantic Ave & Fort Greene Pl",
//          "latitude":40.68382604,
//          "longitude":-73.97632328
//          }"""
//
//                  val schema = ScalaReflection.schemaFor[StationData].dataType //.asInstanceOf[StructType]
//
//                  Given("Sample data for station_status")
//                  val testDF1 = Seq(testStationData).toDF("raw_payload")
//
//
//                  When("Transformations are applied")
//                  val resultDF1 = testDF1.transform(nycStationStatusJson2DF(_, spark))
//
//                  Then("Useful columns are extracted")
//                  resultDF1.schema.fields(0).name should be("bikes_available")
//                  resultDF1.schema.fields(0).dataType.typeName should be("integer")
//                  resultDF1.schema.fields(1).name should be("docks_available")
//                  resultDF1.schema.fields(1).dataType.typeName should be("integer")
//                  resultDF1.schema.fields(2).name should be("is_renting")
//                  resultDF1.schema.fields(2).dataType.typeName should be("boolean")
//                  resultDF1.schema.fields(3).name should be("is_returning")
//                  resultDF1.schema.fields(3).dataType.typeName should be("boolean")
//                  resultDF1.schema.fields(4).name should be("last_updated")
//                  resultDF1.schema.fields(4).dataType.typeName should be("long")
//                  resultDF1.schema.fields(5).name should be("station_id")
//                  resultDF1.schema.fields(5).dataType.typeName should be("string")
//                  resultDF1.schema.fields(6).name should be("name")
//                  resultDF1.schema.fields(6).dataType.typeName should be("string")
//                  resultDF1.schema.fields(7).name should be("latitude")
//                  resultDF1.schema.fields(7).dataType.typeName should be("double")
//                  resultDF1.schema.fields(8).name should be("longitude")
//                  resultDF1.schema.fields(8).dataType.typeName should be("double")
//
//                  val row1 = resultDF1.head()
//                  row1.get(0) should be(19)
//                  row1.get(1) should be(41)
//                  row1.get(2) shouldBe true
//                  row1.get(3) shouldBe true
//                  row1.get(4) should be(1536242527)
//                  row1.get(5) should be("83")
//                  row1.get(6) should be("Atlantic Ave & Fort Greene Pl")
//                  row1.get(7) should be(40.68382604)
//                  row1.get(8) should be(-73.97632328)
            }
      }
}
