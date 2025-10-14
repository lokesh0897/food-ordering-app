# ----------------------------------------------------------------------
# STAGE 1: BUILD THE APPLICATION ARTIFACT (Builder Stage)
# This stage compiles the code and creates the executable JAR.
# ----------------------------------------------------------------------
FROM maven:3.9.5

# Set the working directory
WORKDIR /app

# Copy the pom.xml and download dependencies first to leverage Docker layer caching.
# This ensures a full download only happens if pom.xml changes.
COPY pom.xml .
RUN mvn dependency:go-offline

# Build the application. The Spring Boot plugin packages the app into a JAR.
# The variable 'order-delivery-app-0.0.1-SNAPSHOT.jar' matches the artifactId and version from your pom.xml.
RUN mvn package 

# ----------------------------------------------------------------------
# STAGE 2: CREATE THE FINAL PRODUCTION IMAGE (Runtime Stage)
# This stage is minimal, containing only the JRE and the compiled JAR.
# ----------------------------------------------------------------------
# Use a lightweight JRE base image (Alpine is often smaller and more secure)
FROM openjdk:17-jre-slim-buster

# Arguments derived from the Maven build
ARG JAR_FILE=target/order-delivery-app-0.0.1-SNAPSHOT.jar
ARG APP_NAME=order-delivery-app

# Create a non-root user for security best practices
RUN groupadd spring && useradd -r -g spring spring
USER spring

# Copy the built JAR from the 'builder' stage into the final image
# This is where the file size reduction happens.
COPY --from=builder /app/${JAR_FILE} /home/spring/${APP_NAME}.jar

# The default port for Spring Boot is 8080.
EXPOSE 8080

# Define the command to run the application when the container starts
ENTRYPOINT ["java", "-jar", "/home/spring/order-delivery-app.jar"]
