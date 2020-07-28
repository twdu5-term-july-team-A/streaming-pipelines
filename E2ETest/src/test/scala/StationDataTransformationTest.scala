import org.scalatest._
import org.apache.spark.sql.SparkSession

class StationDataTransformationTest extends FeatureSpec with Matchers with GivenWhenThen {

  feature("Apply station status transformations to data frame") {
    val spark = SparkSession.builder.appName("Test App").master("local").getOrCreate()

    scenario("Transform nyc station data frame") {

      Given("Read stationMart data from hadoop")
      val df = spark.read
        .format("csv")
        .option("inferSchema", "true")
        .option("header", "true")
        .load("hdfs://hadoop:9000/tw/stationMart/data/")

      Then("Useful columns are extracted")
      df.schema.fields(0).name should be("bikes_available")
      df.schema.fields(0).dataType.typeName should be("integer")

      val row1 = df.head()
      row1.get(0) should be(2)
    }
  }
}
