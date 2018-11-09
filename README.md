# kafka_connect_rds_to_s3_json
Retrieve the data from Posgresql on RDS (non CDC) and ingest to AWS S3 as Json String.
# How to execute Kafka Connect with these config files is shown below (in standalone mode)

connect-standalone ./worker.properties ./postgresql-connector.properties ./confluent-s3.properties  &
