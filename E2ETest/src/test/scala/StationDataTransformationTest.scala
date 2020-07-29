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
      df.schema.fields(1).name should be("docks_available")
      df.schema.fields(1).dataType.typeName should be("integer")
      df.schema.fields(2).name should be("is_renting")
      df.schema.fields(2).dataType.typeName should be("boolean")
      df.schema.fields(3).name should be("is_returning")
      df.schema.fields(3).dataType.typeName should be("boolean")
      df.schema.fields(4).name should be("last_updated")
      df.schema.fields(4).dataType.typeName should be("integer")
      df.schema.fields(5).name should be("station_id")
      df.schema.fields(5).dataType.typeName should be("string")
      df.schema.fields(6).name should be("name")
      df.schema.fields(6).dataType.typeName should be("string")
      df.schema.fields(7).name should be("latitude")
      df.schema.fields(7).dataType.typeName should be("double")
      df.schema.fields(8).name should be("longitude")
      df.schema.fields(8).dataType.typeName should be("double")

      val row1 = df.head()
      row1.get(0) should be(2)
    }
  }
}
