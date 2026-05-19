FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# 🔥 COPY ONLY POM FIRST (for caching)
COPY pom.xml .

# 🔥 Download dependencies (cached layer)
RUN mvn dependency:go-offline

# 🔥 Now copy source
COPY src ./src

# 🔥 Build
RUN mvn clean package -DskipTests


# ---- RUNTIME IMAGE ----
FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]