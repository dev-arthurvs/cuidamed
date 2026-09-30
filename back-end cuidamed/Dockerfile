# Imagem do back-end para o Railway (ou qualquer servidor com Docker).
# 1ª etapa: compila com o JDK; 2ª: roda só com o JRE (imagem menor).

FROM eclipse-temurin:25-jdk AS construcao
WORKDIR /app
# Dependências primeiro: sem mudança no pom.xml, o Docker reaproveita essa etapa.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw && ./mvnw -q -B dependency:go-offline
COPY src/ src/
RUN ./mvnw -q -B -DskipTests package && cp target/*.jar app.jar

FROM eclipse-temurin:25-jre
WORKDIR /app
# Sem root: se algo der errado no app, o estrago no container é menor.
RUN useradd --system --no-create-home cuidamed
USER cuidamed
COPY --from=construcao /app/app.jar app.jar
# Memória: o Java usa até 75% do que o Railway der ao container (em vez de
# adivinhar pelo tamanho da máquina) e um coletor leve, próprio para pouca RAM.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
