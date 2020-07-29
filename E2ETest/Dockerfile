FROM ryandjf/docker-spark

RUN mkdir /E2ETest
COPY .  /E2ETest

CMD cd /E2ETest && sbt test


